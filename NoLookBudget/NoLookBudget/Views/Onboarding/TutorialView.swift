import SwiftUI

/// 初回起動時のチュートリアル画面
/// 宇宙飛行士マスコットが使い方を案内する
struct TutorialView: View {
    /// チュートリアル完了時に呼ばれるコールバック
    var onCompleted: () -> Void

    @State private var currentStep = 0
    @State private var mascotOffset: CGFloat = 0
    @State private var mascotRotation: Double = 0
    @State private var showBubble = false
    @State private var showWidgetGuideAlert = false

    /// チュートリアルの全ステップ
    private let steps: [TutorialStep] = [
        TutorialStep(
            title: "ようこそ、パイロット！",
            subtitle: "Orbit Budget の使い方を\n3ステップでご案内します",
            icon: "hand.wave.fill",
            iconColor: Color(red: 251/255, green: 146/255, blue: 60/255),
            mascotMessage: "僕がナビゲートするよ！\n一緒に準備を始めよう 🚀",
            details: [
                TutorialDetail(
                    icon: "gauge.open.with.lines.needle.33percent",
                    text: "残り予算をゲージで直感管理"
                ),
                TutorialDetail(
                    icon: "bolt.fill",
                    text: "ウィジェットで開かずに確認"
                ),
                TutorialDetail(
                    icon: "hand.tap.fill",
                    text: "3秒で支出をサッと記録"
                ),
            ]
        ),
        TutorialStep(
            title: "Step 1: 予算を設定しよう",
            subtitle: "まずは今月使えるお金を決めます",
            icon: "yensign.circle.fill",
            iconColor: Color(red: 74/255, green: 222/255, blue: 128/255),
            mascotMessage: "収入から固定費と貯金を引くだけ！\n残りが今月の「残り予算」だよ",
            details: [
                TutorialDetail(
                    icon: "1.circle.fill",
                    text: "サイドメニュー → 予算設定 を開く"
                ),
                TutorialDetail(
                    icon: "2.circle.fill",
                    text: "月の収入を入力する"
                ),
                TutorialDetail(
                    icon: "3.circle.fill",
                    text: "固定費（家賃・通信費など）を入力"
                ),
                TutorialDetail(
                    icon: "4.circle.fill",
                    text: "先取り貯金額を設定すれば完了！"
                ),
            ],
            tipText: "💡 固定費を引いた残りが自動で計算されます"
        ),
        TutorialStep(
            title: "Step 2: ウィジェットを配置",
            subtitle: "ホーム画面で残高を一目チェック",
            icon: "apps.iphone",
            iconColor: Color(red: 96/255, green: 165/255, blue: 250/255),
            mascotMessage: "これが一番大事！\nアプリを開かなくても残高がわかるよ",
            details: [
                TutorialDetail(
                    icon: "1.circle.fill",
                    text: "ホーム画面を長押し → 左上の＋をタップ"
                ),
                TutorialDetail(
                    icon: "2.circle.fill",
                    text: "「Orbit Budget」を検索"
                ),
                TutorialDetail(
                    icon: "3.circle.fill",
                    text: "好きなサイズのウィジェットを追加"
                ),
                TutorialDetail(
                    icon: "4.circle.fill",
                    text: "ホーム画面に配置して完了！"
                ),
            ],
            tipText: "💡 ウィジェットから直接支出入力もできます"
        ),
        TutorialStep(
            title: "Step 3: 支出をサッと記録",
            subtitle: "たった3秒で入力完了！",
            icon: "bolt.circle.fill",
            iconColor: Color(red: 251/255, green: 146/255, blue: 60/255),
            mascotMessage: "使ったらすぐ記録！\nこれが浪費を防ぐコツだよ",
            details: [
                TutorialDetail(
                    icon: "1.circle.fill",
                    text: "画面下の ＋ ボタンをタップ"
                ),
                TutorialDetail(
                    icon: "2.circle.fill",
                    text: "テンキーで金額を入力"
                ),
                TutorialDetail(
                    icon: "3.circle.fill",
                    text: "カテゴリを選んで「確定」！"
                ),
            ],
            tipText: "💡 飲み会の立替は「立替」をONにするだけ！"
        ),
    ]

