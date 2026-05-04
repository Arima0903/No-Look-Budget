import SwiftUI
import SwiftData
import Foundation
import Combine // ObservableObject, @Published に必要

@main
struct NoLookBudgetApp: App {
    @StateObject private var deepLinkManager = DeepLinkManager()
    // StoreKitManager.shared はinit()で自動起動されるため、明示的な保持不要

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
                .task {
                    // アプリ起動時に通知スケジュールを再登録
                    NotificationService.rescheduleAll()
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
