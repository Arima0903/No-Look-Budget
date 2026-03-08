import Foundation
import SwiftData

@Model
final class Budget {
    var id: UUID = UUID()
    var month: Date
    var totalAmount: Double
    var spentAmount: Double
    var hasSetDebtRecovery: Bool = false
    
    // 追加プロパティ
    var incomeAmount: Double?
    var savingsAmount: Double?
    
    init(month: Date = Date(), totalAmount: Double = 0, spentAmount: Double = 0, hasSetDebtRecovery: Bool = false, incomeAmount: Double? = nil, savingsAmount: Double? = nil) {
        self.month = month
        self.totalAmount = totalAmount
        self.spentAmount = spentAmount
        self.hasSetDebtRecovery = hasSetDebtRecovery
        self.incomeAmount = incomeAmount
        self.savingsAmount = savingsAmount
    }
    
    @Transient
    var remainingAmount: Double {
        return totalAmount - spentAmount
    }
}

@Model
final class FixedCostSetting {
    var id: UUID = UUID()
    var name: String
    var amount: Double
    var orderIndex: Int
    
    init(name: String, amount: Double, orderIndex: Int) {
        self.name = name
        self.amount = amount
        self.orderIndex = orderIndex
    }
}
