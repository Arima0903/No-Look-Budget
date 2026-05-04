import WidgetKit
import SwiftUI
import AppIntents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), budgetTotal: 250000, budgetSpent: 100000, categories: [
            CategoryData(name: "食費", amount: 20000, ratio: 0.8),
            CategoryData(name: "交際費", amount: 15000, ratio: 0.4)
        ], usePercentageDisplay: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task { @MainActor in
            completion(fetchEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task { @MainActor in
            let entry = fetchEntry()
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    /// App Group UserDefaults からスナップショットを読み込む
    /// （SwiftData はクロスプロセスの WAL チェックポイントが保証されないため UserDefaults 経由で受け取る）
    @MainActor
    private func fetchEntry() -> SimpleEntry {
        let suiteName = "group.com.arima0903.NoLookBudget"
        let key = "widget_budget_snapshot_v1"

        guard
            let defaults = UserDefaults(suiteName: suiteName),
            let data = defaults.data(forKey: key)
        else {
            return SimpleEntry(date: Date(), budgetTotal: 0, budgetSpent: 0, categories: [], usePercentageDisplay: false)
        }

        // Codable スナップショット（WidgetDataManager と同じ構造）
        struct Snapshot: Decodable {
            let budgetTotal: Double
            let budgetSpent: Double
            let categories: [CategorySnapshot]
            let usePercentageDisplay: Bool?
        }
        struct CategorySnapshot: Decodable {
            let name: String
            let remainingAmount: Int
            let ratio: Double
        }

        guard let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return SimpleEntry(date: Date(), budgetTotal: 0, budgetSpent: 0, categories: [], usePercentageDisplay: false)
        }

        let mappedCategories = snapshot.categories.map {
            CategoryData(name: $0.name, amount: $0.remainingAmount, ratio: $0.ratio)
        }
        return SimpleEntry(
            date: Date(),
            budgetTotal: snapshot.budgetTotal,
            budgetSpent: snapshot.budgetSpent,
            categories: mappedCategories,
            usePercentageDisplay: snapshot.usePercentageDisplay ?? false
        )
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
    /// プレミアムユーザーが有効化した場合、金額をパーセント表示にする
    let usePercentageDisplay: Bool
}

// MARK: - ウィジェット本体ビュー
// 背景は containerBackground に一本化（View 内に Image を置くとレイアウトが壊れるため）

struct NoLookBudgetWidgetEntryView: View {
    var entry: SimpleEntry

    // 7個以上でコンパクトモード（上部ゲージ縮小・カテゴリ固定サイズ）
    private var isCompact: Bool { entry.categories.count > 6 }
    // カテゴリ行数（3列）
    private var categoryRows: Int { (entry.categories.count + 2) / 3 }

    var body: some View {
        VStack(spacing: isCompact ? 4 : 10) {

            // ── 上部: メインゲージ + 数値（コンパクト時は横並びで縮小）──
            HStack(spacing: 8) {
                Link(destination: URL(string: "nolookbudget://dashboard")!) {
                    WidgetBudgetGaugeView(
                        totalAmount: entry.budgetTotal,
                        spentAmount: entry.budgetSpent,
                        usePercentageDisplay: entry.usePercentageDisplay
                    )
                    .frame(width: isCompact ? 60 : 110, height: isCompact ? 60 : 110)
                }

                VStack(alignment: .leading, spacing: 0) {
                    if !isCompact {
                        Text("Orbit Budget")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.bottom, 6)
                    }

                    VStack(alignment: .leading, spacing: isCompact ? 2 : 8) {
                        if entry.usePercentageDisplay {
                            let spentRatio = entry.budgetTotal > 0 ? (entry.budgetSpent / entry.budgetTotal) : 0
                            let remainRatio = max(1.0 - spentRatio, 0)
                            HStack(spacing: isCompact ? 12 : 0) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("残り")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.65))
                                    Text("\(Int(remainRatio * 100))%")
                                        .font(.system(size: isCompact ? 14 : 22, weight: .black, design: .rounded))
                                        .foregroundColor(Theme.spaceGreen)
                                }
                                if !isCompact { Spacer(minLength: 0) }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("使用済")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.65))
                                    Text("\(Int(spentRatio * 100))%")
                                        .font(.system(size: isCompact ? 14 : 22, weight: .black, design: .rounded))
                                        .foregroundColor(Theme.coralRed)
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("手取り総額")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.65))
                                Text("¥\(Int(entry.budgetTotal))")
                                    .font(.system(size: isCompact ? 13 : 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.6)
                                    .lineLimit(1)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text("使用済")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.65))
                                Text("¥\(Int(entry.budgetSpent))")
                                    .font(.system(size: isCompact ? 13 : 16, weight: .bold))
                                    .foregroundColor(Theme.coralRed)
                                    .minimumScaleFactor(0.6)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, isCompact ? 6 : 12)
                .padding(.vertical, isCompact ? 4 : 10)
                .background(
                    RoundedRectangle(cornerRadius: isCompact ? 10 : 14)
                        .fill(Color.black.opacity(0.45))
                        .overlay(
                            RoundedRectangle(cornerRadius: isCompact ? 10 : 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                )
            }

            // 区切り線
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.5)

            // ── 下半分: カテゴリ一覧（残りスペースを全て使い切る）──
            GeometryReader { geo in
                let columns = 3
                let rows = (entry.categories.count + columns - 1) / columns
                let hSpacing: CGFloat = isCompact ? 6 : 8
                let vSpacing: CGFloat = isCompact ? 6 : 8
                let totalHSpacing = hSpacing * CGFloat(columns - 1)
                let totalVSpacing = vSpacing * CGFloat(max(rows - 1, 0))
                let cellWidth = (geo.size.width - totalHSpacing) / CGFloat(columns)
                let cellHeight = (geo.size.height - totalVSpacing) / CGFloat(max(rows, 1))
                let cellSize = min(cellWidth, cellHeight)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(cellSize), spacing: hSpacing), count: columns),
                    spacing: vSpacing
                ) {
                    ForEach(entry.categories, id: \.name) { cat in
                        Link(destination: URL(
                            string: "nolookbudget://category/\(cat.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"
                        )!) {
                            WidgetCategoryGaugeView(name: cat.name, amount: cat.amount, ratio: cat.ratio, usePercentageDisplay: entry.usePercentageDisplay, compact: isCompact)
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, isCompact ? 4 : 6)
            .padding(.vertical, isCompact ? 4 : 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.38))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            )
        }
        .padding(.top, isCompact ? 10 : 24)
        .padding(.horizontal, isCompact ? 8 : 16)
        .padding(.bottom, isCompact ? 4 : 12)
    }
}

