import Foundation
import SwiftData
import SwiftUI
import Combine

/// カテゴリ別の振り返りデータ
struct CategoryBreakdown: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let budget: Double
    let spent: Double

    var remaining: Double { budget - spent }
    var isOverBudget: Bool { spent > budget }
    /// 予算に対する消費率（0.0〜1.0+）
    var usageRate: Double { budget > 0 ? spent / budget : 0 }
}

@MainActor
class MonthlyReviewViewModel: ObservableObject {
    @Published var targetBudget: Double = 0
    @Published var actualSpent: Double = 0
    @Published var reviewMonthString: String = ""
    @Published var overCategories: [(name: String, amount: Double)] = []
    @Published var cumulativeSavings: Int = 0
    /// カテゴリ別の予算・支出データ（支出額の降順）
    @Published var categoryBreakdowns: [CategoryBreakdown] = []

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
        max(0, actualSpent - targetBudget)
    }

    var surplusAmount: Double {
        max(0, targetBudget - actualSpent)
    }

    // カンマ区切りフォーマット（共通ユーティリティに委譲）
    func formatted(_ value: Double) -> String {
        formatCurrency(value)
    }

    func fetchData() {
        let budgetDesc = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.month, order: .reverse)])
        let budgets = (try? context.fetch(budgetDesc)) ?? []

        // 直近の月の前の月を振り返り対象とする（データが1件のみなら最新月）
        let targetBudgetOpt: Budget? = budgets.count > 1 ? budgets[1] : budgets.first

        if let reviewBudget = targetBudgetOpt {
            self.targetBudget = reviewBudget.totalAmount
            self.actualSpent = reviewBudget.spentAmount

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "M月"
            self.reviewMonthString = formatter.string(from: reviewBudget.month)

            // 全体予算オーバー時のみカテゴリ別超過を計算
            if self.actualSpent > self.targetBudget {
                let catDesc = FetchDescriptor<ItemCategory>()
                let categories = (try? context.fetch(catDesc)) ?? []
                let overCats = categories
                    .filter { $0.spentAmount > $0.totalAmount }
                    .map { (name: $0.name, amount: $0.spentAmount - $0.totalAmount) }
                    .sorted { $0.amount > $1.amount }
                self.overCategories = Array(overCats.prefix(3))
            } else {
                self.overCategories = []
            }
        }

        // カテゴリ別データ取得
        let catDesc = FetchDescriptor<ItemCategory>(sortBy: [SortDescriptor(\.orderIndex)])
        let allCategories = (try? context.fetch(catDesc)) ?? []
        self.categoryBreakdowns = allCategories
            .filter { $0.totalAmount > 0 || $0.spentAmount > 0 }
            .sorted { $0.spentAmount > $1.spentAmount }
            .map { CategoryBreakdown(
                name: $0.name,
                iconName: $0.iconName,
                budget: $0.totalAmount,
                spent: $0.spentAmount
            )}

        // 累計節約額: 全月の黒字分を合算
        let totalSaved = budgets.reduce(0.0) { acc, b in
            let surplus = b.totalAmount - b.spentAmount
            return acc + (surplus > 0 ? surplus : 0)
        }
        self.cumulativeSavings = Int(totalSaved)
    }
}
