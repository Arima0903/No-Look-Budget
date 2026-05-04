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
    /// アプリ使用開始月の文字列（例: "2026年3月"）
    @Published var savingsStartMonth: String = ""
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

        let calendar = Calendar.current

        // 前月を振り返り対象とする（「振り返り」は終わった月を見るもの）
        guard let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: Date()) else { return }
        let prevYM = calendar.dateComponents([.year, .month], from: prevMonthDate)

        let targetBudgetOpt = budgets.first(where: {
            let c = calendar.dateComponents([.year, .month], from: $0.month)
            return c.year == prevYM.year && c.month == prevYM.month
        })

        // 月表示用フォーマッター
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "ja_JP")
        monthFormatter.dateFormat = "M月"

        if let reviewBudget = targetBudgetOpt {
            self.targetBudget = reviewBudget.totalAmount
            self.actualSpent = reviewBudget.spentAmount
            self.reviewMonthString = monthFormatter.string(from: reviewBudget.month)

            // 前月のトランザクションからカテゴリ別支出を集計
            guard let startOfMonth = calendar.date(from: prevYM),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: startOfMonth) else { return }

            let txPredicate = #Predicate<ExpenseTransaction> { tx in
                tx.date >= startOfMonth && tx.date <= endOfMonth
                && tx.isIncome == false && tx.isIOU == false && tx.isFixedCost == false
            }
            let txDesc = FetchDescriptor<ExpenseTransaction>(predicate: txPredicate)
            let monthlyTxs = (try? context.fetch(txDesc)) ?? []

            // カテゴリ別月間支出を集計
            var catSpent: [UUID: Double] = [:]
            for tx in monthlyTxs {
                if let catId = tx.categoryId {
                    catSpent[catId, default: 0] += tx.amount
                }
            }

            // カテゴリ情報を取得
            let catDesc = FetchDescriptor<ItemCategory>(sortBy: [SortDescriptor(\.orderIndex)])
            let allCategories = (try? context.fetch(catDesc)) ?? []

            // 超過カテゴリ（全体予算オーバー時のみ）
            if self.actualSpent > self.targetBudget {
                let overCats = allCategories
                    .compactMap { cat -> (name: String, amount: Double)? in
                        let spent = catSpent[cat.id] ?? 0
                        guard spent > cat.totalAmount else { return nil }
                        return (name: cat.name, amount: spent - cat.totalAmount)
                    }
                    .sorted { $0.amount > $1.amount }
                self.overCategories = Array(overCats.prefix(3))
            } else {
                self.overCategories = []
            }

            // カテゴリ別内訳（月間トランザクションベース）
            self.categoryBreakdowns = allCategories
                .filter { cat in
                    let spent = catSpent[cat.id] ?? 0
                    return cat.totalAmount > 0 || spent > 0
                }
                .sorted { (catSpent[$0.id] ?? 0) > (catSpent[$1.id] ?? 0) }
                .map { cat in
                    let spent = catSpent[cat.id] ?? 0
                    return CategoryBreakdown(
                        name: cat.name,
                        iconName: cat.iconName,
                        budget: cat.totalAmount,
                        spent: spent
                    )
                }
        } else {
            // 前月の予算データがない場合
            self.reviewMonthString = monthFormatter.string(from: prevMonthDate)
            self.targetBudget = 0
            self.actualSpent = 0
            self.overCategories = []
            self.categoryBreakdowns = []
        }

        // 累計節約額: 完了した月の収支を合算（当月は未確定なので除外）
        let currentYM = calendar.dateComponents([.year, .month], from: Date())
        let completedBudgets = budgets.filter { b in
            let bYM = calendar.dateComponents([.year, .month], from: b.month)
            return bYM.year != currentYM.year || bYM.month != currentYM.month
        }
        // 黒字月・赤字月を通算したネット節約額（マイナスにはしない）
        let netSaved = completedBudgets.reduce(0.0) { acc, b in
            return acc + (b.totalAmount - b.spentAmount)
        }
        self.cumulativeSavings = max(0, Int(netSaved))

        // アプリ使用開始月（最も古い予算レコードの月）
        if let earliest = budgets.last {
            let startFormatter = DateFormatter()
            startFormatter.locale = Locale(identifier: "ja_JP")
            startFormatter.dateFormat = "yyyy年M月"
            self.savingsStartMonth = startFormatter.string(from: earliest.month)
        }
    }
}
