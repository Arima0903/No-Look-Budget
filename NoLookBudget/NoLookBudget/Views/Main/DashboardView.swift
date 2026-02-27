import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var deepLinkManager: DeepLinkManager
    @Query private var budgets: [Budget]
    @Query(sort: \ItemCategory.orderIndex) private var categories: [ItemCategory]
    
    @State private var showInputModal = false
    @State private var navigationPath = NavigationPath() // 追加: ルーティング管理用
    
    // モックデータとして、最初の予算を取得（なければ画面表示時に生成）
    var currentBudget: Budget? {
        budgets.first
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // 背景色 (ダークモード基調)
                Color(red: 0.13, green: 0.13, blue: 0.14).ignoresSafeArea()
            
            VStack(spacing: 30) {
                // ヘッダー (現在の日付)
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .padding(.top, 20)
                
                // メインの予算ゲージ（金額表示を内部に含む）
                NavigationLink(destination: BudgetDetailView(budget: currentBudget)) {
                    BudgetGaugeView(budget: currentBudget)
                }
                .buttonStyle(PlainButtonStyle())

                
                // クイック入力ボタン
                Button(action: {
                    showInputModal = true
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("QUICK-SYNC & LOG")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 15)
                    .padding(.horizontal, 40)
                    .background(
                        Capsule()
                            .stroke(Color.white, lineWidth: 2)
                    )
                }
                .padding(.top, 20)
                
                // 下部：項目別の小ウィジェット（カテゴリ）
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    if categories.isEmpty {
                        // モック用ダミーカテゴリ
                        NavigationLink(value: "食費") {
                            CategoryGaugeView(name: "食費", amount: 20000, ratio: 0.8)
                        }
                        NavigationLink(value: "交際費") {
                            CategoryGaugeView(name: "交際費", amount: 15000, ratio: 0.4) // 色指定統一のためisIOUを除外
                        }
                        NavigationLink(value: "変動費") {
                            CategoryGaugeView(name: "変動費", amount: 15000, ratio: 0.1)
                        }
                        NavigationLink(value: "変動費 A") {
                            CategoryGaugeView(name: "変動費 A", amount: 10000, ratio: 0.5)
                        }
                        NavigationLink(value: "変動費 B") {
                            CategoryGaugeView(name: "変動費 B", amount: 8000, ratio: 0.2)
                        }
                        NavigationLink(value: "変動費 C") {
                            CategoryGaugeView(name: "変動費 C", amount: -5000, ratio: 1.33)
                        }
                    } else {
                        ForEach(categories) { category in
                            let ratio = category.totalAmount > 0 ? (category.spentAmount / category.totalAmount) : 0
                            NavigationLink(value: category.name) {
                                CategoryGaugeView(name: category.name, amount: Int(category.remainingAmount), ratio: ratio)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 10)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            setupMockDataIfNeeded()
        }
        .sheet(isPresented: $showInputModal) {
            QuickInputModalView()
                .presentationDetents([.fraction(0.65)])
        }
        .onChange(of: deepLinkManager.selectedCategory) { oldValue, newValue in
            // ディープリンクで受け取ったカテゴリ名があれば、そのカテゴリ詳細画面へ強制遷移する
            if let categoryName = newValue {
                navigationPath.append(categoryName)
                deepLinkManager.selectedCategory = nil // 消費したらリセット
            }
        }
        .onChange(of: deepLinkManager.navigateToDashboard) { oldValue, newValue in
            if newValue {
                // ダッシュボードが指定された場合はナビゲーション階層をリセット（トップに戻る）
                navigationPath.removeLast(navigationPath.count)
                deepLinkManager.navigateToDashboard = false
            }
        }
        .navigationDestination(for: String.self) { categoryName in
            CategoryDetailView(categoryName: categoryName)
        }
        } // End of NavigationStack
    }
    
    private func setupMockDataIfNeeded() {
        if budgets.isEmpty {
            let mockBudget = Budget(month: Date(), totalAmount: 250000, spentAmount: 100000)
            modelContext.insert(mockBudget)
            
            let cat1 = ItemCategory(name: "食費", totalAmount: 50000, spentAmount: 30000, orderIndex: 0)
            let cat2 = ItemCategory(name: "交際費", totalAmount: 30000, spentAmount: 15000, orderIndex: 1)
            let cat3 = ItemCategory(name: "変動費", totalAmount: 20000, spentAmount: 5000, orderIndex: 2)
            let cat4 = ItemCategory(name: "変動費 A", totalAmount: 20000, spentAmount: 10000, orderIndex: 3)
            let cat5 = ItemCategory(name: "変動費 B", totalAmount: 10000, spentAmount: 2000, orderIndex: 4)
            let cat6 = ItemCategory(name: "変動費 C", totalAmount: 15000, spentAmount: 20000, orderIndex: 5)
            
            modelContext.insert(cat1)
            modelContext.insert(cat2)
            modelContext.insert(cat3)
            modelContext.insert(cat4)
            modelContext.insert(cat5)
            modelContext.insert(cat6)
        }
    }
}

