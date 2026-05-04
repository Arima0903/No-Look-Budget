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
    
    // 「その他」カテゴリ名定数
    static let otherCategoryName = "その他"

    // デフォルト固定カテゴリ（無償プランで削除・名前変更不可）
    static let defaultCategoryNames: [String] = ["食費", "交際費", "日用品", "趣味・娯楽", "交通費", "美容・衣服"]

    // プレミアムフラグ
    var isPremium: Bool {
        UserDefaults.standard.bool(forKey: "isPremiumEnabled")
    }

    // カテゴリ追加可否（プレミアム: 最大9個、無償: 固定6個のみ＝追加不可）
    var canAddCategory: Bool {
        guard isPremium else { return false }
        let customCount = categories.filter { cat in
            cat.name != Self.otherCategoryName && !Self.defaultCategoryNames.contains(cat.name)
        }.count
        return customCount < 3
    }

    /// デフォルトカテゴリかどうかを判定
    static func isDefaultCategory(_ name: String) -> Bool {
        defaultCategoryNames.contains(name) || name == otherCategoryName
    }
    
    var isCategoryNameValid: Bool {
        // スペース（全半角）、英数字（全半角）、ひらがな、カタカナ（長音・中黒含む）、漢字のみ許可
        let pattern = "^[a-zA-Z0-9ぁ-んァ-ヶー・一-龠々ａ-ｚＡ-Ｚ０-９\\s　]+$"
        return draftCategoryName.range(of: pattern, options: .regularExpression) != nil
    }
    
    private let context: ModelContext
    
    init(context: ModelContext? = nil) {
        self.context = context ?? SharedModelContainer.shared.mainContext
        fetchData()
    }
    
    func fetchData() {
        // 現在の予算を取得（当月優先、なければ最新）
        let budgetDesc = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.month, order: .reverse)])
        let budgets = (try? context.fetch(budgetDesc)) ?? []

        let calendar = Calendar.current
        let currentYearMonth = calendar.dateComponents([.year, .month], from: Date())

        let targetBudget = budgets.first(where: {
            let bComponents = calendar.dateComponents([.year, .month], from: $0.month)
            return bComponents.year == currentYearMonth.year && bComponents.month == currentYearMonth.month
        }) ?? budgets.first

        if let budget = targetBudget {
            // incomeAmount/savingsAmount が設定済みの場合のみ読み込む
            // 設定されていない場合は空文字のままにして、saveBudget() で上書きされないようにする
            if let income = budget.incomeAmount {
                self.incomeAmount = "\(Int(income))"
            }
            if let savings = budget.savingsAmount {
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
        let startOfMonth = calendar.date(from: currentYearMonth) ?? Date()

        let budgets = (try? context.fetch(budgetDesc)) ?? []
        if let existing = budgets.first(where: {
            let bComponents = calendar.dateComponents([.year, .month], from: $0.month)
            return bComponents.year == currentYearMonth.year && bComponents.month == currentYearMonth.month
        }) {
            currentBudget = existing
        } else if let prevBudget = budgets.first {
            // 当月のBudgetがない場合: 前月の設定を引き継いで新規作成
            let overAmount = max(0, prevBudget.spentAmount - prevBudget.totalAmount)
            currentBudget = Budget(
                month: startOfMonth,
                totalAmount: prevBudget.totalAmount,
                spentAmount: overAmount,
                incomeAmount: prevBudget.incomeAmount,
                savingsAmount: prevBudget.savingsAmount
            )
            context.insert(currentBudget)
        } else {
            // 初期状態でデータが一つもない場合は作成する
            currentBudget = Budget(month: startOfMonth, totalAmount: 0, spentAmount: 0)
            context.insert(currentBudget)
        }
        
        // 入力があった場合のみ更新する（空フィールドは既存値を保持して 0 上書きを防ぐ）
        let newIncome = Double(incomeAmount)
        let newSavings = Double(savingsAmount)

        if let income = newIncome {
            currentBudget.incomeAmount = income
        }
        if let savings = newSavings {
            currentBudget.savingsAmount = savings
        }

        // 計算には入力値 or 既存値を使う（どちらもなければ 0）
        let income = newIncome ?? currentBudget.incomeAmount ?? 0
        let savings = newSavings ?? currentBudget.savingsAmount ?? 0
        let totalFixed = fixedCosts.reduce(0) { $0 + $1.amount }

        // 当月の臨時収入の合計を取得してベース予算に合算する
        var extraIncomeTotal: Double = 0
        if let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentBudget.month)),
           let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: startOfMonth) {
            let predicate = #Predicate<ExpenseTransaction> { (tx: ExpenseTransaction) in
                tx.date >= startOfMonth && tx.date <= endOfMonth && tx.isIncome == true
            }
            let desc = FetchDescriptor<ExpenseTransaction>(predicate: predicate)
            if let incomes = try? context.fetch(desc) {
                extraIncomeTotal = incomes.reduce(0) { $0 + $1.amount }
            }
        }

        let calculatedBaseBudget = income - savings - totalFixed + extraIncomeTotal
        // 自由に使える変動費のベース予算を上書き
        currentBudget.totalAmount = max(0, calculatedBaseBudget)
        
        // 固定費の履歴(Transaction)を当月分同期する
        syncFixedCostTransactions(for: currentBudget.month)

        try? context.save()
        // 「その他」カテゴリを同期（全体予算が変わったため残額を再計算）
        syncOtherCategory()
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

    /// デフォルトカテゴリの場合は名前変更不可（予算額のみ変更可）
    var isEditingDefaultCategory: Bool {
        guard let cat = editingCategory else { return false }
        return Self.defaultCategoryNames.contains(cat.name)
    }
    
    // カテゴリの保存（追加または更新）
    func saveCategory() {
        guard !draftCategoryName.isEmpty,
              let amount = Double(draftCategoryAmount) else { return }

        if let category = editingCategory {
            category.name = draftCategoryName
            category.totalAmount = amount
        } else {
            // 「その他」カテゴリの直前に挿入する
            let insertIndex = categories.firstIndex(where: { $0.name == Self.otherCategoryName }) ?? categories.count
            // 挿入位置以降の orderIndex をずらす
            for i in insertIndex..<categories.count {
                categories[i].orderIndex = i + 1
            }
            let newCat = ItemCategory(name: draftCategoryName, totalAmount: amount, spentAmount: 0, orderIndex: insertIndex)
            context.insert(newCat)
            categories.insert(newCat, at: insertIndex)
        }

        try? context.save()
        syncOtherCategory()
        reloadWidgets()
        fetchData()
        showCategoryModal = false
    }

    // カテゴリの削除（デフォルト固定カテゴリ・その他は削除不可、カスタムカテゴリのみ削除可）
    func deleteCategories(at offsets: IndexSet) {
        // デフォルトカテゴリと「その他」を除外して削除
        let deletableOffsets = offsets.filter { !Self.isDefaultCategory(categories[$0].name) }
        deletableOffsets.forEach { index in
            context.delete(categories[index])
        }

        // 並び順の再計算
        categories.remove(atOffsets: IndexSet(deletableOffsets))
        for (index, cat) in categories.enumerated() {
            cat.orderIndex = index
        }

        // ※ 紐づくトランザクションのcategoryIdをnilにする等の処理はTransactionServiceで後ほど対応可能

        try? context.save()
        syncOtherCategory()
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
    
    /// 「その他」カテゴリを自動管理する
    /// - 存在しない場合は作成（常に最後尾）
    /// - totalAmount = max(0, 全体変動費予算 - 他カテゴリ合算)
    private func syncOtherCategory() {
        // 当月のベース予算を取得
        let budgetDesc = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.month, order: .reverse)])
        let budgets = (try? context.fetch(budgetDesc)) ?? []
        let cal = Calendar.current
        let currentYM = cal.dateComponents([.year, .month], from: Date())
        let totalBudget = budgets.first(where: {
            let c = cal.dateComponents([.year, .month], from: $0.month)
            return c.year == currentYM.year && c.month == currentYM.month
        })?.totalAmount ?? budgets.first?.totalAmount ?? 0

        // 全カテゴリを取得
        let catDesc = FetchDescriptor<ItemCategory>(sortBy: [SortDescriptor(\.orderIndex)])
        let allCats = (try? context.fetch(catDesc)) ?? []
        let regularCats = allCats.filter { $0.name != Self.otherCategoryName }
        let regularTotal = regularCats.reduce(0) { $0 + $1.totalAmount }
        let otherAmount = max(0, totalBudget - regularTotal)

        if let otherCat = allCats.first(where: { $0.name == Self.otherCategoryName }) {
            // 既存の「その他」を更新（常に最後尾に配置）
            otherCat.totalAmount = otherAmount
            otherCat.orderIndex = regularCats.count
        } else {
            // 初回: 「その他」を作成
            let newOtherCat = ItemCategory(
                name: Self.otherCategoryName,
                totalAmount: otherAmount,
                spentAmount: 0,
                orderIndex: regularCats.count
            )
            context.insert(newOtherCat)
        }
        try? context.save()
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

        let catDesc = FetchDescriptor<ItemCategory>(sortBy: [SortDescriptor(\.orderIndex)])
        let cats = (try? context.fetch(catDesc)) ?? []

        // 当月のカテゴリ別支出額を ExpenseTransaction から集計
        var monthlyCatSpent: [UUID: Double] = [:]
        if let startOfMonth = calendar.date(from: currentYM),
           let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: startOfMonth) {
            let txPredicate = #Predicate<ExpenseTransaction> { tx in
                tx.date >= startOfMonth && tx.date <= endOfMonth
                && tx.isIncome == false && tx.isIOU == false && tx.isFixedCost == false
            }
            let txDesc = FetchDescriptor<ExpenseTransaction>(predicate: txPredicate)
            let monthlyTxs = (try? context.fetch(txDesc)) ?? []
            for tx in monthlyTxs {
                if let catId = tx.categoryId {
                    monthlyCatSpent[catId, default: 0] += tx.amount
                }
            }
        }

        struct CatSnap: Encodable {
            let name: String; let remainingAmount: Int; let ratio: Double
        }
        struct Snap: Encodable {
            let budgetTotal: Double; let budgetSpent: Double; let categories: [CatSnap]; let usePercentageDisplay: Bool
        }
        let usePercentage = UserDefaults.standard.bool(forKey: "widgetPercentageDisplay")
        let isPremiumFlag = UserDefaults.standard.bool(forKey: "isPremiumEnabled")
        let maxCats = isPremiumFlag ? 9 : 6
        let displayCats = cats.filter { $0.name != Self.otherCategoryName }
        let snap = Snap(
            budgetTotal: displayTotal,
            budgetSpent: budgetSpent,
            categories: Array(displayCats.prefix(maxCats)).map { cat in
                let spent = monthlyCatSpent[cat.id] ?? 0
                return CatSnap(
                    name: cat.name,
                    remainingAmount: Int(cat.totalAmount - spent),
                    ratio: cat.totalAmount > 0 ? (spent / cat.totalAmount) : 0.0
                )
            },
            usePercentageDisplay: usePercentage
        )
        if let encoded = try? JSONEncoder().encode(snap) {
            defaults.set(encoded, forKey: key)
        }
    }
}
