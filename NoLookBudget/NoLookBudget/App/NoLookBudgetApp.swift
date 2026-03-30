import SwiftUI
import SwiftData
import Foundation
import Combine // ObservableObject, @Published に必要

@main
struct NoLookBudgetApp: App {
    @StateObject private var deepLinkManager = DeepLinkManager()

    init() {
        // UIテスト用: リセットフラグが設定されている場合、オンボーディング状態をクリア
        if ProcessInfo.processInfo.environment["UI_TEST_RESET"] == "1" {
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: "agreedTermsVersion")
            defaults.removeObject(forKey: "hasCompletedTutorial")
            defaults.set("", forKey: "agreedTermsVersion")
            defaults.set(false, forKey: "hasCompletedTutorial")
            defaults.synchronize()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(deepLinkManager)
                .onOpenURL { url in
                    deepLinkManager.handleURL(url)
                }
        }
        .modelContainer(SharedModelContainer.shared)
    }
}

// MARK: - DeepLink Manager
class DeepLinkManager: ObservableObject {
    @Published var selectedCategory: String? = nil
    @Published var navigateToDashboard: Bool = false
    
    func handleURL(_ url: URL) {
        guard url.scheme == "nolookbudget" else { return }
        
        if url.host == "dashboard" {
            // ダッシュボードへの遷移指示
            navigateToDashboard = true
            selectedCategory = nil
        } else if url.host == "category" {
            // カテゴリ詳細への遷移指示
            let path = url.path.replacingOccurrences(of: "/", with: "")
            if let decodedCategory = path.removingPercentEncoding {
                selectedCategory = decodedCategory
                navigateToDashboard = false
            }
        }
    }
}
