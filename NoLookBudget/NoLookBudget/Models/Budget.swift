import Foundation
import SwiftData

@Model
final class Budget {
    var id: UUID = UUID()
    var month: Date
    var totalAmount: Double
    var spentAmount: Double
    
    init(month: Date = Date(), totalAmount: Double = 0, spentAmount: Double = 0) {
        self.month = month
        self.totalAmount = totalAmount
        self.spentAmount = spentAmount
    }
    
    @Transient
    var remainingAmount: Double {
        return totalAmount - spentAmount
    }
}
