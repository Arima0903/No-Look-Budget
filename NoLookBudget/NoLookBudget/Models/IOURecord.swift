import Foundation
import SwiftData

/// 立替（Front/IOU）プール用のレコード。メインのBudgetとは切り離して管理される。
@Model
final class IOURecord {
    var id: UUID = UUID()
    var date: Date
    var amount: Double
    var title: String
    var isResolved: Bool
    var resolvedDate: Date?
    var memo: String?
    
    init(date: Date = Date(), amount: Double, title: String = "立替", isResolved: Bool = false, resolvedDate: Date? = nil, memo: String? = nil) {
        self.date = date
        self.amount = amount
        self.title = title
        self.isResolved = isResolved
        self.resolvedDate = resolvedDate
        self.memo = memo
    }
}
