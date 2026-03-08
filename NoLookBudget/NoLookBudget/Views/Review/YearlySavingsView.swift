import SwiftUI

struct YearlySavingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // サンプルデータ
    let targetYear = 2026
    let totalSavings: Int = 1250000 // 累計貯蓄・浮いたお金の総額
    
    // 過去の月ごとの実績モック
    let monthlyRecords: [(month: String, amount: Int, isSurplus: Bool)] = [
        ("4月", 35000, true),
        ("5月", -12000, false),
        ("6月", 45000, true),
        ("7月", 8000, true),
        ("8月", -25000, false),
        ("9月", 60000, true),
        ("10月", 22000, true),
        ("11月", 15000, true),
        ("12月", -5000, false),
        ("1月", 40000, true),
        ("2月", 30000, true),
        ("3月", 55000, true)
    ]
    
    var body: some View {
        ZStack {
            // 背景 (ダーク＆リッチ)
            Color(red: 0.08, green: 0.08, blue: 0.09).ignoresSafeArea()
            
            // 全体背景のゴールドグロー
            RadialGradient(
                gradient: Gradient(colors: [Color.yellow.opacity(0.15), Color.clear]),
                center: .top,
                startRadius: 100,
                endRadius: 800
            )
            .ignoresSafeArea()
            .pulseAnimation()
            
            VStack(spacing: 0) {
                // トップヘッダー領域
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("\(targetYear)年度の軌跡")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                    // レイアウトバランス用の見えない要素
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // メインアピール
                        VStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(Color.yellow.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                    .pulseAnimation()
                                
                                Image(systemName: "medal.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.yellow)
                                    .shadow(color: .yellow.opacity(0.8), radius: 15, x: 0, y: 0)
                            }
                            
                            Text("1年間の総貯蓄額")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            Text("+ ¥\(totalSavings)")
                                .font(.system(size: 50, weight: .black, design: .rounded))
                                .foregroundColor(.yellow)
                                .shadow(color: .yellow.opacity(0.5), radius: 10, x: 0, y: 0)
                            
                            Text("日々の「No-Look」の積み重ねが\nこれだけの結果を生みました！")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                                .padding(.top, 10)
                        }
                        .padding(.top, 10)
                        
                        // 月別推移グラフ風リスト
                        VStack(alignment: .leading, spacing: 20) {
                            Text("月別ハイライト")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                ForEach(monthlyRecords, id: \.month) { record in
                                    HStack(spacing: 15) {
                                        Text(record.month)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.gray)
                                            .frame(width: 40, alignment: .leading)
                                        
                                        // 簡易バーグラフ
                                        GeometryReader { geo in
                                            let maxAbsViewWidth = geo.size.width * 0.9
                                            let maxAmount: Double = 60000 // サンプルの最大値
                                            let ratio = min(abs(Double(record.amount)) / maxAmount, 1.0)
                                            let barWidth = maxAbsViewWidth * ratio
                                            
                                            HStack {
                                                if record.isSurplus {
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(LinearGradient(colors: [Color(red: 0.4, green: 0.9, blue: 0.6), Color(red: 0.2, green: 0.8, blue: 0.5)], startPoint: .leading, endPoint: .trailing))
                                                        .frame(width: max(barWidth, 5), height: 12)
                                                        .shadow(color: Color.green.opacity(0.3), radius: 3)
                                                    Spacer()
                                                } else {
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                                                        .frame(width: max(barWidth, 5), height: 12)
                                                        .shadow(color: Color.red.opacity(0.3), radius: 3)
                                                    Spacer()
                                                }
                                            }
                                        }
                                        .frame(height: 12)
                                        
                                        Spacer()
                                        
                                        Text(record.isSurplus ? "+¥\(record.amount)" : "-¥\(abs(record.amount))")
                                            .font(.system(.subheadline, design: .rounded).bold())
                                            .foregroundColor(record.isSurplus ? Color(red: 0.4, green: 0.9, blue: 0.6) : Color(red: 1.0, green: 0.4, blue: 0.4))
                                            .frame(width: 75, alignment: .trailing)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 16)
                                    .background(Color.white.opacity(0.03))
                                    .cornerRadius(12)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
    }
}

#Preview {
    YearlySavingsView()
}
