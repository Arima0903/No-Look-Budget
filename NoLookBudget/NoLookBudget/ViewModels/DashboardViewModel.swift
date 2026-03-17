import Foundation
import SwiftData
import SwiftUI
import Combine

struct DailyBudgetTrend: Identifiable {
    let id = UUID()
    let date: Date
    let spent: Double
    let remaining: Double
}

@MainActor
class DashboardViewModel: ObservableObject {
    // データ状態
    @Published var currentBudget: Budget? = nil
    @Published var categories: [ItemCategory] = []
    @Published var recentTransactions: [TransactionDisplayItem] = []
    @Published var dailyTrends: [DailyBudgetTrend] = []

    // アプリ内表示用状態
    @Published var showInputModal = false
    @Published var showSettings = false
    @Published var showHistory = false
    @Published var showMonthlyReview = false
    @Published var showBudgetConfig = false
    @Published var showCategoryConfig = false
    @Published var showSideMenu = false
    @Published var showIOU = false
    @Published var initialInputCategory: String? = nil

    @Published var hasDebtFromLastMonth = false // ToDo: 実データに基づく判定
    @Published var dailySpending: [Int: Double] = [:]  // 日付(1〜31)→その日の合計支出（カレンダー用）

    // 年月セレクタ: 選択中の年・月（デフォルトは当月）
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @Published var selectedMonth: Int = Calendar.current.component(.month, from: Date())

    /// 表示中の月が当月かどうか
    var isCurrentMonth: Bool {
        let cal = Calendar.current
        let now = Date()
        return selectedYear == cal.component(.year, from: now)
            && selectedMonth == cal.component(.month, from: now)
    }

