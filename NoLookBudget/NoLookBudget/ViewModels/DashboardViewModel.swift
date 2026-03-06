import Foundation
import SwiftData
import SwiftUI
import Combine
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
    
    private let context: ModelContext
    
    // Service
    private let transactionService: TransactionServiceProtocol
    
    init(context: ModelContext? = nil) {
        let ctx = context ?? SharedModelContainer.shared.mainContext
        self.context = ctx
        self.transactionService = TransactionService(context: ctx)
        fetchData()
    }
    
    // データの再フェッチ
    func fetchData() {
        let budgetDesc = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.month, order: .reverse)])
        let budgets = (try? context.fetch(budgetDesc)) ?? []
        
        let calendar = Calendar.current
        let currentYearMonth = calendar.dateComponents([.year, .month], from: Date())
        
        // 当月の予算データを優先的に取得し、見つからなければ作成する
        if let current = budgets.first(where: {
            let bComponents = calendar.dateComponents([.year, .month], from: $0.month)
            return bComponents.year == currentYearMonth.year && bComponents.month == currentYearMonth.month
        }) {
            self.currentBudget = current
        } else {
            let newBudget = Budget(month: Date(), totalAmount: 0, spentAmount: 0)
            context.insert(newBudget)
            try? context.save()
            self.currentBudget = newBudget
        }
        
        let catDesc = FetchDescriptor<ItemCategory>(sortBy: [SortDescriptor(\.orderIndex)])
        self.categories = (try? context.fetch(catDesc)) ?? []
        
        // 前月の借金フラグの計算
        self.hasDebtFromLastMonth = false
        if budgets.count > 1 {
            let previousBudget = budgets[1]
            if previousBudget.spentAmount > previousBudget.totalAmount && !previousBudget.hasSetDebtRecovery {
                self.hasDebtFromLastMonth = true
            }
        }
        
        // 直近の記録の取得（上位100件まで、固定費は除外）
        let predicate = #Predicate<ExpenseTransaction> { $0.isFixedCost == false }
        var txDesc = FetchDescriptor<ExpenseTransaction>(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
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
        
        // グラフ用: 日次の推移データを計算
        var newTrends: [DailyBudgetTrend] = []
        if let budget = currentBudget {
            let calendar = Calendar.current
            if let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: budget.month)),
               let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: startOfMonth) {
                
                let txDescAll = FetchDescriptor<ExpenseTransaction>(predicate: #Predicate { tx in
                    tx.date >= startOfMonth && tx.date <= endOfMonth
                }, sortBy: [SortDescriptor(\.date, order: .forward)])
                
                let allMonthTxs = (try? context.fetch(txDescAll)) ?? []
                var dailySpent: [Int: Double] = [:]
                
                for tx in allMonthTxs {
                    if !tx.isIncome && !tx.isIOU {
                        let day = calendar.component(.day, from: tx.date)
                        dailySpent[day, default: 0] += tx.amount
                    }
                }
                
                let todayDay = calendar.component(.day, from: min(Date(), endOfMonth))
                var accumulatedSpent: Double = 0
                let totalBudget = budget.totalAmount
                
                for day in 1...todayDay {
                    if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                        accumulatedSpent += dailySpent[day] ?? 0
                        let remaining = max(0, totalBudget - accumulatedSpent)
                        newTrends.append(DailyBudgetTrend(date: date, spent: accumulatedSpent, remaining: remaining))
                    }
                }
            }
        }
        self.dailyTrends = newTrends
        
        // UIの強制再描画のため
        self.objectWillChange.send()
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
