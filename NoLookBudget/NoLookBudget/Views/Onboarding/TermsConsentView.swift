import SwiftUI

// ─────────────────────────────────────────────────────────────
// MARK: - 規約バージョン管理
// 利用規約 or プライバシーポリシーを更新したら、この値を上げてください。
// ユーザーが再同意を求められます。
// ─────────────────────────────────────────────────────────────
enum TermsVersion {
    static let current = "1.0.0"
}

struct TermsConsentView: View {
    /// 同意完了時に呼ばれるコールバック
    var onAgreed: () -> Void

    @State private var hasScrolledToBottom = false
    @State private var selectedTab = 0

    private let tabs = ["利用規約", "プライバシーポリシー"]

    var body: some View {
        ZStack {
            Theme.spaceNavy.ignoresSafeArea()

            // 上部グロー
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.08),
                    Color.clear
                ]),
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // ─── ヘッダー ───────────────────────────────
                VStack(spacing: 12) {
                    Image("astronaut_mascot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .blendMode(.screen)
                        .padding(.top, 40)

                    Text("Orbit Budget へようこそ")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("ご利用の前に、利用規約とプライバシーポリシーを\nご確認ください。")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // ─── タブ切替 ───────────────────────────────
                Picker("", selection: $selectedTab) {
                    ForEach(0..<tabs.count, id: \.self) { i in
                        Text(tabs[i]).tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // ─── 規約本文スクロールエリア ────────────────
                ScrollView(showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        if selectedTab == 0 {
                            termsContent
                        } else {
                            privacyContent
                        }

                        // スクロール末尾検知用のアンカー
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    hasScrolledToBottom = true
                                }
                        }
                        .frame(height: 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .frame(maxHeight: .infinity)
                .background(Color.white.opacity(0.03))
                .cornerRadius(16)
                .padding(.horizontal, 16)

                // ─── 同意ボタン ──────────────────────────────
                VStack(spacing: 8) {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onAgreed()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("同意してはじめる")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.9, blue: 0.6), Color(red: 0.2, green: 0.8, blue: 0.5)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityIdentifier("agreeButton")

                    Text("「同意してはじめる」をタップすることで、利用規約および\nプライバシーポリシーに同意したものとみなします。")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .preferredColorScheme(.dark)
    }

    // ─────────────────────────────────────────────────────────
    // MARK: - 利用規約サマリー本文
    // ─────────────────────────────────────────────────────────
    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            consentSectionTitle("利用規約（バージョン \(TermsVersion.current)）")

            consentBlock(
                title: "第1条（本規約の適用）",
                body: "本規約はOrbit Budget（以下「本アプリ」）の利用に関する条件を定めます。ダウンロード・インストール時点で同意とみなします。"
            )
            consentBlock(
                title: "第2条（サービスの内容）",
                body: "本アプリは個人の家計管理を支援するiOSアプリです。サービス内容は予告なく変更・廃止される場合があります。"
            )
            consentBlock(
                title: "第3条（COMMANDER PLAN）",
                body: "一部機能は有料サブスクリプションが必要です。サブスクは月額自動更新型です。解約はiOS設定のサブスクリプション管理から、次回更新の24時間前までに行ってください。"
            )
            consentBlock(
                title: "第4条（禁止事項）",
                body: "リバースエンジニアリング・違法行為・不正なプレミアム利用等を禁止します。"
            )
            consentBlock(
                title: "第5条（免責事項）",
                body: "本アプリは家計管理補助ツールであり、金融・税務アドバイスを提供しません。開発者は法令上許容される範囲でのみ責任を負います（故意・重過失を除く）。"
            )
            consentBlock(
                title: "第6条〜第8条",
                body: "知的財産権は開発者に帰属します。規約変更はアプリ内通知にて告知します。準拠法は日本法とし、消費者契約法その他の強行法規が優先されます。"
            )
        }
    }

    // ─────────────────────────────────────────────────────────
    // MARK: - プライバシーポリシーサマリー本文
    // ─────────────────────────────────────────────────────────
    private var privacyContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            consentSectionTitle("プライバシーポリシー（バージョン \(TermsVersion.current)）")

            // 個人情報非収集の強調
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                    .font(.subheadline)
                Text("本アプリは氏名・メールアドレス等の個人情報を一切収集しません。")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineSpacing(3)
            }
            .padding(14)
            .background(Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.3), lineWidth: 1)
            )

            consentBlock(
                title: "保存するデータ",
                body: "予算・支出・カテゴリ・設定情報のみをお客様のデバイス内に保存します。開発者を含む第三者がアクセスする手段はありません。外部サーバーへの送信は一切行いません。"
            )
            consentBlock(
                title: "ウィジェット",
                body: "ホーム画面ウィジェットへのデータ表示にApp Group（デバイス内共有）を使用します。外部送信はありません。"
            )
            consentBlock(
                title: "Apple・課金情報",
                body: "App Store経由の課金情報はApple Inc.が管理します。開発者は決済情報に一切アクセスしません。"
            )
            consentBlock(
                title: "広告（無料プランのみ）",
                body: "将来的に広告SDKを導入する場合は事前にポリシーを更新し、改めてご同意をいただきます。"
            )
            consentBlock(
                title: "データの削除",
                body: "アプリをアンインストールすることで全データが完全に削除されます。"
            )
        }
    }

    // ─────────────────────────────────────────────────────────
    // MARK: - コンポーネント
    // ─────────────────────────────────────────────────────────
    private func consentSectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(.gray)
            .padding(.bottom, 4)
    }

    private func consentBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))
            Text(body)
                .font(.caption)
                .foregroundColor(.gray.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Material.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    TermsConsentView(onAgreed: {})
}
