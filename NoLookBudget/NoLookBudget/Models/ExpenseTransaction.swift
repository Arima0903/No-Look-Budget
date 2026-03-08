import Foundation
import SwiftData

@Model
final class ExpenseTransaction {
    var id: UUID = UUID()
    var date: Date
    var amount: Double
    var categoryId: UUID? 
    var isIOU: Bool
    var isIncome: Bool
    
    // 追加プロパティ（固定費等用）
    var isFixedCost: Bool
    var title: String?
    var fixedCostSettingId: UUID?
    
    init(date: Date = Date(), amount: Double, categoryId: UUID? = nil, isIOU: Bool = false, isIncome: Bool = false, isFixedCost: Bool = false, title: String? = nil, fixedCostSettingId: UUID? = nil) {
        self.date = date
        self.amount = amount
        self.categoryId = categoryId
        self.isIOU = isIOU
        self.isIncome = isIncome
        self.isFixedCost = isFixedCost
        self.title = title
        self.fixedCostSettingId = fixedCostSettingId
    }
}
