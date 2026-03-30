import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    let categoryName: String
    @StateObject private var viewModel: CategoryDetailViewModel
    @State private var editingTransaction: TransactionDisplayItem? = nil

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

                    // バナー広告（無料プランのみ）
                    BannerAdView()
                        .padding(.top, 10)

                    // ヘッダー部
                    VStack(spacing: 5) {
                        Text("今月の予算")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("¥\(formatCurrency(viewModel.totalBudget))")
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
                        
                        Text("¥\(formatCurrency(viewModel.currentRemaining))")
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
                            
                            Text("-¥\(formatCurrency(viewModel.debtAmount))")
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
                    
                    // 履歴リスト
                    VStack(alignment: .leading, spacing: 15) {
                        Text("今月の履歴")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)

                        if viewModel.transactions.isEmpty {
                            Text("履歴がありません")
                                .padding()
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                        } else {
                            List {
                                ForEach(viewModel.transactions) { tx in
                                    Button(action: {
                                        if !tx.isFixedCost {
                                            editingTransaction = tx
                                        }
                                    }) {
                                        HStack {
                                            Text(tx.date)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                                .frame(width: 50, alignment: .leading)

                                            Text(tx.iouAmount > 0 ? "立替" : (tx.isIncome ? "収入" : "支出"))
                                                .font(.body)
                                                .foregroundColor(.white)

                                            if tx.isFixedCost {
                                                Image(systemName: "lock.fill")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }

                                            Spacer()

                                            Text("-¥\(tx.totalAmount)")
                                                .font(.body)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)

                                            if !tx.isFixedCost {
                                                Image(systemName: "chevron.right")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .listRowBackground(Color(red: 0.18, green: 0.18, blue: 0.19))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        if !tx.isFixedCost {
                                            Button(role: .destructive) {
                                                viewModel.deleteTransaction(id: tx.id)
                                            } label: {
                                                Label("削除", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .frame(height: CGFloat(viewModel.transactions.count * 52) + 20)
                            .scrollDisabled(true)
                            .padding(.horizontal, 20)
                        }
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
        .sheet(item: $editingTransaction, onDismiss: {
            viewModel.fetchData()
        }) { tx in
            QuickInputModalView(
                initialCategoryName: tx.isIncome ? nil : tx.category,
                editingTransactionId: tx.id,
                initialAmount: "\(tx.totalAmount)",
                isIncome: tx.isIncome,
                isIOU: tx.iouAmount > 0
            )
            .presentationDetents([.large])
            .preferredColorScheme(.dark)
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
            
            Text("-¥\(formatCurrency(amount))")
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
