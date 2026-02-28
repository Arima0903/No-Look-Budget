import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    
    // アニメーション用
    @State private var animateFeatures = false
    
    var body: some View {
        ZStack {
            // 背景のプレミアム感
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.15, green: 0.1, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.06)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    
                    // ヘッダーアイコン
                    VStack(spacing: 15) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                            )
                            .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 10)
                        
                        Text("No-Look-Budget\nPremium")
                            .font(.title.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // 機能リスト
                    VStack(alignment: .leading, spacing: 25) {
                        featureRow(icon: "calendar.badge.clock", title: "借金の長期分割ペナルティ", description: "予算オーバー分を3ヶ月以上の長期で分割し、来月の首を絞めすぎないように調整できます。")
                        
                        featureRow(icon: "chart.pie.fill", title: "高度な振り返り分析", description: "毎月の推移グラフや、無駄な支出の傾向をAIが分析し、次の予算決めをサポートします。")
                        
                        featureRow(icon: "paintpalette.fill", title: "カスタムテーマカラー", description: "ウィジェットの色味やアプリ全体のテーマカラーを自分好みに変更できます。")
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    .opacity(animateFeatures ? 1 : 0)
                    .offset(y: animateFeatures ? 0 : 20)
                    
                    Spacer(minLength: 40)
                    
                    // プラン・購入ボタン
                    VStack(spacing: 15) {
                        Button(action: {
                            // 課金処理
                        }) {
                            VStack(spacing: 5) {
                                Text("Premiumを始める")
                                    .font(.headline.bold())
                                    .foregroundColor(.black)
                                Text("¥300 / 1ヶ月")
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(15)
                        }
                        .padding(.horizontal, 30)
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("今はしない")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            
            // 閉じるボタン
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateFeatures = true
            }
        }
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.yellow)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    PaywallView()
}
