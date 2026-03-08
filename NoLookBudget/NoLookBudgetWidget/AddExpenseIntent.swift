import AppIntents
import SwiftData
import Foundation

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
struct AddExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "1000円を支出に追加"
    static let description = IntentDescription("ウィジェットから素早く1000円の支出（食費または変動費）を登録します。")

    // 固定金額の例
    @Parameter(title: "金額", default: 1000)
    var amount: Int
    
    // ウィジェット更新を即座に反映させるためのおまじない
    static var isDiscoverable: Bool = true
    
    init() {}
    
    init(amount: Int) {
        self.amount = amount
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // AppGroupの共有コンテナからContextを取得
        let context = SharedModelContainer.shared.mainContext
        let service = TransactionService(context: context)
        
        let descriptor = FetchDescriptor<ItemCategory>(sortBy: [SortDescriptor(\.orderIndex)])
        let categories = (try? context.fetch(descriptor)) ?? []
        let targetCategory = categories.first { $0.name == "食費" } ?? categories.first
        
        try? service.addExpense(amount: Double(amount), category: targetCategory, isIOU: false)
        
        return .result()
    }
}
