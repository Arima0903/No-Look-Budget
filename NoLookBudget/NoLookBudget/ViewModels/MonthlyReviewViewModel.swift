import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class MonthlyReviewViewModel: ObservableObject {
    @Published var targetBudget: Double = 0
    @Published var actualSpent: Double = 0
    @Published var reviewMonthString: String = ""
    @Published var overCategories: [(name: String, amount: Double)] = []
    
    private let context: ModelContext
    private let transactionService: TransactionServiceProtocol
    
    init(context: ModelContext? = nil) {
        let ctx = context ?? SharedModelContainer.shared.mainContext
        self.context = ctx
        self.transactionService = TransactionService(context: ctx)
        fetchData()
    }
    
    var isOverBudget: Bool {
        actualSpent > targetBudget
    }
    
    var overAmount: Double {
        actualSpent - targetBudget
    }
    
    func fetchData() {
        let budgetDesc = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.month, order: .reverse)])
        let budgets = (try? context.fetch(budgetDesc)) ?? []
        
        // 直近の月(budgets.first)ではなく、その前の月(budgets[1])を振り返りの対象とする。
        // もしデータが1ヶ月分しかない場合は、とりあえずその月を表示する。
        let targetBudgetOpt: Budget? = budgets.count > 1 ? budgets[1] : budgets.first
        
        if let reviewBudget = targetBudgetOpt {
            self.targetBudget = reviewBudget.totalAmount
            self.actualSpent = reviewBudget.spentAmount
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "M月"
            self.reviewMonthString = formatter.string(from: reviewBudget.month)
            
            // 全体予算オーバーの場合のみ、詳細なカテゴリ超過を計算して表示する
            if self.actualSpent > self.targetBudget {
                let catDesc = FetchDescriptor<ItemCategory>()
                let categories = (try? context.fetch(catDesc)) ?? []
                
                let overCats = categories
                    .filter { $0.spentAmount > $0.totalAmount }
                    .map { (name: $0.name, amount: $0.spentAmount - $0.totalAmount) }
                    .sorted { $0.amount > $1.amount }
                
                // 上位3件を表示
                self.overCategories = Array(overCats.prefix(3))
            } else {
                self.overCategories = []
            }
        }
    }
    
    func processToNextMonth() {
        try? transactionService.processMonthlyReview(currentDate: Date())
        // 成功時のHapticFeedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
