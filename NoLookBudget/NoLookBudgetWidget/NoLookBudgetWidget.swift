import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), budgetTotal: 250000, budgetSpent: 100000, categories: [
            CategoryData(name: "食費", amount: 20000, ratio: 0.8),
            CategoryData(name: "交際費", amount: 15000, ratio: 0.4)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task { @MainActor in
            let modelContext = SharedModelContainer.shared.mainContext
            
            // 予算情報を取得
            let budgetTotal: Double
            let budgetSpent: Double
            let budgetDesc = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.month, order: .reverse)])
            if let budget = (try? modelContext.fetch(budgetDesc))?.first {
                let displayTotal = budget.incomeAmount ?? budget.totalAmount
                let fixedAndSavings = displayTotal - budget.totalAmount
                budgetTotal = displayTotal
                budgetSpent = budget.spentAmount + fixedAndSavings
            } else {
                budgetTotal = 250000
                budgetSpent = 0
            }
            
            // カテゴリ情報を取得
            let categoryDescriptor = FetchDescriptor<ItemCategory>(sortBy: [SortDescriptor(\.orderIndex)])
            let fetchedCategories = (try? modelContext.fetch(categoryDescriptor)) ?? []
            
            // 最大6件を抽出してWidget用のデータに変換
            let mappedCategories = fetchedCategories.prefix(6).map { cat in
                let ratio = cat.totalAmount > 0 ? (cat.spentAmount / cat.totalAmount) : 0.0
                return CategoryData(name: cat.name, amount: Int(cat.totalAmount - cat.spentAmount), ratio: ratio)
            }
            
            let entry = SimpleEntry(date: Date(), budgetTotal: budgetTotal, budgetSpent: budgetSpent, categories: mappedCategories)
            
            // ウィジェットの更新スケジュール（基本はアプリからのリロードかAppIntentで更新するため、次は1時間後くらいで指定）
            let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
            completion(timeline)
        }
    }
}

struct CategoryData {
    let name: String
    let amount: Int
    let ratio: Double
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let budgetTotal: Double
    let budgetSpent: Double
    let categories: [CategoryData]
}

struct NoLookBudgetWidgetEntryView : View {
    var entry: SimpleEntry

    var body: some View {
        ZStack {
            Theme.spaceNavy
            
            VStack(spacing: 12) {
                // 上半分: メイン情報（左にゲージ、右に詳細テキスト）
                HStack(spacing: 0) {
                    // 左側: メインゲージ
                    Link(destination: URL(string: "nolookbudget://dashboard")!) {
                        WidgetBudgetGaugeView(totalAmount: entry.budgetTotal, spentAmount: entry.budgetSpent)
                            .frame(width: 105, height: 105) // サイズを少し縮小して見切れを防止
                    }
                    
                    // 右側: タイトルと金額の詳細情報（余ったスペースの真ん中に配置）
                    VStack(alignment: .center, spacing: 0) {
                        // アプリタイトル（中央上部に配置）
                        Text("NoLookBudget")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.top, 5)
                        
                        Spacer() // タイトルと数値ブロックを離して下に押し下げる
                        
                        // 数値ブロック（内部は左揃えのまま、ブロックごと中央へ）
                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("手取り総額")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.gray)
                                Text("¥\(Int(entry.budgetTotal))")
                                    .font(.system(size: 16, weight: .bold)) // 少し縮小
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("使用済(固定費込)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.gray)
                                Text("¥\(Int(entry.budgetSpent))")
                                    .font(.system(size: 16, weight: .bold)) // 少し縮小
                                    .foregroundColor(Theme.coralRed)
                            }
                        }
                        .padding(.bottom, 5) // 下端へのパディング
                    }
                    .frame(maxWidth: .infinity, maxHeight: 110) // 右側の全スペースを使ってその中でCenter揃えにする
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 10)
                
                // 下半分: カテゴリ一覧（以前と同じ3x2グリッド）
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(entry.categories, id: \.name) { cat in
                        Link(destination: URL(string: "nolookbudget://category/\(cat.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")")!) {
                            WidgetCategoryGaugeView(name: cat.name, amount: cat.amount, ratio: cat.ratio)
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(24) // 全体に十分なパディングを持たせて見切れを防ぐ
        }
    }
}

