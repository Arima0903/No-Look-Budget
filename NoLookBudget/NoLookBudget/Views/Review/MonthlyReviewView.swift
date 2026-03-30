import SwiftUI

struct MonthlyReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MonthlyReviewViewModel()

    var body: some View {
        ZStack {
            // 背景: Deep Space Navy
            Theme.spaceNavy.ignoresSafeArea()

            // 予算結果に応じたグロー
            RadialGradient(
                gradient: Gradient(colors: [
                    viewModel.isOverBudget
                        ? Color.red.opacity(0.12)
                        : Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.1),
                    Color.clear
                ]),
                center: .top,
                startRadius: 80,
                endRadius: 500
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // ─── ヘッダー ───────────────────────────────
                    ZStack {
                        Text("\(viewModel.reviewMonthString) の振り返り")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // ─── ヒーローエリア ─────────────────────────
                    VStack(spacing: 16) {
                        if viewModel.isOverBudget {
                            // 失敗: 警告アイコン
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 110, height: 110)
                                    .pulseAnimation()

                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 56))
                                    .foregroundColor(.red)
                                    .shadow(color: .red.opacity(0.5), radius: 12, x: 0, y: 0)
                            }

                            Text("MISSION FAILED")
                                .font(.system(.title2, design: .rounded).bold())
                                .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                                .shadow(color: Color.red.opacity(0.4), radius: 8, x: 0, y: 0)

                            Text("\(viewModel.reviewMonthString) は予算をオーバーしました")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))

                        } else {
                            // 成功: 宇宙飛行士マスコット
                            ZStack {
                                // 後ろの緑グロー
                                Circle()
                                    .fill(Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.15))
                                    .frame(width: 160, height: 160)
                                    .pulseAnimation()

                                Image("astronaut_mascot")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 130, height: 130)
                                    .blendMode(.screen)
                            }

                            Text("MISSION CLEARED!")
                                .font(.system(.title, design: .rounded).bold())
                                .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                                .shadow(color: Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.5), radius: 10, x: 0, y: 0)

                            Text("見事、予算内に収めました！")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    // ─── 今月の結果カード ────────────────────────
                    VStack(spacing: 14) {
                        HStack {
                            Text("設定予算（変動費）")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("¥\(formatCurrency(viewModel.targetBudget))")
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundColor(.white)
                        }
                        HStack {
                            Text("実際の支出")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("¥\(formatCurrency(viewModel.actualSpent))")
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundColor(.white)
                        }

                        Divider().background(Color.white.opacity(0.15))

                        HStack {
                            Text(viewModel.isOverBudget ? "超過額" : "浮いた金額")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                            Spacer()
                            Text(viewModel.isOverBudget
                                 ? "-¥\(formatCurrency(viewModel.overAmount))"
                                 : "+¥\(formatCurrency(viewModel.surplusAmount))")
                                .font(.system(.title2, design: .rounded).bold())
                                .foregroundColor(viewModel.isOverBudget
                                    ? Color(red: 1.0, green: 0.4, blue: 0.4)
                                    : Color(red: 0.4, green: 0.9, blue: 0.6))
                                .shadow(color: viewModel.isOverBudget
                                    ? Color.red.opacity(0.4)
                                    : Color.green.opacity(0.4),
                                        radius: 5, x: 0, y: 0)
                        }
                    }
                    .padding(22)
                    .background(Material.ultraThinMaterial)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                    .padding(.horizontal, 20)

                    // ─── 累計節約達成額カード ─────────────────────
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("アプリ使用開始からの累計節約額")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            Spacer()
                        }

                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("¥")
                                .font(.title3.bold())
                                .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                            Text("\(formatCurrency(Double(viewModel.cumulativeSavings)))")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                                .shadow(color: Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.4), radius: 8, x: 0, y: 0)
                            Spacer()
                        }

                        Text("浮いたお金は手元に残っています。使い道はあなた次第です🚀")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(22)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(Material.ultraThinMaterial)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                    .padding(.horizontal, 20)

                    // ─── カテゴリ別 内訳 ────────────────────────
                    if !viewModel.categoryBreakdowns.isEmpty {
                        VStack(spacing: 14) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))
                                Text("カテゴリ別 内訳")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                                Spacer()
                            }

                            ForEach(viewModel.categoryBreakdowns) { cat in
                                VStack(spacing: 8) {
                                    HStack {
                                        Image(systemName: cat.iconName)
                                            .font(.caption)
                                            .foregroundColor(cat.isOverBudget
                                                ? Theme.coralRed
                                                : Theme.spaceGreen)
                                            .frame(width: 20)
                                        Text(cat.name)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)

                                        Spacer()

                                        Text("¥\(formatCurrency(cat.spent))")
                                            .font(.system(.subheadline, design: .rounded).bold())
                                            .foregroundColor(cat.isOverBudget
                                                ? Color(red: 1.0, green: 0.4, blue: 0.4)
                                                : .white)
                                        Text("/ ¥\(formatCurrency(cat.budget))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    // 消費率バー
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.white.opacity(0.08))

                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(
                                                    cat.usageRate > 1.0
                                                        ? LinearGradient(colors: [Theme.warmOrange, Theme.coralRed],
                                                                         startPoint: .leading, endPoint: .trailing)
                                                        : cat.usageRate > 0.8
                                                            ? LinearGradient(colors: [Theme.warmOrange, Theme.warmOrange],
                                                                             startPoint: .leading, endPoint: .trailing)
                                                            : LinearGradient(colors: [Theme.spaceGreenDark, Theme.spaceGreen],
                                                                             startPoint: .leading, endPoint: .trailing)
                                                )
                                                .frame(width: geo.size.width * min(cat.usageRate, 1.0))
                                        }
                                    }
                                    .frame(height: 6)

                                    // 残額 or 超過額
                                    HStack {
                                        Spacer()
                                        if cat.isOverBudget {
                                            Text("超過 ¥\(formatCurrency(abs(cat.remaining)))")
                                                .font(.caption2)
                                                .foregroundColor(Theme.coralRed)
                                        } else {
                                            Text("残り ¥\(formatCurrency(cat.remaining))")
                                                .font(.caption2)
                                                .foregroundColor(Theme.spaceGreen.opacity(0.8))
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(22)
                        .background(Material.ultraThinMaterial)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                        .padding(.horizontal, 20)
                    }

                    // ─── 超過カテゴリ (失敗時のみ) ──────────────
                    if viewModel.isOverBudget && !viewModel.overCategories.isEmpty {
                        VStack(spacing: 14) {
                            Text("原因となったカテゴリ")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)

                            let chartSize: CGFloat = viewModel.overCategories.count == 1 ? 100
                                : viewModel.overCategories.count == 2 ? 80 : 70

                            HStack(spacing: 20) {
                                ForEach(viewModel.overCategories, id: \.name) { cat in
                                    AnimatedOverCategoryRing(name: cat.name, amount: cat.amount, size: chartSize)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // ─── 失敗時: 借金説明 ────────────────────────
                    if viewModel.isOverBudget {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("回収プランが必要です")
                                    .font(.headline.bold())
                                    .foregroundColor(.red)
                            }
                            Text("超過した金額は「借金」となります。カテゴリ詳細画面から回収プランを設定してください。来月の予算から差し引かれます。")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                        }
                        .padding(20)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    }

                    // ─── バナー広告（無料プランのみ）────────────
                    BannerAdView()
                        .padding(.horizontal, 20)

                    // ─── 完了ボタン ──────────────────────────────
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("完了")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(viewModel.isOverBudget ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            viewModel.isOverBudget
                                ? LinearGradient(colors: [.red.opacity(0.7), .orange.opacity(0.7)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(
                                    colors: [Color(red: 0.4, green: 0.9, blue: 0.6), Color(red: 0.2, green: 0.8, blue: 0.5)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(16)
                        .shadow(color: viewModel.isOverBudget
                            ? Color.red.opacity(0.3)
                            : Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.4),
                                radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.fetchData()
        }
    }
}

// サブビュー: 超過カテゴリのアニメーション付きリング
struct AnimatedOverCategoryRing: View {
    let name: String
    let amount: Double
    let size: CGFloat
    @State private var animatedTrim: Double = 0

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: size * 0.1)

                Circle()
                    .trim(from: 0, to: animatedTrim)
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [.orange, .red]),
                                        center: .center,
                                        startAngle: .degrees(0), endAngle: .degrees(360)),
                        style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .red.opacity(0.4), radius: 5, x: 0, y: 0)

                VStack(spacing: 2) {
                    Text(name)
                        .font(.system(size: size * 0.15, weight: .bold))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("-¥\(formatCurrency(Int(amount)))")
                        .font(.system(size: size * 0.18, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.2)) {
                animatedTrim = 1.0
            }
        }
    }
}

#Preview("節約成功") {
    MonthlyReviewView()
}

#Preview("予算オーバー") {
    MonthlyReviewView()
}
