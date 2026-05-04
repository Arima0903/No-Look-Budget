import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class CategoryDetailViewModel: ObservableObject {
    @Published var category: ItemCategory?
    @Published var transactions: [TransactionDisplayItem] = []

    let categoryName: String
    private let context: ModelContext
    private let transactionService: TransactionServiceProtocol

    /// 当月のトランザクションから計算した支出合計
    private var monthlySpentAmount: Double = 0

    init(categoryName: String, context: ModelContext? = nil) {
        self.categoryName = categoryName
        let ctx = context ?? SharedModelContainer.shared.mainContext
        self.context = ctx
        self.transactionService = TransactionService(context: ctx)
        fetchData()
    }

    var totalBudget: Int { Int(category?.totalAmount ?? 0) }

    /// 当月のトランザクションから算出した残り予算
    var currentRemaining: Int {
        Int((category?.totalAmount ?? 0) - monthlySpentAmount)
    }

    /// 当月のトランザクションから算出した超過額
    var debtAmount: Int {
        guard let cat = category else { return 0 }
        return monthlySpentAmount > cat.totalAmount ? Int(monthlySpentAmount - cat.totalAmount) : 0
    }

    func fetchData() {
        let name = self.categoryName
        let catDesc = FetchDescriptor<ItemCategory>(predicate: #Predicate { $0.name == name })
        self.category = (try? context.fetch(catDesc))?.first

        guard let catId = category?.id else { return }

        // 当月の開始日・終了日を計算
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        var nextMonthComponents = DateComponents()
        nextMonthComponents.month = 1
        nextMonthComponents.second = -1
        let endOfMonth = calendar.date(byAdding: nextMonthComponents, to: startOfMonth)!

        // 当月のトランザクションのみ取得
        let txDesc = FetchDescriptor<ExpenseTransaction>(
            predicate: #Predicate {
                $0.categoryId == catId &&
                $0.date >= startOfMonth &&
                $0.date <= endOfMonth
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let fetchedTx = (try? context.fetch(txDesc)) ?? []

        // 当月の支出合計をトランザクションから直接計算（立替・固定費は除外）
        monthlySpentAmount = fetchedTx
            .filter { !$0.isIncome && !$0.isIOU && !$0.isFixedCost }
            .reduce(0) { $0 + $1.amount }

        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"

        self.transactions = fetchedTx.map { tx in
            TransactionDisplayItem(
                id: tx.id,
                date: formatter.string(from: tx.date),
                category: categoryName,
                totalAmount: Int(tx.amount),
                iouAmount: tx.isIOU ? Int(tx.amount) : 0,
                isIncome: tx.isIncome,
                isFixedCost: tx.isFixedCost,
                originalIdForEdit: tx.id
            )
        }
    }

    /// 指定IDの取引を削除し、データを再取得する
    func deleteTransaction(id: UUID) {
        do {
            try transactionService.deleteTransaction(id: id)
            fetchData()
        } catch {
            // エラーは握りつぶさず将来的にはアラート表示等で対応
        }
    }
}
