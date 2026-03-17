import Foundation
import SwiftData
import WidgetKit

protocol TransactionServiceProtocol {
    func addExpense(amount: Double, category: ItemCategory?, isIOU: Bool, memo: String?) throws
    func addIncome(amount: Double) throws
    func processMonthlyReview(currentDate: Date) throws
    func recoverDebt(sourceCategoryName: String, targetCategoryName: String, amount: Double) throws
    func updateExpense(id: UUID, amount: Double, category: ItemCategory?, isIOU: Bool, memo: String?) throws
    func updateIncome(id: UUID, amount: Double) throws
    func deleteTransaction(id: UUID) throws
}

// メモ引数を省略できるようにするデフォルト実装
extension TransactionServiceProtocol {
    func addExpense(amount: Double, category: ItemCategory?, isIOU: Bool) throws {
        try addExpense(amount: amount, category: category, isIOU: isIOU, memo: nil)
    }
    func updateExpense(id: UUID, amount: Double, category: ItemCategory?, isIOU: Bool) throws {
        try updateExpense(id: id, amount: amount, category: category, isIOU: isIOU, memo: nil)
    }
}

@MainActor
class TransactionService: TransactionServiceProtocol {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // 現在の年月に対応する予算レコードを取得するヘルパー
    private func getCurrentMonthBudget() -> Budget? {
        let descriptor = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.month, order: .reverse)])
        let budgets = (try? context.fetch(descriptor)) ?? []
        let calendar = Calendar.current
        let currentYearMonth = calendar.dateComponents([.year, .month], from: Date())
        
        return budgets.first(where: {
            let bComponents = calendar.dateComponents([.year, .month], from: $0.month)
            return bComponents.year == currentYearMonth.year && bComponents.month == currentYearMonth.month
        }) ?? budgets.first
    }
    
    // 支出または立替を追加する
    func addExpense(amount: Double, category: ItemCategory?, isIOU: Bool, memo: String? = nil) throws {
        guard amount > 0 else { return }

        // 1. Transaction履歴の作成
        let trimmedMemo = memo.flatMap { $0.isEmpty ? nil : String($0.prefix(20)) }
        let transaction = ExpenseTransaction(date: Date(), amount: amount, categoryId: category?.id, isIOU: isIOU, isIncome: false, memo: trimmedMemo)
        context.insert(transaction)
        
        // 2. 状態の更新
        if isIOU {
            // 立替の場合はIOURecordを追加（予算残高は減らさない）
            let title = category?.name ?? "立替"
            let iou = IOURecord(date: Date(), amount: amount, title: title, isResolved: false)
            context.insert(iou)
        } else {
            // 通常支出の場合はカテゴリ残高と全体予算残高の両方を減らす（ spentAmount を増やす ）
            if let category = category {
                category.spentAmount += amount
            }
            
            // カテゴリの有無に関わらず、全体予算（Budget）の使用済み金額にも加算する
            if let budget = getCurrentMonthBudget() {
                budget.spentAmount += amount
            }
        }
        
        try context.save()
        reloadWidgets()
    }
    
    // 臨時収入を追加する
    func addIncome(amount: Double) throws {
        guard amount > 0 else { return }
        
        let transaction = ExpenseTransaction(date: Date(), amount: amount, categoryId: nil, isIOU: false, isIncome: true)
        context.insert(transaction)
        if let budget = getCurrentMonthBudget() {
            budget.totalAmount += amount
        }
        
        try context.save()
        reloadWidgets()
    }
    
    // 月跨ぎの処理（借金の繰り越し等）
    func processMonthlyReview(currentDate: Date) throws {
        guard let currentBudget = getCurrentMonthBudget() else { return }
        
        // オーバーした分（借金）を計算
        let overAmount = currentBudget.spentAmount - currentBudget.totalAmount
        
        // 次月の予算を作成
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? Date()
        let newTotal = 250000.0 // ※仮のベース予算
        
        // オーバー分が存在すれば初めからspentAmountに加算する（借金として持つ）
        let initialSpent = overAmount > 0 ? overAmount : 0.0
        
        // 手取り額と先取り貯金を前月から引き継ぐ（次月開設時に再設定不要にする）
        let nextBudget = Budget(
            month: nextMonth,
            totalAmount: newTotal,
            spentAmount: initialSpent,
            incomeAmount: currentBudget.incomeAmount,
            savingsAmount: currentBudget.savingsAmount
        )
        context.insert(nextBudget)
        
        try context.save()
        reloadWidgets()
    }
    
    // 借金（超過予算）を他のカテゴリから回収・補填する
    func recoverDebt(sourceCategoryName: String, targetCategoryName: String, amount: Double) throws {
        let sourceDesc = FetchDescriptor<ItemCategory>(predicate: #Predicate { $0.name == sourceCategoryName })
        let targetDesc = FetchDescriptor<ItemCategory>(predicate: #Predicate { $0.name == targetCategoryName })
        
        guard let sourceCat = try? context.fetch(sourceDesc).first,
              let targetCat = try? context.fetch(targetDesc).first else { return }
        
        // 減額元（source）の予算総枠を減らす
        sourceCat.totalAmount -= amount
        
        // 対象元（target）の超過分（＝使用済み金額）を減らして相殺する
        targetCat.spentAmount -= amount
        
        try context.save()
        reloadWidgets()
    }
    
    // 既存の支出/立替を更新する
    func updateExpense(id: UUID, amount: Double, category: ItemCategory?, isIOU: Bool, memo: String? = nil) throws {
        let descriptor = FetchDescriptor<ExpenseTransaction>(predicate: #Predicate { $0.id == id })
        guard let transaction = try? context.fetch(descriptor).first else { return }
        
        // 1. 以前の金額を取り消す (旧isIOUを考慮)
        let oldAmount = transaction.amount
        let oldIsIOU = transaction.isIOU
        
        if !oldIsIOU {
            // 旧が通常支出の場合のみ、Budget・Categoryから差し戻す
            if let budget = getCurrentMonthBudget() {
                budget.spentAmount = max(0, budget.spentAmount - oldAmount)
            }
            
            if let oldCatId = transaction.categoryId {
                let catDesc = FetchDescriptor<ItemCategory>(predicate: #Predicate { $0.id == oldCatId })
                if let oldCat = try? context.fetch(catDesc).first {
                    oldCat.spentAmount = max(0, oldCat.spentAmount - oldAmount)
                }
            }
        }
        
        // 2. 新しい値を適用する
        transaction.amount = amount
        transaction.categoryId = category?.id
        transaction.isIOU = isIOU
        transaction.isIncome = false
        transaction.memo = memo.flatMap { $0.isEmpty ? nil : String($0.prefix(20)) }
        
        if !isIOU {
            // 新が通常支出の場合のみ、Budget・Categoryに加算
            if let budget = getCurrentMonthBudget() {
                budget.spentAmount += amount
            }
            
            if let newCat = category {
                newCat.spentAmount += amount
            }
        }
        
        try context.save()
        reloadWidgets()
    }
    
    // 既存の臨時収入を更新する
    func updateIncome(id: UUID, amount: Double) throws {
        let descriptor = FetchDescriptor<ExpenseTransaction>(predicate: #Predicate { $0.id == id })
        guard let transaction = try? context.fetch(descriptor).first else { return }
        
        let diff = amount - transaction.amount
        transaction.amount = amount
        transaction.isIncome = true
        
        if let budget = getCurrentMonthBudget() {
            budget.totalAmount += diff
        }
        
        try context.save()
        reloadWidgets()
    }
    
    // トランザクションを削除し、予算を復元する
    func deleteTransaction(id: UUID) throws {
        let descriptor = FetchDescriptor<ExpenseTransaction>(predicate: #Predicate { $0.id == id })
        guard let transaction = try? context.fetch(descriptor).first else { return }
        
        let amount = transaction.amount
        
        if transaction.isIncome {
            if let budget = getCurrentMonthBudget() {
                budget.totalAmount = max(0, budget.totalAmount - amount)
            }
        } else if !transaction.isIOU {
            // 通常支出の場合のみ予算を復元する（立替は予算に影響していないため復元不要）
            if let budget = getCurrentMonthBudget() {
                budget.spentAmount = max(0, budget.spentAmount - amount)
            }
            if let catId = transaction.categoryId {
                let catDesc = FetchDescriptor<ItemCategory>(predicate: #Predicate { $0.id == catId })
                if let category = try? context.fetch(catDesc).first {
                    category.spentAmount = max(0, category.spentAmount - amount)
                }
            }
        }
        
        context.delete(transaction)
        try context.save()
        reloadWidgets()
    }
    
    private func reloadWidgets() {
        saveWidgetSnapshot()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// App Group UserDefaults にウィジェット用スナップショットを書き込む
    private func saveWidgetSnapshot() {
        let suiteName = "group.com.arima0903.NoLookBudget"
        let key = "widget_budget_snapshot_v1"
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }

        // 当月予算を取得
        let budgetDesc = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.month, order: .reverse)])
        let budgets = (try? context.fetch(budgetDesc)) ?? []
        let calendar = Calendar.current
        let currentYM = calendar.dateComponents([.year, .month], from: Date())
        let budget = budgets.first(where: {
            let c = calendar.dateComponents([.year, .month], from: $0.month)
            return c.year == currentYM.year && c.month == currentYM.month
        }) ?? budgets.first

        let displayTotal = budget?.incomeAmount ?? budget?.totalAmount ?? 0.0
        let fixedAndSavings = displayTotal - (budget?.totalAmount ?? 0.0)
        let budgetSpent = (budget?.spentAmount ?? 0.0) + fixedAndSavings

        // カテゴリを取得
        let catDesc = FetchDescriptor<ItemCategory>(sortBy: [SortDescriptor(\.orderIndex)])
        let cats = (try? context.fetch(catDesc)) ?? []

        // JSON エンコードして保存
        struct CatSnap: Encodable {
            let name: String; let remainingAmount: Int; let ratio: Double
        }
        struct Snap: Encodable {
            let budgetTotal: Double; let budgetSpent: Double; let categories: [CatSnap]
        }
        let snap = Snap(
            budgetTotal: displayTotal,
            budgetSpent: budgetSpent,
            categories: cats.prefix(6).map {
                CatSnap(
                    name: $0.name,
                    remainingAmount: Int($0.totalAmount - $0.spentAmount),
                    ratio: $0.totalAmount > 0 ? ($0.spentAmount / $0.totalAmount) : 0.0
                )
            }
        )
        if let encoded = try? JSONEncoder().encode(snap) {
            defaults.set(encoded, forKey: key)
        }
    }
}
