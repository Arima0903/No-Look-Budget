import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 共有データ構造（ホーム画面・ロック画面共通）

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
    var hideNumbers: Bool = false  // ロック画面プライバシーオプション
}

// MARK: - 共有 Provider（ホーム画面・ロック画面共通）

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), budgetTotal: 250000, budgetSpent: 100000, categories: [
            CategoryData(name: "食費", amount: 20000, ratio: 0.8),
            CategoryData(name: "交際費", amount: 15000, ratio: 0.4)
        ])
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
        let budgetKey = "widget_budget_snapshot_v1"
        let hideKey = "lockScreen_hide_numbers"

        guard
            let defaults = UserDefaults(suiteName: suiteName),
            let data = defaults.data(forKey: budgetKey)
        else {
            return SimpleEntry(date: Date(), budgetTotal: 0, budgetSpent: 0, categories: [])
        }

        struct Snapshot: Decodable {
            let budgetTotal: Double
            let budgetSpent: Double
            let categories: [CategorySnapshot]
        }
        struct CategorySnapshot: Decodable {
            let name: String
            let remainingAmount: Int
            let ratio: Double
        }

        guard let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return SimpleEntry(date: Date(), budgetTotal: 0, budgetSpent: 0, categories: [])
        }

        let mappedCategories = snapshot.categories.map {
            CategoryData(name: $0.name, amount: $0.remainingAmount, ratio: $0.ratio)
        }
        let hideNumbers = defaults.bool(forKey: hideKey)

        return SimpleEntry(
            date: Date(),
            budgetTotal: snapshot.budgetTotal,
            budgetSpent: snapshot.budgetSpent,
            categories: mappedCategories,
            hideNumbers: hideNumbers
        )
    }
}

// MARK: - ホーム画面ウィジェット ビュー

struct NoLookBudgetWidgetEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack(spacing: 10) {

            // ── 上半分: メインゲージ + 数値 ──
            HStack(spacing: 10) {
                // 左: 全体予算円グラフ
                Link(destination: URL(string: "nolookbudget://dashboard")!) {
                    WidgetBudgetGaugeView(
                        totalAmount: entry.budgetTotal,
                        spentAmount: entry.budgetSpent
                    )
                    .frame(width: 110, height: 110)
                }

                // 右: 数値ブロック（ガラスパネル）
                VStack(alignment: .leading, spacing: 0) {
                    Text("NoLookBudget")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.bottom, 6)

                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("手取り総額")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.65))
                            Text("¥\(Int(entry.budgetTotal))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 3)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("使用済(固定費込)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.65))
                            Text("¥\(Int(entry.budgetSpent))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Theme.coralRed)
                                .shadow(color: Theme.coralRed.opacity(0.5), radius: 4)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.black.opacity(0.45))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                )
            }

            // 区切り線
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.5)

            // ── 下半分: カテゴリ一覧（ガラスパネル）──
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                spacing: 8
            ) {
                ForEach(entry.categories, id: \.name) { cat in
                    Link(destination: URL(
                        string: "nolookbudget://category/\(cat.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"
                    )!) {
                        WidgetCategoryGaugeView(name: cat.name, amount: cat.amount, ratio: cat.ratio)
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.38))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            )

            Spacer(minLength: 0)
        }
        .padding(.top, 24)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

// MARK: - ロック画面ウィジェット ビュー

/// ロック画面 横長矩形タイプ（accessoryRectangular）
struct LockScreenRectangularView: View {
    var entry: SimpleEntry

    var remainingAmount: Double { entry.budgetTotal - entry.budgetSpent }

    var remainingColor: Color {
        let ratio = entry.budgetTotal > 0 ? (entry.budgetSpent / entry.budgetTotal) : 0
        if ratio > 0.8 { return Theme.coralRed }
        if ratio > 0.5 { return Theme.warmOrange }
        return Theme.spaceGreen
    }

