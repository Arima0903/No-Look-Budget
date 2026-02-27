import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct NoLookBudgetWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.13, blue: 0.14)
            
            VStack(spacing: 8) {
                Spacer() // 上部からの余白を少し増やすための柔軟なスペーサー
                
                // Main Gauge (Responsive size) - Tap to Open Dashboard
                Link(destination: URL(string: "nolookbudget://dashboard")!) {
                    WidgetBudgetGaugeView(totalAmount: 250000, spentAmount: 100000)
                        .frame(height: 110)
                }
                
                // Categories - Tap to Open specific Category
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 8) {
                    Link(destination: URL(string: "nolookbudget://category/\("食費".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")")!) {
                        WidgetCategoryGaugeView(name: "食費", amount: 20000, ratio: 0.8)
                    }
                    Link(destination: URL(string: "nolookbudget://category/\("交際費".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")")!) {
                        WidgetCategoryGaugeView(name: "交際費", amount: 15000, ratio: 0.4)
                    }
                    Link(destination: URL(string: "nolookbudget://category/\("変動費".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")")!) {
                        WidgetCategoryGaugeView(name: "変動費", amount: 15000, ratio: 0.1)
                    }
                    Link(destination: URL(string: "nolookbudget://category/\("変動費 A".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")")!) {
                        WidgetCategoryGaugeView(name: "変動費 A", amount: 10000, ratio: 0.5)
                    }
                    Link(destination: URL(string: "nolookbudget://category/\("変動費 B".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")")!) {
                        WidgetCategoryGaugeView(name: "変動費 B", amount: 8000, ratio: 0.2)
                    }
                    Link(destination: URL(string: "nolookbudget://category/\("変動費 C".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")")!) {
                        WidgetCategoryGaugeView(name: "変動費 C", amount: -5000, ratio: 1.33)
                    }
                }
                .padding(.horizontal, 25) // 左右の余白を増やしてコンパクトに
                
                Spacer().frame(height: 15) // 下部の余白を確保して全体を少し上に押し上げるバランス調整
            }
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
            Circle()
                .stroke(Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.3), style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            
            let spentRatio = totalAmount > 0 ? (spentAmount / totalAmount) : 0.4
            let clampedRatio = min(max(spentRatio, 0), 1)
            
            Circle()
                .trim(from: 0, to: clampedRatio)
                .stroke(Color(red: 0.9, green: 0.4, blue: 0.4), style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            
            Circle()
                .trim(from: clampedRatio, to: 1)
                .stroke(Color(red: 0.4, green: 0.9, blue: 0.6), style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            
            // ゲージ内のテキストが被らないようにサイズと横幅の制限を付ける
            VStack(spacing: 4) {
                Text("REMAINING")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.gray)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("¥\(Int(remainingAmount))")
                    .font(.system(size: 22, weight: .black))
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
        if ratio >= 1.0 { return Color(red: 0.9, green: 0.4, blue: 0.4) }
        else if ratio > 0.5 { return Color.yellow }
        else { return Color(red: 0.4, green: 0.9, blue: 0.6) }
    }
    
    var amountString: String { amount < 0 ? "-¥\(-amount)" : "¥\(amount)" }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.3), lineWidth: 10)
                .rotationEffect(.degrees(-90))
            
            let clampedRatio = min(max(ratio, 0), 1)
            
            Circle()
                .trim(from: 0, to: clampedRatio)
                .stroke(Color(red: 0.9, green: 0.4, blue: 0.4), style: StrokeStyle(lineWidth: 10, lineCap: .butt)) // 一律で赤色に統一
                .rotationEffect(.degrees(-90))
            
            Circle()
                .trim(from: clampedRatio, to: 1)
                .stroke(Color(red: 0.4, green: 0.9, blue: 0.6), style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 2) {
                Text(name)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.gray)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(amountString)
                    .font(.system(size: 11, weight: .bold))
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
    SimpleEntry(date: .now)
}
