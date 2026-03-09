import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    let categoryName: String
    @StateObject private var viewModel: CategoryDetailViewModel
    
    init(categoryName: String) {
        self.categoryName = categoryName
        _viewModel = StateObject(wrappedValue: CategoryDetailViewModel(categoryName: categoryName))
    }
    
    var body: some View {
        ZStack {
            Theme.spaceNavy.ignoresSafeArea()
            
            // 右下にマスコットを薄く表示
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("astronaut_mascot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .blendMode(.screen) // 追加: 黒背景を透過(合成)させる
                        .opacity(0.15)
                        .padding(.bottom, 20)
                        .padding(.trailing, 20)
                }
            }
            
            ScrollView {
                VStack(spacing: 30) {
                    
                    // ヘッダー部
                    VStack(spacing: 5) {
                        Text("今月の予算")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("¥\(viewModel.totalBudget)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    // 残高表示部
                    VStack(spacing: 15) {
                        Text("残り予算")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("¥\(viewModel.currentRemaining)")
                            .font(.system(size: 50, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                    }
                    
                    // --- 借金（過去の超過分）アラートエリア ---
                    if viewModel.debtAmount > 0 {
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                                Text("未回収の超過予算（借金）があります")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            Text("-¥\(viewModel.debtAmount)")
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4))
                            
                            Text("来月の予算から自動的に一括で差し引かれます。")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            // 借金回収設定へのリンク
                            NavigationLink(destination: DebtRecoveryView(categoryName: categoryName, debtAmount: viewModel.debtAmount)) {
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
                            if viewModel.transactions.isEmpty {
                                Text("履歴がありません")
                                    .padding()
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(viewModel.transactions) { tx in
                                    HistoryRowView(
                                        date: tx.date,
                                        memo: tx.iouAmount > 0 ? "立替" : (tx.isIncome ? "臨時収入" : "支出"),
                                        amount: tx.totalAmount
                                    )
                                }
                            }
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
        .onAppear {
            viewModel.fetchData()
        }
        .preferredColorScheme(.dark)
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
