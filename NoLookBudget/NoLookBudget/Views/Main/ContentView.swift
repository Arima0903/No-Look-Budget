import SwiftUI

struct ContentView: View {
    /// ユーザーが同意済みの規約バージョンを永続化
    @AppStorage("agreedTermsVersion") private var agreedTermsVersion: String = ""

    /// チュートリアル完了フラグ
    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial: Bool = false

    /// 同意画面の表示フラグ
    /// - 未同意（初回起動）または規約バージョンが更新された場合に true
    private var needsConsent: Bool {
        agreedTermsVersion != TermsVersion.current
    }

    var body: some View {
        if needsConsent {
            // 規約未同意 → 同意画面を表示（dismissできない）
            TermsConsentView {
                // 同意ボタンタップ時: 現在のバージョンを記録して本体へ
                agreedTermsVersion = TermsVersion.current
            }
        } else if !hasCompletedTutorial {
            // 規約同意済み・チュートリアル未完了 → チュートリアル表示
            TutorialView {
                hasCompletedTutorial = true
                // チュートリアル完了後に通知許可を要求
                Task {
                    let granted = await NotificationService.requestAuthorization()
                    if granted {
                        NotificationService.rescheduleAll()
                    }
                }
            }
        } else {
            // 全て完了 → ダッシュボードへ
            DashboardView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DeepLinkManager())
}
