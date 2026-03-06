import Foundation
import SwiftData
import SwiftUI
import Combine
import WidgetKit

@MainActor
class ConfigurationViewModel: ObservableObject {
    @Published var incomeAmount: String = ""
    @Published var savingsAmount: String = ""
    @Published var fixedCosts: [FixedCostSetting] = []
    
    // 固定費モーダル用状態
    @Published var showFixedCostModal = false
    @Published var editingFixedCost: FixedCostSetting? = nil
    @Published var draftFixedCostName: String = ""
    @Published var draftFixedCostAmount: String = ""
    
    // 変動費カテゴリ（既存通り）
    @Published var categories: [ItemCategory] = []
    
    // カテゴリ追加・編集モーダル用状態
    @Published var showCategoryModal = false
    @Published var editingCategory: ItemCategory? = nil
    @Published var draftCategoryName: String = ""
    @Published var draftCategoryAmount: String = ""
    
    // バリデーション用
    var canAddCategory: Bool {
        categories.count < 6
    }
    
    var isCategoryNameValid: Bool {
        // スペース（全半角）、英数字（全半角）、ひらがな、カタカナ、漢字のみ許可（記号不可）
        let pattern = "^[a-zA-Z0-9ぁ-んァ-ヶ一-龠々ａ-ｚＡ-Ｚ０-９\\s　]+$"
        return draftCategoryName.range(of: pattern, options: .regularExpression) != nil
    }
    
    private let context: ModelContext
    
    init(context: ModelContext? = nil) {
        self.context = context ?? SharedModelContainer.shared.mainContext
        fetchData()
    }
    
