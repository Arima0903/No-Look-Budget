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

    init(categoryName: String, context: ModelContext? = nil) {
        self.categoryName = categoryName
        let ctx = context ?? SharedModelContainer.shared.mainContext
        self.context = ctx
        self.transactionService = TransactionService(context: ctx)
        fetchData()
    }
    
    var totalBudget: Int { Int(category?.totalAmount ?? 0) }
    var currentRemaining: Int { Int(category?.remainingAmount ?? 0) }
    var debtAmount: Int {
        guard let cat = category else { return 0 }
        return cat.spentAmount > cat.totalAmount ? Int(cat.spentAmount - cat.totalAmount) : 0
    }
    
    func fetchData() {
        let name = self.categoryName
        let catDesc = FetchDescriptor<ItemCategory>(predicate: #Predicate { $0.name == name })
        self.category = (try? context.fetch(catDesc))?.first
        
        guard let catId = category?.id else { return }
        
        // PredicateでのOptional UUID比較
        let txDesc = FetchDescriptor<ExpenseTransaction>(
            predicate: #Predicate { $0.categoryId == catId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let fetchedTx = (try? context.fetch(txDesc)) ?? []
        
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
            print("取引の削除に失敗しました: \(error)")
        }
    }
}
