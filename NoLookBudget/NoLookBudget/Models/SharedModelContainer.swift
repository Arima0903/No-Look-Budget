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

// MARK: - App Theme (Astronaut Theme)
import SwiftUI

enum Theme {
    // Background Colors (Deep Space Navy)
    static let spaceNavy = Color(red: 8/255.0, green: 11/255.0, blue: 20/255.0) // #080B14
    static let spaceNavyLighter = Color(red: 26/255.0, green: 26/255.0, blue: 46/255.0) // #1A1A2E
    
    // Accent Colors
    static let spaceGreen = Color(red: 74/255.0, green: 222/255.0, blue: 128/255.0) // #4ADE80
    static let spaceGreenDark = Color(red: 34/255.0, green: 197/255.0, blue: 94/255.0) // #22C55E
    
    static let coralRed = Color(red: 239/255.0, green: 68/255.0, blue: 68/255.0) // #EF4444
    static let warmOrange = Color(red: 251/255.0, green: 146/255.0, blue: 60/255.0) // #FB923C
    
    // Sub text colors
    static let textMain = Color.white
    static let textSub = Color.gray
    
    // Gradients
    static let safeGradient = LinearGradient(
        colors: [spaceGreen, spaceGreenDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let dangerGradient = LinearGradient(
        colors: [warmOrange, coralRed],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let spaceBackground = LinearGradient(
        colors: [spaceNavy, spaceNavyLighter],
        startPoint: .top,
        endPoint: .bottom
    )
}