// メインの巨大円形ゲージ
struct BudgetGaugeView: View {
    var budget: Budget?
    
    var body: some View {
        ZStack {
            // 1周まるごとの「予算全体（緑）」
            Circle()
                .stroke(Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.3), style: StrokeStyle(lineWidth: 35, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            
            let spentRatio = budget != nil && budget!.totalAmount > 0 ? (budget!.spentAmount / budget!.totalAmount) : 0.4
            let clampedRatio = min(max(spentRatio, 0), 1)
            
            // 使用済み（赤）を0時の方向から右回りに上書きしていく
            Circle()
                .trim(from: 0, to: clampedRatio)
                .stroke(Color(red: 0.9, green: 0.4, blue: 0.4), style: StrokeStyle(lineWidth: 35, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            
            // 残高の緑ライン (赤の終点から1周の終わりまで)
            Circle()
                .trim(from: clampedRatio, to: 1)
                .stroke(Color(red: 0.4, green: 0.9, blue: 0.6), style: StrokeStyle(lineWidth: 35, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            
            // 中央空洞への情報表示（時計のアイコンの代わりに数字を入れる）
            VStack(spacing: 5) {
                Text("REMAINING")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                let remainingColor: Color = (spentRatio > 0.5) ? .yellow : Color(red: 0.4, green: 0.9, blue: 0.6)
                
                Text("¥\(Int(budget?.remainingAmount ?? 150000))")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(remainingColor)
                
                Divider()
                    .background(Color.gray.opacity(0.5))
                    .frame(width: 100)
                    .padding(.vertical, 4)
                
                Text("SPENT")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                Text("¥\(Int(budget?.spentAmount ?? 100000))")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4))
            }
        }
        .frame(width: 250, height: 250)
        .padding(.vertical, 20)
    }
}

// 項目別の小ウィジェットゲージ
struct CategoryGaugeView: View {
    let name: String
    let amount: Int
    let ratio: Double
    
    var amountColor: Color {
        // 文字の色: 50%を超えると黄色、100%を超えると赤
        if ratio >= 1.0 { return Color(red: 0.9, green: 0.4, blue: 0.4) }
        else if ratio > 0.5 { return Color.yellow }
        else { return Color(red: 0.4, green: 0.9, blue: 0.6) }
    }
    
    var amountString: String {
        if amount < 0 {
            return "-¥\(-amount)"
        } else {
            return "¥\(amount)"
        }
    }
    
    var body: some View {
        ZStack {
            // 背景の円全体（緑）
            Circle()
                .stroke(Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.3), lineWidth: 8)
                .rotationEffect(.degrees(-90))
            
            let clampedRatio = min(max(ratio, 0), 1)
            
            // 使用済み（赤に統一）
            Circle()
                .trim(from: 0, to: clampedRatio)
                .stroke(Color(red: 0.9, green: 0.4, blue: 0.4), style: StrokeStyle(lineWidth: 8, lineCap: .butt)) // 一律で赤色に統一
                .rotationEffect(.degrees(-90))
            
            // 残金（緑）
            Circle()
                .trim(from: clampedRatio, to: 1)
                .stroke(Color(red: 0.4, green: 0.9, blue: 0.6), style: StrokeStyle(lineWidth: 8, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            
            VStack {
                Text(name)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                Text(amountString)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(amountColor)
            }
        }
        .frame(width: 80, height: 80)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Budget.self, ItemCategory.self, IOURecord.self, ExpenseTransaction.self], inMemory: true)
        .environmentObject(DeepLinkManager())
}

// MARK: - 仮の遷移先ビュー（後ほど別ファイルに切り出し予定）
struct BudgetDetailView: View {
    var budget: Budget?
    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.13, blue: 0.14).ignoresSafeArea()
            VStack {
                Text("全体の予算詳細")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                Text("（ここに全項目の履歴などが表示されます）")
                    .foregroundColor(.gray)
                Spacer()
            }
        }
    }
}

struct CategoryDetailView: View {
    var categoryName: String
    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.13, blue: 0.14).ignoresSafeArea()
            VStack {
                Text("\(categoryName) の詳細")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                Text("（ここにこの項目の支出履歴などが表示されます）")
                    .foregroundColor(.gray)
                Spacer()
            }
        }
    }
}
