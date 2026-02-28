import SwiftUI
import SwiftData

struct TransactionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var editingTransaction: TransactionMock? = nil
    
    // サンプルデータ
    @State private var transactions = [
        TransactionMock(id: 1, date: "2026-03-01 19:30", category: "食費", totalAmount: 1500, iouAmount: 0),
        TransactionMock(id: 2, date: "2026-03-01 12:45", category: "交際費", totalAmount: 3500, iouAmount: 0),
        TransactionMock(id: 3, date: "2026-03-02 08:15", category: "変動費", totalAmount: 500, iouAmount: 0),
        TransactionMock(id: 4, date: "2026-03-03 21:00", category: "交際費", totalAmount: 15000, iouAmount: 12000) // 立替込みの例
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.11).ignoresSafeArea()
                
                List {
                    ForEach(transactions) { tx in
                        Button(action: {
                            editingTransaction = tx
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(tx.category)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    
                                    Text(tx.date)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("¥\(tx.personalAmount)")
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                    
                                    if tx.iouAmount > 0 {
                                        Text("総額 ¥\(tx.totalAmount) / 立替 ¥\(tx.iouAmount)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                    .onDelete(perform: deleteTransaction)
                }
                .scrollContentBackground(.hidden)
                
                if transactions.isEmpty {
                    VStack {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("履歴がありません")
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("支出履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                        .foregroundColor(.yellow)
                }
            }
            .sheet(item: $editingTransaction) { tx in
                QuickInputModalView(initialCategoryName: tx.category)
                    .presentationDetents([.fraction(0.85), .large])
            }
        }
    }
    
    // 削除処理のモック
    private func deleteTransaction(at offsets: IndexSet) {
        transactions.remove(atOffsets: offsets)
        // 実際のアプリではここでデータベースからも削除し、関連するカテゴリの予算残高を復元する
    }
}

// モック用の構造体
struct TransactionMock: Identifiable {
    let id: Int
    let date: String
    let category: String
    let totalAmount: Int
    let iouAmount: Int
    
    var personalAmount: Int {
        totalAmount - iouAmount
    }
}

@MainActor
let previewContainer: ModelContainer = {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Budget.self, ItemCategory.self, IOURecord.self, ExpenseTransaction.self, configurations: config)
        let context = container.mainContext
        context.insert(ItemCategory(name: "食費", totalAmount: 50000, spentAmount: 10000, orderIndex: 0))
        context.insert(ItemCategory(name: "交際費", totalAmount: 30000, spentAmount: 15000, orderIndex: 1))
        context.insert(ItemCategory(name: "変動費", totalAmount: 20000, spentAmount: 5000, orderIndex: 2))
        context.insert(ItemCategory(name: "変動費 A", totalAmount: 20000, spentAmount: 10000, orderIndex: 3))
        context.insert(ItemCategory(name: "変動費 B", totalAmount: 10000, spentAmount: 2000, orderIndex: 4))
        context.insert(ItemCategory(name: "変動費 C", totalAmount: 15000, spentAmount: 20000, orderIndex: 5))
        return container
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
}()

#Preview {
    TransactionHistoryView()
        .modelContainer(previewContainer)
}
