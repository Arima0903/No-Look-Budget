import Foundation
import SwiftData

@Model
final class ExpenseTransaction {
    var id: UUID = UUID()
    var date: Date
    var amount: Double
    var categoryId: UUID? 
    var isIOU: Bool
    
    init(date: Date = Date(), amount: Double, categoryId: UUID? = nil, isIOU: Bool = false) {
        self.date = date
        self.amount = amount
        self.categoryId = categoryId
        self.isIOU = isIOU
    }
}
