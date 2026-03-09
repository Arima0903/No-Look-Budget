import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject private var deepLinkManager: DeepLinkManager
    
    @State private var navigationPath = NavigationPath() // ルーティング管理用
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // 背景 (ダークモード基調) + 星空アニメーション
                ZStack {
                    Theme.spaceNavy
                    ConstellationView()
                    
                    // 右上の空きスペースにマスコットを配置
                    VStack {
                        HStack {
                            Spacer()
                            Image("astronaut_mascot")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .blendMode(.screen) // 追加: 黒背景を透過(合成)させる
                                .opacity(0.85)
                                // 修正方法: 頭が見切れる場合はここの数値を大きく（下に移動）します
                                .padding(.top, 100) 
                                .padding(.trailing, 15)
                        }
                        Spacer()
                    }
                }
                .ignoresSafeArea()
                
                // 予算オーバー時の警告グローエフェクト
                if let bg = viewModel.currentBudget, bg.spentAmount > bg.totalAmount {
                    RadialGradient(
                        gradient: Gradient(colors: [Color.red.opacity(0.15), Color.clear]),
                        center: .top,
                        startRadius: 50,
                        endRadius: 400
                    )
                    .ignoresSafeArea()
                    .pulseAnimation() // カスタムアニメーション
                }

                
                VStack(spacing: 30) {
                    // 予算オーバー警告 (Glassmorphism)
                    if let bg = viewModel.currentBudget, bg.spentAmount > bg.totalAmount {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                                Text("予算をオーバーしています！")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Material.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("今月の残り予算")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        // メインの予算ゲージ（金額表示を内部に含む）
                        HStack {
                            Spacer()
                            NavigationLink(destination: BudgetDetailView(
                                budget: viewModel.currentBudget,
                                recentTransactions: viewModel.recentTransactions,
                                dailyTrends: viewModel.dailyTrends,
                                onDelete: viewModel.deleteRecentTransaction
                            )) {
                                BudgetGaugeView(budget: viewModel.currentBudget)
                                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, viewModel.currentBudget?.spentAmount ?? 0 > viewModel.currentBudget?.totalAmount ?? 0 ? 0 : 10)
                            Spacer()
                        }
                    }

                    
                    // 支出入力ボタン（メインアクション）
                    VStack(spacing: 15) {
                        // 借金警告ボタン (Glassmorphism)
                        if viewModel.hasDebtFromLastMonth {
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                viewModel.showMonthlyReview = true
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
                                .background(Material.ultraThin)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                                )
                            }
                        }
                        
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            viewModel.initialInputCategory = nil
                            viewModel.showInputModal = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text("記録をつける")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Theme.safeGradient)
                            .cornerRadius(16)
                            .shadow(color: Theme.spaceGreen.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    
                    // 下部：項目別の小ウィジェット（カテゴリ）
                    VStack(alignment: .leading, spacing: 10) {
                        Text("予算別残り予算")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                            if viewModel.categories.isEmpty {
                                // カテゴリ未設定時の空状態UI
                                VStack(spacing: 15) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("カテゴリがありません\n左上のメニューから設定してください")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                // グリッドの3列分の中央に配置するためのハック
                                .frame(maxWidth: .infinity)
                                .gridCellColumns(3)
                                .padding(.top, 20)
                            } else {
                                ForEach(viewModel.categories) { category in
                                    let ratio = category.totalAmount > 0 ? (category.spentAmount / category.totalAmount) : 0
                                    NavigationLink(value: category.name) {
                                        CategoryGaugeView(name: category.name, amount: Int(category.remainingAmount), ratio: ratio)
                                    }
                                    .simultaneousGesture(TapGesture().onEnded {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    })
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                    }
                
                Spacer()
            }
            
            // サイドメニューのオーバーレイ
            if viewModel.showSideMenu {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { viewModel.showSideMenu = false }
                    }
                
                HStack {
                    SideMenuView(
                        showHistory: $viewModel.showHistory,
                        showSettings: $viewModel.showSettings,
                        showMonthlyReview: $viewModel.showMonthlyReview,
                        showIOU: $viewModel.showIOU,
                        showBudgetConfig: $viewModel.showBudgetConfig,
                        showCategoryConfig: $viewModel.showCategoryConfig,
                        showSideMenu: $viewModel.showSideMenu
                    )
                    .frame(width: 260)
                    
                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
        .background(Theme.spaceNavy)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.spaceNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    withAnimation { viewModel.showSideMenu = true }
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            viewModel.fetchData()
            // コールドスタート（アプリ完全停止時）からのディープリンク対応
            if let categoryName = deepLinkManager.selectedCategory {
                viewModel.initialInputCategory = categoryName
                viewModel.showInputModal = true
                deepLinkManager.selectedCategory = nil
            }
        }
        .sheet(isPresented: $viewModel.showInputModal, onDismiss: {
            viewModel.fetchData()
        }) {
            QuickInputModalView(initialCategoryName: viewModel.initialInputCategory)
                .preferredColorScheme(.dark)
                .presentationDetents([.fraction(0.85), .large])
        }
        .sheet(isPresented: $viewModel.showSettings, onDismiss: {
            viewModel.fetchData()
        }) {
            SettingsView()
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $viewModel.showHistory, onDismiss: {
            viewModel.fetchData()
        }) {
            TransactionHistoryView()
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $viewModel.showMonthlyReview, onDismiss: {
            viewModel.fetchData()
        }) {
            MonthlyReviewView()
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $viewModel.showIOU, onDismiss: {
            viewModel.fetchData()
        }) {
            IOURecordView()
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $viewModel.showBudgetConfig, onDismiss: {
            viewModel.fetchData()
        }) {
            NavigationStack {
                BudgetConfigurationView()
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $viewModel.showCategoryConfig, onDismiss: {
            viewModel.fetchData()
        }) {
            NavigationStack {
                CategoryConfigurationView()
            }
            .preferredColorScheme(.dark)
        }
        .onChange(of: deepLinkManager.selectedCategory) { oldValue, newValue in
            // ディープリンクで受け取ったカテゴリ名があれば、そのカテゴリ状態のまま入力モーダルを開く
            if let categoryName = newValue {
                viewModel.initialInputCategory = categoryName
                viewModel.showInputModal = true
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
        .background(Theme.spaceNavy)
        .preferredColorScheme(.dark) // 確実にダークモードを強制
    }
}

// MARK: - View Modifiers
struct PulseAnimationModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulseAnimation() -> some View {
        self.modifier(PulseAnimationModifier())
    }
}

// MARK: - Constellation Background (星座アニメーション・静的)
struct ConstellationView: View {
    // 星の数
    let starCount = 35
    @State private var stars: [CGPoint] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 星同士を繋ぐ線 (星座線)
                Path { path in
                    for i in 0..<stars.count {
                        // 近くの星（数個）と線を繋ぐ
                        for j in (i+1)..<stars.count {
                            let dist = hypot(stars[i].x - stars[j].x, stars[i].y - stars[j].y)
                            if dist < 80 { // 距離が近い星だけを繋ぐ
                                path.move(to: stars[i])
                                path.addLine(to: stars[j])
                            }
                        }
                    }
                }
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                
                // 星そのもの
                ForEach(0..<stars.count, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        // インデックスを利用して星の大きさを1.5〜3.5の間で疑似ランダムに設定
                        .frame(width: 1.5 + CGFloat(index % 3))
                        .position(stars[index])
                        .opacity(0.6 + (Double(index % 4) * 0.1))
                }
            }
            .onAppear {
                if stars.isEmpty {
                    var newStars: [CGPoint] = []
                    // 再描画時も座標が変わらないように一度だけ生成して保持する
                    for _ in 0..<starCount {
                        newStars.append(CGPoint(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        ))
                    }
                    stars = newStars
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// 押し込みアニメーション付きボタンスタイル
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// メインの巨大円形ゲージ
struct BudgetGaugeView: View {
    var budget: Budget?
    @State private var animatedRatio: Double = 0
    
    var body: some View {
        ZStack {
            // 背景のグロー
            Circle()
                .fill(Color.black.opacity(0.2))
                .blur(radius: 20)
            
            // 背景の円全体（ベース）
            Circle()
                .stroke(Color.white.opacity(0.05), style: StrokeStyle(lineWidth: 35, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            
            // 宇宙飛行士モチーフはダッシュボード全体の右上に移動しました
            
            let displayTotal = budget?.incomeAmount ?? budget?.totalAmount ?? 250000.0
            let fixedAndSavings = displayTotal - (budget?.totalAmount ?? 250000.0)
            let displaySpent = (budget?.spentAmount ?? 100000.0) + fixedAndSavings
            let spentRatio = displayTotal > 0 ? (displaySpent / displayTotal) : 0.4
            let clampedRatio = min(max(spentRatio, 0), 1)
            
            // 使用済み（オレンジ〜赤グラデーション）
            Circle()
                .trim(from: 0, to: animatedRatio)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Theme.warmOrange, Theme.coralRed]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 35, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.coralRed.opacity(clampedRatio > 0.8 ? 0.3 : 0), radius: 10)
            
            // 残高の緑ライン (赤の終点から1周の終わりまで)
            if animatedRatio < 1.0 {
                Circle()
                    .trim(from: animatedRatio + 0.005, to: 1) // +0.005 for a tiny gap
                    .stroke(
                        Theme.safeGradient,
                        style: StrokeStyle(lineWidth: 35, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Theme.spaceGreen.opacity(0.2), radius: 10)
            }
            
            // 中央空洞への情報表示
            VStack(spacing: 2) {
                let displayTotal = budget?.incomeAmount ?? budget?.totalAmount ?? 250000.0
                let fixedAndSavings = displayTotal - (budget?.totalAmount ?? 250000.0)
                let displaySpent = (budget?.spentAmount ?? 100000.0) + fixedAndSavings
                let spentRatio = displayTotal > 0 ? (displaySpent / displayTotal) : 0.4
                
                Text("手取り総額: ¥\(Int(displayTotal))")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .padding(.bottom, 2)
                
                Text("残額")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                let remainingColor: Color = (spentRatio > 0.8) ? Theme.coralRed : ((spentRatio > 0.5) ? Theme.warmOrange : Theme.textMain)
                
                Text("¥\(Int(budget?.remainingAmount ?? 150000))")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(remainingColor)
                    // グローエフェクト
                    .shadow(color: remainingColor.opacity(0.5), radius: 5, x: 0, y: 0)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(width: 120)
                    .padding(.vertical, 8)
                
                Text("使用済(固定費込)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                Text("¥\(Int(displaySpent))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.coralRed)
                
                // 追加：詳細へ遷移できることを明示
                HStack(spacing: 4) {
                    Text("詳細")
                        .font(.system(size: 11, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.gray.opacity(0.8))
                .padding(.top, 8)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Material.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.top, 5)
            }
        }
        .frame(width: 260, height: 260)
        .padding(.vertical, 10)
        .onAppear {
            updateRatio()
        }
        .onChange(of: budget?.spentAmount) { _, _ in
            updateRatio()
        }
    }
    
    private func updateRatio() {
        let displayTotal = budget?.incomeAmount ?? budget?.totalAmount ?? 250000.0
        let fixedAndSavings = displayTotal - (budget?.totalAmount ?? 250000.0)
        let displaySpent = (budget?.spentAmount ?? 100000.0) + fixedAndSavings
        let targetRatio = displayTotal > 0 ? (displaySpent / displayTotal) : 0.4
        let clampedTarget = min(max(targetRatio, 0), 1)
        withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
            animatedRatio = clampedTarget
        }
    }
}

// 項目別の小ウィジェットゲージ
struct CategoryGaugeView: View {
    let name: String
    let amount: Int
    let ratio: Double
    
    var amountColor: Color {
        // 文字の色: 50%を超えると黄色、100%を超えると赤
        if ratio >= 1.0 { return Theme.coralRed }
        else if ratio > 0.5 { return Theme.warmOrange }
        else { return Theme.spaceGreen }
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
            // 背景の円全体（ベース）
            Circle()
                .stroke(Color.white.opacity(0.05), style: StrokeStyle(lineWidth: 8, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            
            let clampedRatio = min(max(ratio, 0), 1)
            
            // 使用済み（グラデーション）
            Circle()
                .trim(from: 0, to: clampedRatio)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Theme.warmOrange, Theme.coralRed]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))
            
            // 残金（緑グラデーション）
            if clampedRatio < 1.0 {
                Circle()
                    .trim(from: clampedRatio + 0.05, to: 1) // slightly separate
                    .stroke(
                        Theme.safeGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
            }
            
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
        .modelContainer(for: [Budget.self, ItemCategory.self, IOURecord.self, ExpenseTransaction.self, FixedCostSetting.self], inMemory: true)
        .environmentObject(DeepLinkManager())
        .preferredColorScheme(.dark)
}

// MARK: - 全体予算詳細ビュー
struct BudgetDetailView: View {
    var budget: Budget?
    var recentTransactions: [TransactionDisplayItem]
    var dailyTrends: [DailyBudgetTrend]
    var onDelete: (IndexSet) -> Void
    
    @State private var editingTransaction: TransactionDisplayItem? = nil
    
    var body: some View {
        ZStack {
            Theme.spaceNavy.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    BudgetGaugeView(budget: budget)
                        .scaleEffect(0.9)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("予算の推移")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        if let budget = budget {
                            let total = budget.totalAmount
                            let calendar = Calendar.current
                            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: budget.month)) ?? Date()
                            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: startOfMonth) ?? Date()
                            
                            VStack(spacing: 5) {
                                if dailyTrends.isEmpty {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white.opacity(0.05))
                                        .frame(height: 150)
                                        .overlay(Text("データがありません").foregroundColor(.gray))
                                } else {
                                    Chart(dailyTrends) { trend in
                                        // 支出額推移 (赤)
                                        LineMark(
                                            x: .value("日付", trend.date),
                                            y: .value("金額", trend.spent)
                                        )
                                        .foregroundStyle(by: .value("データ", "累積支出"))
                                        .lineStyle(StrokeStyle(lineWidth: 3))
                                        
                                        // 残り予算推移 (緑)
                                        LineMark(
                                            x: .value("日付", trend.date),
                                            y: .value("金額", trend.remaining)
                                        )
                                        .foregroundStyle(by: .value("データ", "残り予算"))
                                        .lineStyle(StrokeStyle(lineWidth: 3))
                                    }
                                    .chartForegroundStyleScale([
                                        "残り予算": Theme.spaceGreen,
                                        "累積支出": Theme.coralRed
                                    ])
                                    .chartLegend(position: .top, alignment: .trailing)
                                    .chartXScale(domain: startOfMonth...endOfMonth)
                                    .chartXAxis {
                                        AxisMarks(values: .stride(by: .day, count: 5)) { value in
                                            AxisGridLine().foregroundStyle(.gray.opacity(0.3))
                                            AxisTick().foregroundStyle(.gray)
                                            AxisValueLabel(format: .dateTime.month(.defaultDigits).day(), centered: true)
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                    .chartYAxis {
                                        AxisMarks(position: .leading) { value in
                                            AxisGridLine().foregroundStyle(.gray.opacity(0.3))
                                            AxisValueLabel()
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                    .frame(height: 180)
                                    .padding(.top, 10)
                                }
                                
                                // 臨時収入が合算されていることを示すテキスト
                                HStack {
                                    Spacer()
                                    Text("※ 臨時収入は手取り予算として合算されています [ 総枠: ¥\(Int(total)) ]")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                .padding(.top, 4)
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 60)
                                .overlay(Text("データがありません").foregroundColor(.gray))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("直近の記録 (最大100件)")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        if recentTransactions.isEmpty {
                            Text("最近の記録はありません")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                        } else {
                            if recentTransactions.count > 5 {
                                Text("↓ さらに履歴を見るには下にスクロール")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 5)
                            }
                            
                            // ScrollViewの中にListを入れるとバグになるため、固定高で擬似Listを作る
                            List {
                                ForEach(recentTransactions) { tx in
                                    Button(action: {
                                        if !tx.isFixedCost {
                                            editingTransaction = tx
                                        }
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                HStack(spacing: 4) {
                                                    Text(tx.category)
                                                        .foregroundColor(.white)
                                                    if tx.isFixedCost {
                                                        Image(systemName: "lock.fill")
                                                            .font(.caption2)
                                                            .foregroundColor(.gray)
                                                    }
                                                }
                                                Text(tx.date)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            Text(tx.isIncome ? "+¥\(tx.totalAmount)" : "-¥\(tx.personalAmount)")
                                                .fontWeight(.bold)
                                                .foregroundColor(tx.isIncome ? Color(red: 0.4, green: 0.9, blue: 0.6) : .white)
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    .listRowBackground(Color.white.opacity(0.05))
                                    .deleteDisabled(tx.isFixedCost)
                                }
                                .onDelete(perform: onDelete)
                            }
                            .listStyle(.plain)
                            .frame(height: CGFloat(recentTransactions.count * 60) + 20) // 簡易的な高さ計算
                            .scrollDisabled(true) // 外側のScrollViewに任せる
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
            }
        }
        .navigationTitle("今月の全体予算")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingTransaction) { tx in
            QuickInputModalView(
                initialCategoryName: tx.isIncome ? nil : tx.category,
                editingTransactionId: tx.id,
                initialAmount: "\(tx.totalAmount)",
                isIncome: tx.isIncome,
                isIOU: tx.iouAmount > 0
            )
            .presentationDetents([.fraction(0.85), .large])
        }
    }
}

// MARK: - サイドメニュービュー
struct SideMenuView: View {
    @Binding var showHistory: Bool
    @Binding var showSettings: Bool
    @Binding var showMonthlyReview: Bool
    @Binding var showIOU: Bool
    @Binding var showBudgetConfig: Bool // 追加
    @Binding var showCategoryConfig: Bool // 追加
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
                    MenuButton(icon: "person.2.circle.fill", title: "立替リスト", color: .orange) {
                        showSideMenu = false
                        showIOU = true
                    }
                    MenuButton(icon: "clock.arrow.circlepath", title: "支出履歴", color: .white) {
                        showSideMenu = false
                        showHistory = true
                    }
                    Divider().background(Color.white.opacity(0.3))
                    Group {
                        Text("家計設定").font(.caption).foregroundColor(.gray)
                        MenuButton(icon: "dollarsign.circle.fill", title: "予算・貯金の設定", color: .green) {
                            showSideMenu = false
                            showBudgetConfig = true
                        }
                        MenuButton(icon: "list.bullet.circle.fill", title: "カテゴリの編集", color: .cyan) {
                            showSideMenu = false
                            showCategoryConfig = true
                        }
                    }
                    Divider().background(Color.white.opacity(0.3))
                    MenuButton(icon: "gearshape.fill", title: "アプリ設定", color: .white) {
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
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
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