// Widget Configuration
struct NoLookBudgetWidget: Widget {
    let kind: String = "NoLookBudgetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                NoLookBudgetWidgetEntryView(entry: entry)
                    .containerBackground(Color(red: 0.13, green: 0.13, blue: 0.14), for: .widget)
            } else {
                NoLookBudgetWidgetEntryView(entry: entry)
                    .background(Color(red: 0.13, green: 0.13, blue: 0.14))
            }
        }
        .configurationDisplayName("No-Look-Budget")
        .description("常に予算の一覧をホーム画面で確認できます。")
        .supportedFamilies([.systemLarge]) // 大ウィジェット専用
        .contentMarginsDisabled() // これでウィジェットの余白を消して画面いっぱいに広げる
    }
}

// MARK: - Widget用 UIコンポーネント

struct WidgetBudgetGaugeView: View {
    let totalAmount: Double
    let spentAmount: Double
    
    var remainingAmount: Double { totalAmount - spentAmount }
    
    var remainingColor: Color {
        let ratio = totalAmount > 0 ? (spentAmount / totalAmount) : 0
        // 赤いゲージが半分を超えたら(予算50%切ったら)黄色に
        if ratio > 0.5 { return Color.yellow }
        return Color(red: 0.4, green: 0.9, blue: 0.6) // 通常は緑
    }
    
    var body: some View {
        ZStack {
            // 背景ベース（ちょっと薄く）
            Circle()
                .stroke(Color.white.opacity(0.05), style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            
            let spentRatio = totalAmount > 0 ? (spentAmount / totalAmount) : 0.4
            let clampedRatio = min(max(spentRatio, 0), 1)
            
            // 使用済みのグラデーション（オレンジ〜赤）
            Circle()
                .trim(from: 0, to: clampedRatio)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Theme.warmOrange, Theme.coralRed]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 22, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))
            
            // 下地の緑（残高）
            if clampedRatio < 1.0 {
                Circle()
                    .trim(from: clampedRatio + 0.005, to: 1) // +0.005 for a tiny gap
                    .stroke(
                        Theme.safeGradient,
                        style: StrokeStyle(lineWidth: 22, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
            }
            
            // ゲージ内のテキストが被らないようにサイズと横幅の制限を付ける
            VStack(spacing: 2) {
                Text("残り")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("¥\(Int(totalAmount - spentAmount))")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(remainingColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .padding(.horizontal, 24) // ゲージの淵(lineWidth=22)に当たらないように内側にパディング
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

struct WidgetCategoryGaugeView: View {
    let name: String
    let amount: Int
    let ratio: Double
    var amountColor: Color {
        // グラデーションの境界値: 50%以上で黄色、100%以上で赤
        if ratio >= 1.0 { return Theme.coralRed }
        else if ratio > 0.5 { return Theme.warmOrange }
        else { return Theme.spaceGreen }
    }
    
    var amountString: String { amount < 0 ? "-¥\(-amount)" : "¥\(amount)" }
    
    var body: some View {
        ZStack {
            // 背景ベース
            Circle()
                .stroke(Color.white.opacity(0.05), style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            
            let clampedRatio = min(max(ratio, 0), 1)
            
            // 使用済みグラデーション
            Circle()
                .trim(from: 0, to: clampedRatio)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.orange, Color.red]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))

            // 残高の緑
            if clampedRatio < 1.0 {
                Circle()
                    .trim(from: clampedRatio + 0.02, to: 1)
                    .stroke(
                        Theme.safeGradient,
                        style: StrokeStyle(lineWidth: 10, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
            }
            
            VStack(spacing: 2) {
                Text(name)
                    .font(.system(size: 11, weight: .bold)) // 8 -> 11 に拡大
                    .foregroundColor(.gray)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(amountString)
                    .font(.system(size: 14, weight: .bold)) // 11 -> 14 に拡大
                    .foregroundColor(amountColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8) // 文字が枠に被らないようにパディング
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

#Preview(as: .systemLarge) {
    NoLookBudgetWidget()
} timeline: {
    SimpleEntry(date: .now, budgetTotal: 250000, budgetSpent: 100000, categories: [
        CategoryData(name: "食費", amount: 20000, ratio: 0.8),
        CategoryData(name: "交際費", amount: 15000, ratio: 0.4),
        CategoryData(name: "変動費", amount: 15000, ratio: 0.1)
    ])
}
