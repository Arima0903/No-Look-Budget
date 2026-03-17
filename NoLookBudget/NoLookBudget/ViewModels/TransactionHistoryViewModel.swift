import Foundation
import SwiftData
import SwiftUI
import Combine

struct TransactionDisplayItem: Identifiable {
    let id: UUID
    let date: String
    let category: String
    let totalAmount: Int
    let iouAmount: Int
    let isIncome: Bool
    let isFixedCost: Bool
    
    // UI表示用を保持するプロパティ追加
    var originalIdForEdit: UUID?
    
    var personalAmount: Int {
        totalAmount - iouAmount
    }
}

@MainActor
class TransactionHistoryViewModel: ObservableObject {
    @Published var displayItems: [TransactionDisplayItem] = []
    
    private let context: ModelContext
    private let transactionService: TransactionServiceProtocol
    
    init(context: ModelContext? = nil) {
        let ctx = context ?? SharedModelContainer.shared.mainContext
        self.context = ctx
        self.transactionService = TransactionService(context: ctx)
        fetchData()
    }
    
    func fetchData() {
        let predicate = #Predicate<ExpenseTransaction> { $0.isFixedCost == false }
        let txDesc = FetchDescriptor<ExpenseTransaction>(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
        let transactions = (try? context.fetch(txDesc)) ?? []
        
        // カテゴリの辞書化
        let catDesc = FetchDescriptor<ItemCategory>()
        let categories = (try? context.fetch(catDesc)) ?? []
        let categoryDict = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm" // 変更: わかりやすい月日表示
        
        self.displayItems = transactions.map { tx in
            let catName: String
            if tx.isFixedCost {
                catName = tx.title ?? "固定費"
            } else {
                catName = tx.categoryId.flatMap { categoryDict[$0] } ?? (tx.isIncome ? "収入" : "不明")
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
        
        // テストデータ挿入等のモックデータ処理がない場合、空の場合は何もしない
    }
    
    func deleteTransaction(at offsets: IndexSet) {
        offsets.forEach { index in
            let item = displayItems[index]
            guard !item.isFixedCost else { return } // 固定費はここから削除不可とする
            try? transactionService.deleteTransaction(id: item.id)
        }
        fetchData()
    }
}