    func fetchData() {
        // 現在の予算を取得
        let budgetDesc = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.month, order: .reverse)])
        if let currentBudget = (try? context.fetch(budgetDesc))?.first {
            if let income = currentBudget.incomeAmount {
                self.incomeAmount = "\(Int(income))"
            }
            if let savings = currentBudget.savingsAmount {
                self.savingsAmount = "\(Int(savings))"
            }
        }
        
        // 固定費を取得
        let fixedDesc = FetchDescriptor<FixedCostSetting>(sortBy: [SortDescriptor(\.orderIndex)])
        self.fixedCosts = (try? context.fetch(fixedDesc)) ?? []
        
        // カテゴリを取得して並び順通りにセット
        let catDesc = FetchDescriptor<ItemCategory>(sortBy: [SortDescriptor(\.orderIndex)])
        self.categories = (try? context.fetch(catDesc)) ?? []
    }
    
    // 予算と固定費の一括保存処理
    func saveBudget() {
        let budgetDesc = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.month, order: .reverse)])
        var currentBudget: Budget
        
        let calendar = Calendar.current
        let currentYearMonth = calendar.dateComponents([.year, .month], from: Date())
        
        let budgets = (try? context.fetch(budgetDesc)) ?? []
        if let existing = budgets.first(where: {
            let bComponents = calendar.dateComponents([.year, .month], from: $0.month)
            return bComponents.year == currentYearMonth.year && bComponents.month == currentYearMonth.month
        }) ?? budgets.first {
            currentBudget = existing
        } else {
            // 初期状態でデータが一つもない場合は作成する
            currentBudget = Budget(month: Date(), totalAmount: 0, spentAmount: 0)
            context.insert(currentBudget)
        }
        
        let income = Double(incomeAmount) ?? 0
        let savings = Double(savingsAmount) ?? 0
        let totalFixed = fixedCosts.reduce(0) { $0 + $1.amount }
        
        // 当月の臨時収入の合計を取得してベース予算に合算する
        var extraIncomeTotal: Double = 0
        let calendar = Calendar.current
        if let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentBudget.month)),
           let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: startOfMonth) {
            let predicate = #Predicate<ExpenseTransaction> { tx in
                tx.date >= startOfMonth && tx.date <= endOfMonth && tx.isIncome == true
            }
            let desc = FetchDescriptor<ExpenseTransaction>(predicate: predicate)
            if let incomes = try? context.fetch(desc) {
                extraIncomeTotal = incomes.reduce(0) { $0 + $1.amount }
            }
        }
        
        let calculatedBaseBudget = income - savings - totalFixed + extraIncomeTotal
        
        currentBudget.incomeAmount = income
        currentBudget.savingsAmount = savings
        // 自由に使える変動費のベース予算を上書き
        currentBudget.totalAmount = max(0, calculatedBaseBudget)
        
        // 固定費の履歴(Transaction)を当月分同期する
        syncFixedCostTransactions(for: currentBudget.month)
        
        try? context.save()
        reloadWidgets()
        fetchData()
    }
    
    // 固定費のトランザクション同期処理
    private func syncFixedCostTransactions(for month: Date) {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: startOfMonth) else { return }
        
        // 当月の既存の固定費履歴をすべて取得
        let predicate = #Predicate<ExpenseTransaction> { tx in
            tx.date >= startOfMonth && tx.date <= endOfMonth && tx.isFixedCost == true
        }
        let desc = FetchDescriptor<ExpenseTransaction>(predicate: predicate)
        let existingFixedTxs = (try? context.fetch(desc)) ?? []
        
        // 設定に基づく最新の固定費リスト
        for setting in fixedCosts {
            // 既に存在するかチェック
            if let existingTx = existingFixedTxs.first(where: { $0.fixedCostSettingId == setting.id }) {
                // 金額や名称が変更されていれば更新
                existingTx.amount = setting.amount
                existingTx.title = setting.name
                existingTx.date = startOfMonth // 月初日付にしておく
            } else {
                // 新規作成
                let newTx = ExpenseTransaction(
                    date: startOfMonth,
                    amount: setting.amount,
                    isFixedCost: true,
                    title: setting.name,
                    fixedCostSettingId: setting.id
                )
                context.insert(newTx)
            }
        }
        
        // 設定から削除された固定費の履歴を削除
        let validSettingIds = Set(fixedCosts.map { $0.id })
        for tx in existingFixedTxs {
            if let targetId = tx.fixedCostSettingId, !validSettingIds.contains(targetId) {
                context.delete(tx)
            }
        }
    }
    
    // --- 固定費のCRUD ---
    func prepareAddingFixedCost() {
        editingFixedCost = nil
        draftFixedCostName = ""
        draftFixedCostAmount = ""
        showFixedCostModal = true
    }
    
    func prepareEditingFixedCost(_ cost: FixedCostSetting) {
        editingFixedCost = cost
        draftFixedCostName = cost.name
        draftFixedCostAmount = "\(Int(cost.amount))"
        showFixedCostModal = true
    }
    
    func saveFixedCost() {
        guard !draftFixedCostName.isEmpty, let amount = Double(draftFixedCostAmount) else { return }
        
        if let cost = editingFixedCost {
            cost.name = draftFixedCostName
            cost.amount = amount
        } else {
            let nextIndex = fixedCosts.count
            let newCost = FixedCostSetting(name: draftFixedCostName, amount: amount, orderIndex: nextIndex)
            context.insert(newCost)
            fixedCosts.append(newCost)
        }
        
        try? context.save()
        reloadWidgets()
        fetchData()
        showFixedCostModal = false
    }
    
    func deleteFixedCosts(at offsets: IndexSet) {
        offsets.forEach { index in
            context.delete(fixedCosts[index])
        }
        fixedCosts.remove(atOffsets: offsets)
        for (index, cost) in fixedCosts.enumerated() {
            cost.orderIndex = index
        }
        try? context.save()
        reloadWidgets()
        fetchData()
    }
    
    func moveFixedCosts(from source: IndexSet, to destination: Int) {
        fixedCosts.move(fromOffsets: source, toOffset: destination)
        for (index, cost) in fixedCosts.enumerated() {
            cost.orderIndex = index
        }
        try? context.save()
        reloadWidgets()
    }
    
    // --- カテゴリの追加・更新の準備 ---
    func prepareAddingCategory() {
        editingCategory = nil
        draftCategoryName = ""
        draftCategoryAmount = ""
        showCategoryModal = true
    }
    
    func prepareEditingCategory(_ category: ItemCategory) {
        editingCategory = category
        draftCategoryName = category.name
        draftCategoryAmount = "\(Int(category.totalAmount))"
        showCategoryModal = true
    }
    
    // カテゴリの保存（追加または更新）
    func saveCategory() {
        guard !draftCategoryName.isEmpty,
              let amount = Double(draftCategoryAmount) else { return }
        
        if let category = editingCategory {
            category.name = draftCategoryName
            category.totalAmount = amount
        } else {
            let nextIndex = categories.count
            let newCat = ItemCategory(name: draftCategoryName, totalAmount: amount, spentAmount: 0, orderIndex: nextIndex)
            context.insert(newCat)
            categories.append(newCat)
        }
        
        try? context.save()
        reloadWidgets()
        fetchData()
        showCategoryModal = false
    }
    
    // カテゴリの削除
    func deleteCategories(at offsets: IndexSet) {
        offsets.forEach { index in
            let cat = categories[index]
            context.delete(cat)
        }
        
        // 並び順の再計算
        categories.remove(atOffsets: offsets)
        for (index, cat) in categories.enumerated() {
            cat.orderIndex = index
        }
        
        // ※ 紐づくトランザクションのcategoryIdをnilにする等の処理はTransactionServiceで後ほど対応可能
        
        try? context.save()
        reloadWidgets()
        fetchData()
    }
    
    // カテゴリの並び替え
    func moveCategories(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        
        // orderIndexの更新
        for (index, cat) in categories.enumerated() {
            cat.orderIndex = index
        }
        
        try? context.save()
        reloadWidgets()
    }
    
    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
