import SwiftUI
import SwiftData

struct TransactionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = TransactionHistoryViewModel()
    @State private var editingTransaction: TransactionDisplayItem? = nil
    
    var body: some View {
        NavigationStack {
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
                
                List {
                    ForEach(viewModel.displayItems) { tx in
                        Button(action: {
                            if !tx.isFixedCost {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                editingTransaction = tx
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack(spacing: 4) {
                                        Text(tx.category)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        if tx.isFixedCost {
                                            Image(systemName: "lock.fill")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Text(tx.date)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(tx.isIncome ? "+¥\(tx.totalAmount)" : "-¥\(tx.personalAmount)")
                                        .font(.system(.title3, design: .rounded).bold())
                                        .foregroundColor(tx.isIncome ? Color(red: 0.4, green: 0.9, blue: 0.6) : (tx.iouAmount > 0 ? .orange : .white))
                                    
                                    if tx.iouAmount > 0 {
                                        Text("総額 ¥\(tx.totalAmount) / 立替 ¥\(tx.iouAmount)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Material.ultraThinMaterial)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.hidden)
                        .deleteDisabled(tx.isFixedCost) // 固定費はスワイプ削除不可
                    }
                    .onDelete(perform: viewModel.deleteTransaction)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .padding(.top, 10)
                
                if viewModel.displayItems.isEmpty {
                    VStack {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.3))
                        Text("履歴がありません")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("支出履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
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
            }
        }
        .onAppear {
            viewModel.fetchData()
        }
    }
}

@MainActor
let previewContainer: ModelContainer = {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Budget.self, ItemCategory.self, IOURecord.self, ExpenseTransaction.self, configurations: config)
        let context = container.mainContext
        context.insert(ItemCategory(name: "食費", totalAmount: 50000, spentAmount: 10000, orderIndex: 0))
        return container
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
}()

#Preview {
    TransactionHistoryView()
        .modelContainer(previewContainer)
}