// MARK: - サイズ別ルーター

struct NoLookBudgetWidgetRouter: View {
    @Environment(\.widgetFamily) var family
    var entry: SimpleEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            NoLookBudgetWidgetEntryView(entry: entry)
        }
    }
}

// MARK: - Medium ウィジェットビュー

struct MediumWidgetView: View {
    var entry: SimpleEntry

    private var topCategories: [CategoryData] {
        Array(entry.categories.sorted { $0.ratio > $1.ratio }.prefix(4))
    }

    var body: some View {
        VStack(spacing: 6) {
            // 上段: メインゲージ + 数値パネル
            HStack(spacing: 10) {
                Link(destination: URL(string: "nolookbudget://dashboard")!) {
                    WidgetBudgetGaugeView(
                        totalAmount: entry.budgetTotal,
                        spentAmount: entry.budgetSpent,
                        usePercentageDisplay: entry.usePercentageDisplay
                    )
                    .frame(width: 70, height: 70)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("Orbit Budget")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.bottom, 4)

                    HStack(spacing: 16) {
                        if entry.usePercentageDisplay {
                            let spentRatio = entry.budgetTotal > 0 ? (entry.budgetSpent / entry.budgetTotal) : 0
                            let remainRatio = max(1.0 - spentRatio, 0)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("残り")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("\(Int(remainRatio * 100))%")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundColor(Theme.spaceGreen)
                                    .shadow(color: Theme.spaceGreen.opacity(0.5), radius: 3)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text("使用済")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("\(Int(spentRatio * 100))%")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundColor(Theme.coralRed)
                                    .shadow(color: Theme.coralRed.opacity(0.5), radius: 4)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("手取り総額")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("¥\(Int(entry.budgetTotal))")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.4), radius: 3)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text("使用済")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("¥\(Int(entry.budgetSpent))")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.coralRed)
                                    .shadow(color: Theme.coralRed.opacity(0.5), radius: 4)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)

            // 区切り線
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5)
                .padding(.horizontal, 14)

            // 下段: カテゴリ横バー（最大4件）
            VStack(spacing: 4) {
                ForEach(topCategories, id: \.name) { cat in
                    Link(destination: URL(
                        string: "nolookbudget://category/\(cat.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"
                    )!) {
                        MediumCategoryBarView(category: cat, usePercentageDisplay: entry.usePercentageDisplay)
                    }
                }
            }
            .padding(.horizontal, 14)

