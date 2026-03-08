import SwiftData
import Foundation

@MainActor
class SharedModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Budget.self, ItemCategory.self, ExpenseTransaction.self, IOURecord.self, FixedCostSetting.self])
        let modelConfiguration: ModelConfiguration
        
        // App Group Storage Setup
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.arima0903.NoLookBudget") {
            let storeURL = appGroupURL.appendingPathComponent("NoLookBudget.store")
            modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
        } else {
            // Fallback for previews or standard localized storage if App Group isn't set up yet
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // Test/Preview Container (In-Memory)
    static func createInMemoryContainer() -> ModelContainer {
        let schema = Schema([Budget.self, ItemCategory.self, ExpenseTransaction.self, IOURecord.self, FixedCostSetting.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create in-memory ModelContainer: \(error)")
        }
    }
}
