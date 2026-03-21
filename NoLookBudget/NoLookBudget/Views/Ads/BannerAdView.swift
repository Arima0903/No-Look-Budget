import SwiftUI
import UIKit

// ─────────────────────────────────────────────────────────────
// MARK: - 広告ユニットID 設定
// ─────────────────────────────────────────────────────────────
// DEBUG ビルドではテスト用ID、Release ビルドでは Secrets.xcconfig の本番IDを使用
enum AdUnitID {
    static let banner: String = {
        #if DEBUG
        // Google公式テスト用ID（開発・シミュレーター時）
        return "ca-app-pub-3940256099942544/2934735716"
        #else
        // 本番用ID: Info.plist 経由で Secrets.xcconfig から読み込み
        return Bundle.main.object(forInfoDictionaryKey: "ADMOB_BANNER_ID") as? String ?? ""
        #endif
    }()

    static let appID: String = {
        #if DEBUG
        return "ca-app-pub-3940256099942544~1458002511"
        #else
        return Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String ?? ""
        #endif
    }()
}

// ─────────────────────────────────────────────────────────────
// MARK: - BannerAdView
//
// 【現在の状態】
//   Google Mobile Ads SDK 未導入のため、プレースホルダーを表示。
//   SDK 導入後に AdBannerRepresentable を有効化する。
//
// 【SDK 導入手順】
//   1. Xcode → File → Add Package Dependencies
//      URL: https://github.com/googleads/swift-package-manager-google-mobile-ads
//   2. このファイルの下部にある AdBannerRepresentable のコメントを解除
//   3. BannerAdView.body の AdBannerPlaceholder() を
//      AdBannerRepresentable(adUnitID: adUnitID) に差し替える
// ─────────────────────────────────────────────────────────────

struct BannerAdView: View {
    @AppStorage("isPremiumEnabled") private var isPremiumEnabled = false

    /// 広告ユニットID（省略時はテスト用IDを使用）
    var adUnitID: String = AdUnitID.banner

    var body: some View {
        // プレミアムユーザーには広告を表示しない
        if !isPremiumEnabled {
            AdBannerPlaceholder()
            // ▼ SDK 導入後はここを差し替える:
            // AdBannerRepresentable(adUnitID: adUnitID)
            //     .frame(height: 50)
            //     .frame(maxWidth: .infinity)
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: - SDK 未導入時のプレースホルダー
// ─────────────────────────────────────────────────────────────
private struct AdBannerPlaceholder: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .frame(height: 50)
            Rectangle()
                .fill(Color.white.opacity(0.04))
                .frame(height: 50)
            HStack(spacing: 6) {
                Image(systemName: "megaphone.fill")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.4))
                Text("Ad")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: - SDK 導入後はこちらのコメントを解除する
//         (GoogleMobileAds を import した上で有効化)
// ─────────────────────────────────────────────────────────────
/*
import GoogleMobileAds

struct AdBannerRepresentable: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeFluid)
        banner.adUnitID = adUnitID
        banner.rootViewController = rootViewController()
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
    }
}
*/

#Preview {
    VStack {
        Spacer()
        BannerAdView()
    }
    .background(Color.black)
}
