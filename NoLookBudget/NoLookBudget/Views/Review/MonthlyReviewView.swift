import SwiftUI

struct MonthlyReviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    // サンプルデータ
    let targetBudget: Double = 150000
    let actualSpent: Double = 162000 // 12000円オーバー
    
    var isOverBudget: Bool {
        actualSpent > targetBudget
    }
    
    var overAmount: Double {
        actualSpent - targetBudget
    }
    
    // サンプルの超過カテゴリデータ
    let overCategories: [(name: String, amount: Double)] = [
        ("交際費", 8000),
        ("食費", 3000),
        ("変動費A", 1000)
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.11).ignoresSafeArea()
            
            VStack(spacing: 30) {
                // トップヘッダー領域（タイトルと閉じるボタン）
                ZStack {
                    Text("先月の振り返り")
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
                    Image(systemName: isOverBudget ? "exclamationmark.triangle.fill" : "star.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(isOverBudget ? .red : .yellow)
                    
                    Text(isOverBudget ? "予算をオーバーしました" : "素晴らしい！黒字達成です")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                
                // 結果の数字
                VStack(spacing: 10) {
                    HStack {
                        Text("設定予算(変動費)")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("¥\(Int(targetBudget))")
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text("実際の支出")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("¥\(Int(actualSpent))")
                            .foregroundColor(.white)
                    }
                    Divider().background(Color.gray.opacity(0.3))
                    HStack {
                        Text("結果")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Text(isOverBudget ? "- ¥\(Int(overAmount))" : "+ ¥\(Int(targetBudget - actualSpent))")
                            .font(.title.bold())
                            .foregroundColor(isOverBudget ? .red : .green)
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(15)
                .padding(.horizontal, 20)
                
                // カテゴリ別の超過状況（小さい円グラフ）
                if isOverBudget {
                    VStack(spacing: 15) {
                        Text("原因となったカテゴリ")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        // 個数に応じてサイズを可変にする
                        let chartSize: CGFloat = overCategories.count == 1 ? 100 : (overCategories.count == 2 ? 80 : 65)
                        
                        HStack(spacing: 20) {
                            ForEach(overCategories, id: \.name) { cat in
                                VStack {
                                    ZStack {
                                        Circle()
                                            .stroke(Color(red: 0.9, green: 0.4, blue: 0.4).opacity(0.3), lineWidth: chartSize * 0.1)
                                        Circle()
                                            .trim(from: 0, to: 1)
                                            .stroke(Color(red: 0.9, green: 0.4, blue: 0.4), style: StrokeStyle(lineWidth: chartSize * 0.1, lineCap: .butt))
                                            .rotationEffect(.degrees(-90))
                                        VStack {
                                            Text(cat.name)
                                                .font(.system(size: chartSize * 0.15, weight: .bold))
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                            Text("-¥\(Int(cat.amount))")
                                                .font(.system(size: chartSize * 0.18, weight: .bold))
                                                .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                        }
                                    }
                                    .frame(width: chartSize, height: chartSize)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // 次のアクション分岐
                if isOverBudget {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("⚠️ 回収プラン設定が必要です")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("オーバーした金額は「借金」となります。今月のどの予算カテゴリから返済するか、回収プランを決めてください。")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    Button(action: {
                        // 回収プラン画面(DebtRecoveryView)等へ遷移
                    }) {
                        Text("回収プランを決める")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                } else {
                    Text("今月もこの調子で、無理なく予算内でやりくりしましょう。")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 30)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("今月の予算をそのまま開始")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.yellow)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    MonthlyReviewView()
}