    /// ツールバーに表示する「yyyy年M月」文字列
    var selectedMonthTitle: String {
        var comps = DateComponents()
        comps.year = selectedYear
        comps.month = selectedMonth
        let date = Calendar.current.date(from: comps) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    /// 1か月前に移動
    func selectPreviousMonth() {
        if selectedMonth == 1 {
            selectedMonth = 12
            selectedYear -= 1
        } else {
            selectedMonth -= 1
        }
        fetchData()
    }

    /// 1か月後に移動（当月以降への移動は禁止）
    func selectNextMonth() {
        guard !isCurrentMonth else { return }
        if selectedMonth == 12 {
            selectedMonth = 1
            selectedYear += 1
        } else {
            selectedMonth += 1
        }
        fetchData()
    }

    private let context: ModelContext

    // Service
    private let transactionService: TransactionServiceProtocol

    init(context: ModelContext? = nil) {
        let ctx = context ?? SharedModelContainer.shared.mainContext
        self.context = ctx
        self.transactionService = TransactionService(context: ctx)
        fetchData()
    }

    // データの再フェッチ（selectedYear / selectedMonth を参照）
    func fetchData() {
        let budgetDesc = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.month, order: .reverse)])
        let budgets = (try? context.fetch(budgetDesc)) ?? []

        let calendar = Calendar.current

        // selectedYear / selectedMonth から対象日付を構築
        var targetComps = DateComponents()
        targetComps.year = selectedYear
        targetComps.month = selectedMonth
        targetComps.day = 1
        let selectedDate = calendar.date(from: targetComps) ?? Date()
        let targetYearMonth = calendar.dateComponents([.year, .month], from: selectedDate)

        // 選択月の予算データを取得。見つからない場合、当月のみ自動作成する
        if let current = budgets.first(where: {
            let bComponents = calendar.dateComponents([.year, .month], from: $0.month)
            return bComponents.year == targetYearMonth.year && bComponents.month == targetYearMonth.month
        }) {
            self.currentBudget = current
        } else {
            if isCurrentMonth {
                // 当月のみ: 予算が未作成なら自動作成
                let newBudget = Budget(month: selectedDate, totalAmount: 0, spentAmount: 0)
                context.insert(newBudget)
                try? context.save()
                self.currentBudget = newBudget
            } else {
                // 過去月でデータなし: nil のまま（自動作成しない）
                self.currentBudget = nil
            }
        }

        let catDesc = FetchDescriptor<ItemCategory>(sortBy: [SortDescriptor(\.orderIndex)])
        self.categories = (try? context.fetch(catDesc)) ?? []

        // 前月の借金フラグの計算（当月表示中のみ有効）
        self.hasDebtFromLastMonth = false
        if isCurrentMonth && budgets.count > 1 {
            let previousBudget = budgets[1]
            if previousBudget.spentAmount > previousBudget.totalAmount && !previousBudget.hasSetDebtRecovery {
                self.hasDebtFromLastMonth = true
            }
        }

        // 選択月の開始・終了日を計算
        guard let startOfSelectedMonth = calendar.date(from: targetYearMonth),
              let endOfSelectedMonth = calendar.date(
                byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59),
                to: startOfSelectedMonth
              )
        else {
            self.recentTransactions = []
            self.dailySpending = [:]
            self.dailyTrends = []
            self.objectWillChange.send()
            return
        }

        // 直近の記録の取得（固定費除外・選択月のみ）
        let predicate = #Predicate<ExpenseTransaction> {
            $0.isFixedCost == false
            && $0.date >= startOfSelectedMonth
            && $0.date <= endOfSelectedMonth
        }
        var txDesc = FetchDescriptor<ExpenseTransaction>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        txDesc.fetchLimit = 100
        let transactions = (try? context.fetch(txDesc)) ?? []
        let categoryDict = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"

        self.recentTransactions = transactions.map { tx in
            let catName: String
            if tx.isFixedCost {
                catName = tx.title ?? "固定費"
            } else {
                catName = tx.categoryId.flatMap { categoryDict[$0] } ?? (tx.isIncome ? "臨時収入" : "不明")
            }
            let totalAmount = Int(tx.amount)
            let iouAmount = tx.isIOU ? Int(tx.amount) : 0

            return TransactionDisplayItem(
                id: tx.id,
                date: formatter.string(from: tx.date),
                category: catName,
                totalAmount: totalAmount,
                iouAmount: iouAmount,
                isIncome: tx.isIncome,
                isFixedCost: tx.isFixedCost,
                originalIdForEdit: tx.id
            )
        }

        // グラフ用: 日次の推移データを計算（選択月）
        var newTrends: [DailyBudgetTrend] = []
        if let budget = currentBudget {
            let txDescAll = FetchDescriptor<ExpenseTransaction>(predicate: #Predicate { tx in
                tx.date >= startOfSelectedMonth && tx.date <= endOfSelectedMonth
            }, sortBy: [SortDescriptor(\.date, order: .forward)])

            let allMonthTxs = (try? context.fetch(txDescAll)) ?? []
            var dailySpent: [Int: Double] = [:]

            for tx in allMonthTxs {
                if !tx.isIncome && !tx.isIOU {
                    let day = calendar.component(.day, from: tx.date)
                    dailySpent[day, default: 0] += tx.amount
                }
            }
            self.dailySpending = dailySpent  // カレンダービュー用に保持

            // トレンドは当月なら本日まで、過去月なら月末まで
            let lastDay: Int
            if isCurrentMonth {
                lastDay = calendar.component(.day, from: min(Date(), endOfSelectedMonth))
            } else {
                lastDay = calendar.component(.day, from: endOfSelectedMonth)
            }
            var accumulatedSpent: Double = 0
            let totalBudget = budget.totalAmount

            for day in 1...lastDay {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfSelectedMonth) {
                    accumulatedSpent += dailySpent[day] ?? 0
                    let remaining = max(0, totalBudget - accumulatedSpent)
                    newTrends.append(DailyBudgetTrend(date: date, spent: accumulatedSpent, remaining: remaining))
                }
            }
        } else {
            self.dailySpending = [:]
        }
        self.dailyTrends = newTrends

        // 当月表示中のみウィジェット用スナップショットを更新する
        if isCurrentMonth {
            saveWidgetSnapshot()
        }

        // UIの強制再描画のため
        self.objectWillChange.send()
    }

    /// App Group UserDefaults にウィジェット用スナップショットを書き込む
    private func saveWidgetSnapshot() {
        let suiteName = "group.com.arima0903.NoLookBudget"
        let key = "widget_budget_snapshot_v1"
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }

        let budget = currentBudget
        let displayTotal = budget?.incomeAmount ?? budget?.totalAmount ?? 0.0
        let fixedAndSavings = displayTotal - (budget?.totalAmount ?? 0.0)
        let budgetSpent = (budget?.spentAmount ?? 0.0) + fixedAndSavings

        struct CatSnap: Encodable {
            let name: String; let remainingAmount: Int; let ratio: Double
        }
        struct Snap: Encodable {
            let budgetTotal: Double; let budgetSpent: Double; let categories: [CatSnap]
        }
        let snap = Snap(
            budgetTotal: displayTotal,
            budgetSpent: budgetSpent,
            categories: categories.prefix(6).map {
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

    // 直近トランザクションの削除
    func deleteRecentTransaction(at offsets: IndexSet) {
        offsets.forEach { index in
            let item = recentTransactions[index]
            guard !item.isFixedCost else { return } // 固定費はここから削除不可とする
            try? transactionService.deleteTransaction(id: item.id)
        }
        fetchData()
    }

    // サイドメニュー用等のアクション
    func openInputModal(with category: String? = nil) {
        self.initialInputCategory = category
        self.showInputModal = true
    }
}
