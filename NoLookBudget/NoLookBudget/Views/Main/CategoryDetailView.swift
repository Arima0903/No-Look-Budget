import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    let categoryName: String
    
    // --- 仮のモックデータ ---
    let totalBudget = 50000
    let currentRemaining = 12000
    let debtAmount = 8000 // 過去の未回収借金（マイナス分）
    
    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.13, blue: 0.14).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    
                    // ヘッダー部
                    VStack(spacing: 5) {
                        Text("今月の予算")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("¥\(totalBudget)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    // 残高表示部
                    VStack(spacing: 15) {
                        Text("REMAINING")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("¥\(currentRemaining)")
                            .font(.system(size: 50, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                    }
                    
                    // --- 借金（過去の超過分）アラートエリア ---
                    if debtAmount > 0 {
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                                Text("未回収の超過予算（借金）があります")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            Text("-¥\(debtAmount)")
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4))
                            
                            Text("来月の予算から自動的に一括で差し引かれます。")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            // 借金回収設定へのリンク
                            NavigationLink(destination: DebtRecoveryView(categoryName: categoryName, debtAmount: debtAmount)) {
                                Text("回収プランを決める")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(Color.yellow)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(20)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // 履歴リスト（モック）
                    VStack(alignment: .leading, spacing: 15) {
                        Text("今月の履歴")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 1) {
                            HistoryRowView(date: "今日", memo: "ランチ", amount: 1200)
                            HistoryRowView(date: "昨日", memo: "カフェ", amount: 600)
                            HistoryRowView(date: "2/25", memo: "スーパー", amount: 4500)
                        }
                        .background(Color(white: 0.2))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 50)
                }
            }
        }
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HistoryRowView: View {
    let date: String
    let memo: String
    let amount: Int
    
    var body: some View {
        HStack {
            Text(date)
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .leading)
            
            Text(memo)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("-¥\(amount)")
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color(red: 0.18, green: 0.18, blue: 0.19))
    }
}

#Preview {
    NavigationStack {
        CategoryDetailView(categoryName: "食費")
    }
}
