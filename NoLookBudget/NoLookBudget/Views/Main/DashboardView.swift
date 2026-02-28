import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var deepLinkManager: DeepLinkManager
    @Query private var budgets: [Budget]
    @Query(sort: \ItemCategory.orderIndex) private var categories: [ItemCategory]
    
    @State private var showInputModal = false
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showMonthlyReview = false
    @State private var showSideMenu = false
    @State private var initialInputCategory: String? = nil
    @State private var navigationPath = NavigationPath() // 追加: ルーティング管理用
    @State private var hasDebtFromLastMonth = true // モック用の借金フラグ
    
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
                    // 予算オーバー警告
                    if let bg = currentBudget, bg.spentAmount > bg.totalAmount {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("予算をオーバーしています！")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Spacer()
                            Button("確認する") {
                                showMonthlyReview = true
                            }
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.red)
                            .cornerRadius(5)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    
                    // メインの予算ゲージ（金額表示を内部に含む）
                    NavigationLink(destination: BudgetDetailView(budget: currentBudget)) {
                        BudgetGaugeView(budget: currentBudget)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, currentBudget?.spentAmount ?? 0 > currentBudget?.totalAmount ?? 0 ? 0 : 40) // 警告がある場合は余白を詰める
                    
                    // 支出入力ボタン（メインアクション）
                    VStack(spacing: 15) {
                        // 借金警告ボタン
                        if hasDebtFromLastMonth {
                            Button(action: {
                                showMonthlyReview = true
                            }) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                    Text("前月の借金により予算修正が必要です")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 12)
                                .background(Color.yellow.opacity(0.15))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                                )
                            }
                        }
                        
                        Button(action: {
                            initialInputCategory = nil
                            showInputModal = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text("支出を入力")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.4, green: 0.9, blue: 0.6))
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal, 20)
                    
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
            
            // サイドメニューのオーバーレイ
            if showSideMenu {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showSideMenu = false }
                    }
                
                HStack {
                    SideMenuView(
                        showHistory: $showHistory,
                        showSettings: $showSettings,
                        showMonthlyReview: $showMonthlyReview,
                        showSideMenu: $showSideMenu
                    )
                    .frame(width: 260)
                    
                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    withAnimation { showSideMenu = true }
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            setupMockDataIfNeeded()
            // コールドスタート（アプリ完全停止時）からのディープリンク対応
            if let categoryName = deepLinkManager.selectedCategory {
                initialInputCategory = categoryName
                showInputModal = true
                deepLinkManager.selectedCategory = nil
            }
        }
        .sheet(isPresented: $showInputModal) {
            QuickInputModalView(initialCategoryName: initialInputCategory)
                .presentationDetents([.fraction(0.85), .large])
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showHistory) {
            TransactionHistoryView()
        }
        .sheet(isPresented: $showMonthlyReview) {
            MonthlyReviewView()
        }
        .onChange(of: deepLinkManager.selectedCategory) { oldValue, newValue in
            // ディープリンクで受け取ったカテゴリ名があれば、そのカテゴリ状態のまま入力モーダルを開く
            if let categoryName = newValue {
                initialInputCategory = categoryName
                showInputModal = true
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
                Text("残額")
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
                
                Text("使用済")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                Text("¥\(Int(budget?.spentAmount ?? 100000))")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4))
                
                // 追加：詳細へ遷移できることを明示
                HStack(spacing: 2) {
                    Text("タップして詳細")
                        .font(.system(size: 10))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                }
                .foregroundColor(.gray.opacity(0.8))
                .padding(.top, 5)
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
            
            VStack(spacing: 2) {
                Text(name)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                Text(amountString)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(amountColor)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
        .frame(width: 80, height: 80)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Budget.self, ItemCategory.self, IOURecord.self, ExpenseTransaction.self], inMemory: true)
        .environmentObject(DeepLinkManager())
}

// MARK: - 全体予算詳細ビュー
struct BudgetDetailView: View {
    var budget: Budget?
    
    @State private var editingTransaction: DashboardTransactionMock? = nil
    
    // モックデータ: 直近の記録
    let recentTransactions = [
        DashboardTransactionMock(id: 1, category: "食費", date: "2026-03-01 19:30", amount: 1500),
        DashboardTransactionMock(id: 2, category: "交際費", date: "2026-03-01 12:45", amount: 3500),
        DashboardTransactionMock(id: 3, category: "変動費", date: "2026-03-02 08:15", amount: 500)
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.13, blue: 0.14).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    BudgetGaugeView(budget: budget)
                        .scaleEffect(0.9)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("予算の推移")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        // ここのグラフ等はモック
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 150)
                            .overlay(Text("グラフ表示エリア").foregroundColor(.gray))
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("直近の記録")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        // 直近の記録をタップ可能にし、編集モーダルを呼び出す
                        ForEach(recentTransactions) { tx in
                            Button(action: {
                                editingTransaction = tx
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(tx.category)
                                            .foregroundColor(.white)
                                        Text(tx.date)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Text("-¥\(tx.amount)")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 50)
                }
            }
        }
        .navigationTitle("今月の全体予算")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingTransaction) { tx in
            QuickInputModalView(initialCategoryName: tx.category)
                .presentationDetents([.fraction(0.85), .large])
        }
    }
}

// ダッシュボード用・直近履歴モック構造体
struct DashboardTransactionMock: Identifiable {
    let id: Int
    let category: String
    let date: String
    let amount: Int
}

// MARK: - サイドメニュービュー
struct SideMenuView: View {
    @Binding var showHistory: Bool
    @Binding var showSettings: Bool
    @Binding var showMonthlyReview: Bool
    @Binding var showSideMenu: Bool
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.11)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 30) {
                Text("メニュー")
                    .font(.title2.bold())
                    .foregroundColor(.gray)
                    .padding(.top, 40)
                    .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 20) {
                    MenuButton(icon: "star.circle.fill", title: "月末振り返り", color: .yellow) {
                        showSideMenu = false
                        showMonthlyReview = true
                    }
                    MenuButton(icon: "clock.arrow.circlepath", title: "支出履歴", color: .white) {
                        showSideMenu = false
                        showHistory = true
                    }
                    Divider().background(Color.white.opacity(0.3))
                    MenuButton(icon: "gearshape.fill", title: "設定", color: .white) {
                        showSideMenu = false
                        showSettings = true
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}

private struct MenuButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 10)
        }
    }
}
