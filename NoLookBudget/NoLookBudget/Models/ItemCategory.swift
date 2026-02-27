import Foundation
import SwiftData

@Model
final class ItemCategory {
    var id: UUID = UUID()
    var name: String
    var totalAmount: Double
    var spentAmount: Double
    var iconName: String
    var orderIndex: Int
    
    init(name: String, totalAmount: Double = 0, spentAmount: Double = 0, iconName: String = "circle", orderIndex: Int = 0) {
        self.name = name
        self.totalAmount = totalAmount
        self.spentAmount = spentAmount
        self.iconName = iconName
        self.orderIndex = orderIndex
    }
    
    @Transient
    var remainingAmount: Double {
        return totalAmount - spentAmount
    }
}