    var body: some View {
        HStack(spacing: 10) {
            // 左: コンパクト円グラフ
            WidgetBudgetGaugeView(
                totalAmount: entry.budgetTotal,
                spentAmount: entry.budgetSpent,
                hideNumbers: entry.hideNumbers
            )
            .frame(width: 56, height: 56)

            // 右: 残額 + カテゴリ一覧
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("残り")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(entry.hideNumbers ? "--- ---" : "¥\(Int(remainingAmount))")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(remainingColor)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    ForEach(entry.categories.prefix(3), id: \.name) { cat in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(cat.name)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Text(entry.hideNumbers ? "--" : "¥\(cat.amount)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(
                                    cat.ratio >= 1.0 ? Theme.coralRed :
                                    cat.ratio > 0.5 ? Theme.warmOrange :
                                    Theme.spaceGreen
                                )
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                        if cat.name != entry.categories.prefix(3).last?.name {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 0.5, height: 20)
                        }
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// ロック画面 円形タイプ（accessoryCircular）
struct LockScreenCircularView: View {
    var entry: SimpleEntry

    var body: some View {
        WidgetBudgetGaugeView(
            totalAmount: entry.budgetTotal,
            spentAmount: entry.budgetSpent,
            hideNumbers: entry.hideNumbers
        )
    }
}

// MARK: - Widget Configurations

struct NoLookBudgetWidget: Widget {
    let kind: String = "NoLookBudgetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                NoLookBudgetWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        // 星空背景（アプリ本体と統一・ここだけで管理）
                        Image("starfield_background")
                            .resizable()
                            .scaledToFill()
                    }
            } else {
                NoLookBudgetWidgetEntryView(entry: entry)
                    .background(
                        Image("starfield_background")
                            .resizable()
                            .scaledToFill()
                    )
            }
        }
        .configurationDisplayName("No-Look-Budget")
        .description("常に予算の一覧をホーム画面で確認できます。")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}

/// ロック画面ウィジェット エントリービュー（familyに応じてレイアウト切替）
struct LockScreenWidgetEntryView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            LockScreenCircularView(entry: entry)
        default:
            LockScreenRectangularView(entry: entry)
        }
    }
}

/// ロック画面専用ウィジェット（Premium機能）
struct NoLookBudgetLockScreenWidget: Widget {
    let kind: String = "NoLookBudgetLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                LockScreenWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) { Color.clear }
            } else {
                LockScreenRectangularView(entry: entry)
            }
        }
        .configurationDisplayName("No-Look-Budget（ロック画面）")
        .description("ロック画面で予算残額をすばやく確認。Premium限定機能。")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
    }
}

// MARK: - Widget用 UIコンポーネント（ホーム・ロック画面共通）

struct WidgetBudgetGaugeView: View {
    let totalAmount: Double
    let spentAmount: Double
    var hideNumbers: Bool = false  // ロック画面プライバシーオプション

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
                if hideNumbers {
                    Text("---")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(remainingColor)
                        .minimumScaleFactor(0.5)
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

    var amountColor: Color {
        if ratio >= 1.0 { return Theme.coralRed }
        else if ratio > 0.5 { return Theme.warmOrange }
        else { return Theme.spaceGreen }
    }

    var amountString: String { amount < 0 ? "-¥\(-amount)" : "¥\(amount)" }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 9, lineCap: .butt))
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
                    style: StrokeStyle(lineWidth: 9, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))

            if clampedRatio < 1.0 {
                Circle()
                    .trim(from: clampedRatio + 0.02, to: 1)
                    .stroke(Theme.safeGradient, style: StrokeStyle(lineWidth: 9, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 2) {
                Text(name)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(amountString)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(amountColor)
                    .shadow(color: amountColor.opacity(0.4), radius: 3)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

// MARK: - Previews

#Preview("ホーム画面", as: .systemLarge) {
    NoLookBudgetWidget()
} timeline: {
    SimpleEntry(date: .now, budgetTotal: 250000, budgetSpent: 100000, categories: [
        CategoryData(name: "食費", amount: 20000, ratio: 0.8),
        CategoryData(name: "交際費", amount: 15000, ratio: 0.4),
        CategoryData(name: "変動費", amount: 15000, ratio: 0.1)
    ])
}

#Preview("ロック画面 横長", as: .accessoryRectangular) {
    NoLookBudgetLockScreenWidget()
} timeline: {
    SimpleEntry(date: .now, budgetTotal: 250000, budgetSpent: 100000, categories: [
        CategoryData(name: "食費", amount: 20000, ratio: 0.8),
        CategoryData(name: "交際費", amount: 15000, ratio: 0.4),
        CategoryData(name: "変動費", amount: 15000, ratio: 0.1)
    ])
}

#Preview("ロック画面 円形", as: .accessoryCircular) {
    NoLookBudgetLockScreenWidget()
} timeline: {
    SimpleEntry(date: .now, budgetTotal: 250000, budgetSpent: 100000, categories: [])
}
