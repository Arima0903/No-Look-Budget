import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPremiumEnabled") private var isPremiumEnabled = false
    @ObservedObject private var storeKit = StoreKitManager.shared
    @State private var animateFeatures = false
    @State private var isPurchasing = false

    var body: some View {
        ZStack {
            // 背景: Deep Space Navy
            Theme.spaceNavy.ignoresSafeArea()

            // 上部ゴールドグロー
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.12),
                    Color.clear
                ]),
                center: .top,
                startRadius: 50,
                endRadius: 450
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // ─── ヒーロー ────────────────────────────────
                    VStack(spacing: 16) {
                        // 宇宙飛行士 + ゴールドグロー
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.25), .clear],
                                        center: .center, startRadius: 30, endRadius: 100
                                    )
                                )
                                .frame(width: 180, height: 180)
                                .pulseAnimation()

                            Image("astronaut_mascot")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .blendMode(.screen)

                            // 王冠バッジ
                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "crown.fill")
                                        .font(.title3)
                                        .foregroundStyle(
                                            LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                                        )
                                        .shadow(color: .orange.opacity(0.6), radius: 6, x: 0, y: 0)
                                        .offset(x: -8, y: 0)
                                }
                                Spacer()
                            }
                            .frame(width: 140, height: 140)
                        }
                        .padding(.top, 60)

                        VStack(spacing: 6) {
                            Text("COMMANDER PLAN")
                                .font(.system(.title2, design: .rounded).bold())
                                .foregroundStyle(
                                    LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                                )
                                .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 0)

                            Text("Orbit Budget を\n最大限に活用する")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }

                    // ─── 機能一覧 ─────────────────────────────────
                    VStack(spacing: 14) {
                        premiumFeatureCard(
                            icon: "calendar.badge.clock",
                            iconColor: Color(red: 1.0, green: 0.6, blue: 0.2),
                            title: "借金の長期分割ペナルティ",
                            description: "予算オーバー分を最大3ヶ月で分割回収。来月の家計を締め付けすぎません。"
                        )
                        premiumFeatureCard(
                            icon: "chart.line.uptrend.xyaxis",
                            iconColor: Color(red: 0.4, green: 0.9, blue: 0.6),
                            title: "高度な振り返り分析",
                            description: "月次推移グラフや支出傾向の深掘り分析で、次の予算設定をよりスマートに。"
                        )
                        premiumFeatureCard(
                            icon: "eye.slash.fill",
                            iconColor: Color(red: 0.3, green: 0.8, blue: 1.0),
                            title: "ウィジェット プライバシーモード",
                            description: "ウィジェットの金額表示をパーセントに切替可能。他人に見られても金額がバレません。"
                        )
                        premiumFeatureCard(
                            icon: "folder.badge.plus",
                            iconColor: Color(red: 0.9, green: 0.7, blue: 0.2),
                            title: "カスタムカテゴリ追加",
                            description: "デフォルト6カテゴリに加えて、自分だけのカテゴリを3つまで追加。ウィジェットにも最大9カテゴリ表示。"
                        )
                        premiumFeatureCard(
                            icon: "paintpalette.fill",
                            iconColor: Color(red: 0.6, green: 0.4, blue: 1.0),
                            title: "カスタムテーマ",
                            description: "ウィジェット・アプリカラーを自分好みに変更。あなただけの宇宙を作ろう。"
                        )
                        premiumFeatureCard(
                            icon: "bell.badge.fill",
                            iconColor: Color(red: 1.0, green: 0.4, blue: 0.4),
                            title: "スマート通知",
                            description: "予算消化ペースに応じたアラートで、月末の予算オーバーを未然に防ぎます。"
                        )
                    }
                    .padding(.horizontal, 20)
                    .opacity(animateFeatures ? 1 : 0)
                    .offset(y: animateFeatures ? 0 : 20)

                    // ─── エラー表示 ───────────────────────────────
                    if let error = storeKit.purchaseError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }

                    // ─── 購入ボタン ───────────────────────────────
                    VStack(spacing: 12) {
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            isPurchasing = true
                            Task {
                                await storeKit.purchase()
                                isPurchasing = false
                                // 購入成功時は画面を閉じる
                                if storeKit.isPremium {
                                    dismiss()
                                }
                            }
                        }) {
                            VStack(spacing: 4) {
                                if isPurchasing {
                                    ProgressView()
                                        .tint(.black)
                                        .padding(.vertical, 4)
                                } else {
                                    // App Storeから取得した価格を表示（取得前はデフォルト表示）
                                    let priceText = storeKit.products.first?.displayPrice ?? "¥450"
                                    Text("COMMANDER PLANを始める")
                                        .font(.headline.bold())
                                        .foregroundColor(.black)
                                    Text("\(priceText) / 月　　初月無料")
                                        .font(.caption)
                                        .foregroundColor(.black.opacity(0.6))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.85, blue: 0.2), Color(red: 1.0, green: 0.6, blue: 0.1)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .orange.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(isPurchasing)

                        Button(action: {
                            Task {
                                await storeKit.restorePurchases()
                                if storeKit.isPremium {
                                    dismiss()
                                }
                            }
                        }) {
                            Text("購入を復元する")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Button(action: { dismiss() }) {
                            Text("今はしない")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }

            // 閉じるボタン（ScrollViewより後に配置して最前面に表示）
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.8))
                            .padding(20)
                    }
                }
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
                animateFeatures = true
            }
        }
    }

    private func premiumFeatureCard(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }

            Spacer()
        }
        .padding(16)
        .background(Material.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    PaywallView()
}
