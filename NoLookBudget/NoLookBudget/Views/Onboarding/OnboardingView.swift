import SwiftUI

struct OnboardingView: View {
    @State private var step = 1
    
    // 入力データ
    @State private var monthlyIncome: String = ""
    @State private var fixedCosts: String = ""
    @State private var savingsTarget: String = ""
    
    var dynamicBudget: Double {
        let income = Double(monthlyIncome) ?? 0
        let fixed = Double(fixedCosts) ?? 0
        let savings = Double(savingsTarget) ?? 0
        return max(0, income - fixed - savings)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.11).ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // ヘッダー部
                    VStack(spacing: 8) {
                        Text("初期設定")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text("Step \(step) / 4")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // コンテンツ部
                    TabView(selection: $step) {
                        // Step 1: 収入設定
                        setupStepView(
                            title: "今月の収入",
                            description: "まずは手取りの収入を入力してください。",
                            inputText: $monthlyIncome,
                            icon: "yensign.circle.fill",
                            color: .green
                        ).tag(1)
                        
                        // Step 2: 固定費の天引き
                        setupStepView(
                            title: "固定費（家賃・通信費など）",
                            description: "必ず出ていくお金を先に入力しましょう。これは日々の管理からは隠されます。",
                            inputText: $fixedCosts,
                            icon: "house.fill",
                            color: .blue
                        ).tag(2)
                        
                        // Step 3: 先取り貯金
                        setupStepView(
                            title: "先取り貯金",
                            description: "余ったお金を貯金するのは困難です。最初に確実によける金額を決めましょう。",
                            inputText: $savingsTarget,
                            icon: "piggybank.fill",
                            color: .orange
                        ).tag(3)
                        
                        // Step 4: 変動費（アプリ管理予算）の決定
                        finalStepView()
                            .tag(4)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: step)
                    
                    // ナビゲーションボタン
                    HStack {
                        if step > 1 {
                            Button(action: {
                                withAnimation { step -= 1 }
                            }) {
                                Text("戻る")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 30)
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(12)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if step < 4 {
                                withAnimation { step += 1 }
                            } else {
                                // アプリ本編へ（ダッシュボード等へ遷移）
                                print("Setup Complete")
                            }
                        }) {
                            Text(step < 4 ? "次へ" : "ウィジェット設定へ進む")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.vertical, 16)
                                .padding(.horizontal, step < 4 ? 40 : 20)
                                .background(Color.yellow) // 全体テーマカラー
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    // 各ステップの共通入力ビュー
    private func setupStepView(title: String, description: String, inputText: Binding<String>, icon: String, color: Color) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(color)
                .padding(.bottom, 10)
            
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            TextField("¥ 0", text: inputText)
                .keyboardType(.numberPad)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.vertical, 15)
                .background(Color.white.opacity(0.05))
                .cornerRadius(15)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    // 最終計算結果ビュー
    private func finalStepView() -> some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("予算枠が決定しました！")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 15) {
                HStack {
                    Text("収入")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("¥\(monthlyIncome.isEmpty ? "0" : monthlyIncome)")
                        .foregroundColor(.white)
                }
                HStack {
                    Text("- 固定費")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("¥\(fixedCosts.isEmpty ? "0" : fixedCosts)")
                        .foregroundColor(.red)
                }
                HStack {
                    Text("- 先取り貯金")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("¥\(savingsTarget.isEmpty ? "0" : savingsTarget)")
                        .foregroundColor(.orange)
                }
                
                Divider().background(Color.white.opacity(0.3))
                
                HStack {
                    Text("今月の生活費(変動費)")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Text("¥\(Int(dynamicBudget))")
                        .font(.title2.bold())
                        .foregroundColor(.yellow)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(15)
            .padding(.horizontal, 30)
            
            Text("この生活費の中でやりくりするだけです。\nウィジェットを設定して管理を始めましょう！")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding(.top, 40)
    }
}

#Preview {
    OnboardingView()
}