            Spacer(minLength: 0)
        }
        .padding(.top, 14)
        .padding(.bottom, 8)
    }
}

// MARK: - Medium用カテゴリ横バー

struct MediumCategoryBarView: View {
    let category: CategoryData
    var usePercentageDisplay: Bool = false

    private var barColor: Color {
        if category.ratio >= 1.0 { return Theme.coralRed }
        if category.ratio > 0.5 { return Theme.warmOrange }
        return Theme.spaceGreen
    }

    private var amountString: String {
        category.amount < 0 ? "-¥\(-category.amount)" : "¥\(category.amount)"
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(category.name)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 36, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    Capsule()
                        .fill(barColor)
                        .frame(
                            width: max(geo.size.width * min(max(CGFloat(category.ratio), 0), 1), 4),
                            height: 6
                        )
                        .shadow(color: barColor.opacity(0.4), radius: 3)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 12)

            if usePercentageDisplay {
                let remainPercent = max(Int((1.0 - category.ratio) * 100), 0)
                Text("\(remainPercent)%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(barColor)
                    .frame(width: 50, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            } else {
                Text(amountString)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(barColor)
                    .frame(width: 50, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }
}

// MARK: - Widget Configuration

struct NoLookBudgetWidget: Widget {
    let kind: String = "NoLookBudgetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                NoLookBudgetWidgetRouter(entry: entry)
                    .containerBackground(for: .widget) {
                        // 星空背景（アプリ本体と統一・ここだけで管理）
                        Image("starfield_background")
                            .resizable()
                            .scaledToFill()
                    }
            } else {
                NoLookBudgetWidgetRouter(entry: entry)
                    .background(
                        Image("starfield_background")
                            .resizable()
                            .scaledToFill()
                    )
            }
        }
        .configurationDisplayName("Orbit Budget")
        .description("常に予算の一覧をホーム画面で確認できます。")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Widget用 UIコンポーネント

struct WidgetBudgetGaugeView: View {
    let totalAmount: Double
    let spentAmount: Double
    var usePercentageDisplay: Bool = false

    var remainingAmount: Double { totalAmount - spentAmount }

    var remainingColor: Color {
        let ratio = totalAmount > 0 ? (spentAmount / totalAmount) : 0
        if ratio > 0.8 { return Theme.coralRed }
        if ratio > 0.5 { return Theme.warmOrange }
        return Theme.spaceGreen
    }

    var body: some View {
        ZStack {
            // ガラス背景
            Circle().fill(Color.black.opacity(0.4)).blur(radius: 4)

            // ベースストローク
            Circle()
                .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 20, lineCap: .butt))
                .rotationEffect(.degrees(-90))

            let spentRatio = totalAmount > 0 ? (spentAmount / totalAmount) : 0.0
            let clampedRatio = min(max(spentRatio, 0), 1)

            // 使用済みグラデーション
            // startAngle:0°(3時) → rotationEffect(-90°) → 12時開始に補正
            Circle()
                .trim(from: 0, to: clampedRatio)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Theme.warmOrange, Theme.coralRed]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))

            // 残高（緑）
            if clampedRatio < 1.0 {
                Circle()
                    .trim(from: clampedRatio + 0.008, to: 1)
                    .stroke(Theme.safeGradient, style: StrokeStyle(lineWidth: 20, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }

            // 中央テキスト
            VStack(spacing: 1) {
                Text("残り")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                if usePercentageDisplay {
                    let remainRatio = totalAmount > 0 ? max((totalAmount - spentAmount) / totalAmount, 0) : 0
                    Text("\(Int(remainRatio * 100))%")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(remainingColor)
                        .shadow(color: remainingColor.opacity(0.5), radius: 4)
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                } else {
                    Text("¥\(Int(remainingAmount))")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(remainingColor)
                        .shadow(color: remainingColor.opacity(0.5), radius: 4)
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 20)
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

struct WidgetCategoryGaugeView: View {
    let name: String
    let amount: Int
    let ratio: Double
    var usePercentageDisplay: Bool = false
    var compact: Bool = false

    var amountColor: Color {
        if ratio >= 1.0 { return Theme.coralRed }
        else if ratio > 0.5 { return Theme.warmOrange }
        else { return Theme.spaceGreen }
    }

    var amountString: String { amount < 0 ? "-¥\(-amount)" : "¥\(amount)" }

    /// パーセント表示用の文字列（残りパーセント）
    var percentageString: String {
        let remainPercent = max(Int((1.0 - ratio) * 100), 0)
        return "\(remainPercent)%"
    }

    private var lineWidth: CGFloat { compact ? 6 : 9 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                .rotationEffect(.degrees(-90))

            let clampedRatio = min(max(ratio, 0), 1)

            Circle()
                .trim(from: 0, to: clampedRatio)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Theme.warmOrange, Theme.coralRed]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))

            if clampedRatio < 1.0 {
                Circle()
                    .trim(from: clampedRatio + 0.02, to: 1)
                    .stroke(Theme.safeGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: compact ? 1 : 2) {
                Text(name)
                    .font(.system(size: compact ? 8 : 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(usePercentageDisplay ? percentageString : amountString)
                    .font(.system(size: compact ? 10 : 13, weight: .bold))
                    .foregroundColor(amountColor)
                    .shadow(color: amountColor.opacity(0.4), radius: 3)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
            }
            .padding(.horizontal, compact ? 3 : 6)
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

#Preview("Large (6カテゴリ)", as: .systemLarge) {
    NoLookBudgetWidget()
} timeline: {
    SimpleEntry(date: .now, budgetTotal: 250000, budgetSpent: 100000, categories: [
        CategoryData(name: "食費", amount: 20000, ratio: 0.8),
        CategoryData(name: "交際費", amount: 15000, ratio: 0.4),
        CategoryData(name: "日用品", amount: 15000, ratio: 0.1),
        CategoryData(name: "趣味・娯楽", amount: 10000, ratio: 0.3),
        CategoryData(name: "交通費", amount: 8000, ratio: 0.5),
        CategoryData(name: "美容・衣服", amount: 12000, ratio: 0.6)
    ], usePercentageDisplay: false)
}

#Preview("Large (9カテゴリ/Premium)", as: .systemLarge) {
    NoLookBudgetWidget()
} timeline: {
    SimpleEntry(date: .now, budgetTotal: 250000, budgetSpent: 100000, categories: [
        CategoryData(name: "食費", amount: 20000, ratio: 0.8),
        CategoryData(name: "交際費", amount: 15000, ratio: 0.4),
        CategoryData(name: "日用品", amount: 15000, ratio: 0.1),
        CategoryData(name: "趣味・娯楽", amount: 10000, ratio: 0.3),
        CategoryData(name: "交通費", amount: 8000, ratio: 0.5),
        CategoryData(name: "美容・衣服", amount: 12000, ratio: 0.6),
        CategoryData(name: "教育費", amount: 5000, ratio: 0.2),
        CategoryData(name: "ポーカー", amount: 3000, ratio: 0.9),
        CategoryData(name: "ペット", amount: 7000, ratio: 0.4)
    ], usePercentageDisplay: false)
}

#Preview("Large (% 表示)", as: .systemLarge) {
    NoLookBudgetWidget()
} timeline: {
    SimpleEntry(date: .now, budgetTotal: 250000, budgetSpent: 100000, categories: [
        CategoryData(name: "食費", amount: 20000, ratio: 0.8),
        CategoryData(name: "交際費", amount: 15000, ratio: 0.4),
        CategoryData(name: "変動費", amount: 15000, ratio: 0.1)
    ], usePercentageDisplay: true)
}

#Preview("Medium", as: .systemMedium) {
    NoLookBudgetWidget()
} timeline: {
    SimpleEntry(date: .now, budgetTotal: 250000, budgetSpent: 100000, categories: [
        CategoryData(name: "食費", amount: 20000, ratio: 0.8),
        CategoryData(name: "交際費", amount: 15000, ratio: 0.4),
        CategoryData(name: "日用品", amount: 15000, ratio: 0.1),
        CategoryData(name: "趣味", amount: 8000, ratio: 0.6)
    ], usePercentageDisplay: false)
}

#Preview("Medium (% 表示)", as: .systemMedium) {
    NoLookBudgetWidget()
} timeline: {
    SimpleEntry(date: .now, budgetTotal: 250000, budgetSpent: 100000, categories: [
        CategoryData(name: "食費", amount: 20000, ratio: 0.8),
        CategoryData(name: "交際費", amount: 15000, ratio: 0.4),
        CategoryData(name: "日用品", amount: 15000, ratio: 0.1),
        CategoryData(name: "趣味", amount: 8000, ratio: 0.6)
    ], usePercentageDisplay: true)
}
