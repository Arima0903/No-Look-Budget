import SwiftUI

struct MonthlyReviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = MonthlyReviewViewModel()
    @AppStorage("isPremiumEnabled") private var isPremiumEnabled = false
    
    var body: some View {
        ZStack {
            // 背景 (ダーク＆リッチ)
            Color(red: 0.08, green: 0.08, blue: 0.09).ignoresSafeArea()
            
            // 予算オーバー時は背景に微かな赤グローを敷く
            if viewModel.isOverBudget {
                RadialGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.1), Color.clear]),
                    center: .top,
                    startRadius: 100,
                    endRadius: 600
                )
                .ignoresSafeArea()
            } else {
                RadialGradient(
                    gradient: Gradient(colors: [Color.yellow.opacity(0.1), Color.clear]),
                    center: .top,
                    startRadius: 100,
                    endRadius: 600
                )
                .ignoresSafeArea()
            }
            
            VStack(spacing: 30) {
                // トップヘッダー領域（タイトルと閉じるボタン）
                ZStack {
                    Text("\(viewModel.reviewMonthString) の振り返り")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // メッセージと結果アイコン
                VStack(spacing: 15) {
                    if viewModel.isOverBudget {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.red)
                            .pulseAnimation()
                            .shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 0)
                        
                        Text("\(viewModel.reviewMonthString) は予算をオーバーしました")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.2))
                                .frame(width: 120, height: 120)
                                .pulseAnimation()
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)
                                .shadow(color: .yellow.opacity(0.8), radius: 15, x: 0, y: 0)
                        }
                        
                        Text("MISSION CLEARED!")
                            .font(.system(.title, design: .rounded).bold())
                            .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                            .shadow(color: Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.5), radius: 10, x: 0, y: 0)
                        
                        Text("見事、予算内に収めました！")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 10)
                
                // 結果の数字 (Glassmorphism Card)
                VStack(spacing: 12) {
                    HStack {
                        Text("設定予算(変動費)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("¥\(Int(viewModel.targetBudget))")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text("実際の支出")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("¥\(Int(viewModel.actualSpent))")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundColor(.white)
                    }
                    Divider().background(Color.white.opacity(0.2))
                    HStack {
                        Text("結果")
                            .font(.headline)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        Spacer()
                        Text(viewModel.isOverBudget ? "- ¥\(Int(viewModel.overAmount))" : "+ ¥\(Int(viewModel.targetBudget - viewModel.actualSpent))")
                            .font(.system(.title, design: .rounded).bold())
                            .foregroundColor(viewModel.isOverBudget ? Color(red: 1.0, green: 0.4, blue: 0.4) : Color(red: 0.4, green: 0.9, blue: 0.6))
                            .shadow(color: viewModel.isOverBudget ? Color.red.opacity(0.4) : Color.green.opacity(0.4), radius: 5, x: 0, y: 0)
                    }
                }
                .padding(24)
                .background(Material.ultraThinMaterial)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 10)
                .padding(.horizontal, 20)
                
                // カテゴリ別の超過状況（小さい円グラフ）
                if viewModel.isOverBudget {
                    VStack(spacing: 15) {
                        Text("原因となったカテゴリ")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        
                        // 個数に応じてサイズを可変にする
                        let chartSize: CGFloat = viewModel.overCategories.count == 1 ? 100 : (viewModel.overCategories.count == 2 ? 80 : 70)
                        
                        HStack(spacing: 20) {
                            ForEach(viewModel.overCategories, id: \.name) { cat in
                                AnimatedOverCategoryRing(name: cat.name, amount: cat.amount, size: chartSize)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // 次のアクション分岐
                if viewModel.isOverBudget {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("⚠️ 回収プラン設定が必要です")
                            .font(.headline)
                            .fontWeight(.black)
                            .foregroundColor(.red)
                        Text("オーバーした金額は「借金」となります。先月のどの予算カテゴリから返済するか、回収プランを決めてください。")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    if isPremiumEnabled {
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            // 回収プラン画面(DebtRecoveryView)等のプレミアム機能へ遷移
                        }) {
                            Text("回収プランを決める")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .cornerRadius(16)
                                .shadow(color: .red.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 8) {
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                // Paywallを出すなどの処理に繋げる
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                    Text("回収プランを決める (Premium)")
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(16)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Text("無料版では翌月の予算から自動的に一括で差し引かれます")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                    }
                } else {
                    VStack(spacing: 15) {
                        Text("浮いたお金 ¥\(Int(viewModel.targetBudget - viewModel.actualSpent)) は自動的に\n「先取り貯金」または次回繰り越しに回ります。")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        viewModel.processToNextMonth()
                        dismiss()
                    }) {
                        HStack {
                            Text("報酬を受け取って次月へ")
                                .fontWeight(.bold)
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient(colors: [Color(red: 0.4, green: 0.9, blue: 0.6), Color(red: 0.2, green: 0.8, blue: 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(16)
                        .shadow(color: Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            viewModel.fetchData()
        }
    }
}

// サブビュー：超過カテゴリのアニメーション付きリング
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
                        AngularGradient(gradient: Gradient(colors: [.orange, .red]), center: .center),
                        style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .red.opacity(0.4), radius: 5, x: 0, y: 0)
                
                VStack {
                    Text(name)
                        .font(.system(size: size * 0.15, weight: .bold))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("-¥\(Int(amount))")
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

#Preview("Over Budget") {
    MonthlyReviewView()
}

#Preview("Under Budget") {
    MonthlyReviewView()
}