    var body: some View {
        ZStack {
            // 背景
            Theme.spaceNavy.ignoresSafeArea()

            // 上部グロー
            RadialGradient(
                gradient: Gradient(colors: [
                    steps[currentStep].iconColor.opacity(0.1),
                    Color.clear,
                ]),
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentStep)

            VStack(spacing: 0) {
                // ─── マスコット＆吹き出し ──────────────
                mascotSection
                    .padding(.top, 40)
                    .padding(.bottom, 16)

                // ─── ステップコンテンツ ────────────────
                ScrollView(showsIndicators: false) {
                    stepContent(steps[currentStep])
                        .padding(.horizontal, 20)
                        .id(currentStep)
                }
                .frame(maxHeight: .infinity)

                // ─── ページインジケーター ──────────────
                pageIndicator
                    .padding(.top, 12)

                // ─── ナビゲーションボタン ──────────────
                navigationButtons
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .alert("ウィジェットの追加方法", isPresented: $showWidgetGuideAlert) {
            Button("OK、追加してくる！") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep += 1
                }
            }
        } message: {
            Text("1. ホーム画面に戻って長押し\n2. 左上の＋をタップ\n3. 「Orbit Budget」で検索\n4. 好きなサイズを選んで追加！")
        }
        .onAppear {
            startMascotAnimation()
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showBubble = true
            }
        }
    }

    // MARK: - マスコットセクション
    private var mascotSection: some View {
        HStack(alignment: .top, spacing: 12) {
            // マスコット画像
            Image("astronaut_mascot")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .blendMode(.screen)
                .offset(y: mascotOffset)
                .rotationEffect(.degrees(mascotRotation))

            // 吹き出し
            if showBubble {
                VStack(alignment: .leading, spacing: 4) {
                    Text(steps[currentStep].mascotMessage)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .lineSpacing(4)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Material.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    steps[currentStep].iconColor.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.4), value: currentStep)
    }

    // MARK: - ステップコンテンツ
    private func stepContent(_ step: TutorialStep) -> some View {
        VStack(spacing: 16) {
            // アイコン＆タイトル
            VStack(spacing: 10) {
                Image(systemName: step.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(step.iconColor)

                Text(step.title)
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text(step.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.bottom, 8)

            // 詳細リスト
            VStack(spacing: 10) {
                ForEach(step.details) { detail in
                    HStack(spacing: 14) {
                        Image(systemName: detail.icon)
                            .font(.title3)
                            .foregroundStyle(step.iconColor)
                            .frame(width: 28)

                        Text(detail.text)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(3)

                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Material.ultraThinMaterial)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                }
            }

            // ヒント表示
            if let tipText = step.tipText {
                HStack(spacing: 8) {
                    Text(tipText)
                        .font(.caption)
                        .foregroundColor(step.iconColor)
                        .lineSpacing(3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(step.iconColor.opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(step.iconColor.opacity(0.2), lineWidth: 1)
                )
                .padding(.top, 4)
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - ページインジケーター
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentStep
                          ? steps[currentStep].iconColor
                          : Color.white.opacity(0.2))
                    .frame(
                        width: index == currentStep ? 24 : 8,
                        height: 8
                    )
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - ナビゲーションボタン
    private var navigationButtons: some View {
        Group {
            if currentStep == 2 {
                widgetPromotionSection
            } else {
                standardNavigationButtons
            }
        }
    }

    // MARK: - ウィジェット配置プロモーション（Duolingo風半強制UI）
    @ViewBuilder
    private var widgetPromotionSection: some View {
        VStack(spacing: 16) {
            // メインCTA: ウィジェット追加ボタン
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                showWidgetGuideAlert = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.app.fill")
                        .font(.title3)
                    Text("ウィジェットを追加する")
                        .fontWeight(.bold)
                        .font(.body)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [
                            steps[currentStep].iconColor,
                            steps[currentStep].iconColor.opacity(0.8),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(
                    color: steps[currentStep].iconColor.opacity(0.5),
                    radius: 15, x: 0, y: 8
                )
            }
            .buttonStyle(ScaleButtonStyle())

            // 「戻る」と「あとで」を横並びに配置
            HStack {
                // 戻るボタン
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("戻る")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.vertical, 8)
                }

                Spacer()

                // 「あとで」ボタン（意図的に目立たなくする）
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                }) {
                    Text("あとで")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - 通常のナビゲーションボタン（Step 0, 1, 3）
    private var standardNavigationButtons: some View {
        HStack(spacing: 12) {
            // スキップ / 戻るボタン
            if currentStep > 0 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("戻る")
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(14)
                }
            } else {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onCompleted()
                }) {
                    Text("スキップ")
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                }
                .accessibilityIdentifier("skipButton")
            }

            Spacer()

            // 次へ / はじめるボタン
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                if currentStep < steps.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                } else {
                    onCompleted()
                }
            }) {
                HStack(spacing: 8) {
                    Text(currentStep < steps.count - 1 ? "次へ" : "はじめる！")
                        .fontWeight(.bold)
                    if currentStep < steps.count - 1 {
                        Image(systemName: "chevron.right")
                    } else {
                        Image(systemName: "rocket.fill")
                    }
                }
                .foregroundColor(.black)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(
                    LinearGradient(
                        colors: [
                            steps[currentStep].iconColor,
                            steps[currentStep].iconColor.opacity(0.8),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
                .shadow(
                    color: steps[currentStep].iconColor.opacity(0.4),
                    radius: 10, x: 0, y: 5
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityIdentifier("nextButton")
        }
    }

    // MARK: - マスコットアニメーション
    private func startMascotAnimation() {
        // ふわふわ浮遊アニメーション
        withAnimation(
            .easeInOut(duration: 2.5)
            .repeatForever(autoreverses: true)
        ) {
            mascotOffset = -8
        }

        // 軽い傾きアニメーション
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            mascotRotation = 3
        }
    }
}

// MARK: - データモデル

/// チュートリアルの1ステップを表すデータ
struct TutorialStep {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let mascotMessage: String
    let details: [TutorialDetail]
    var tipText: String? = nil
}

/// チュートリアルの詳細項目
struct TutorialDetail: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}

#Preview {
    TutorialView(onCompleted: {})
}
