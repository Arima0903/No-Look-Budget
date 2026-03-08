import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class DebtRecoveryViewModel: ObservableObject {
    @Published var categories: [ItemCategory] = []
    
    private let context: ModelContext
    private let transactionService: TransactionServiceProtocol
    
    init(context: ModelContext? = nil) {
        let ctx = context ?? SharedModelContainer.shared.mainContext
        self.context = ctx
        self.transactionService = TransactionService(context: ctx)
        fetchCategories()
    }
    
    func fetchCategories() {
        let descriptor = FetchDescriptor<ItemCategory>(sortBy: [SortDescriptor(\.orderIndex)])
        self.categories = (try? context.fetch(descriptor)) ?? []
    }
    
    func recoverDebt(sourceCategoryName: String, targetCategoryName: String, amount: Double) -> Bool {
        do {
            try transactionService.recoverDebt(sourceCategoryName: sourceCategoryName, targetCategoryName: targetCategoryName, amount: amount)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            return true
        } catch {
            return false
        }
    }
}
