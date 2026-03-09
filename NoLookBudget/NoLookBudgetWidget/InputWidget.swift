import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Input Widget Configuration
struct InputWidget: Widget {
    let kind: String = "NoLookBudgetInputWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InputWidgetProvider()) { entry in
            InputWidgetEntryView(entry: entry)
                .containerBackground(Theme.spaceNavy, for: .widget)
        }
        .configurationDisplayName("最速入力 (No-Look)")
        .description("Apple Payなどで支払った直後に、1タップで即座に金額を減らします。")
        .supportedFamilies([.systemLarge]) // 大きめのUIを想定
        .contentMarginsDisabled() // 画面いっぱいに広げる
    }
}

// MARK: - App Intent (バックグラウンド処理)
struct QuickExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "クイック支出"
    
    // 金額やカテゴリを持たせることができる（MVPでは額面のみとするなど）
    @Parameter(title: "金額")
    var amount: Int
    
    init() {}
    
    init(amount: Int) {
        self.amount = amount
    }

    func perform() async throws -> some IntentResult {
        // --- 実際のSwiftDataへの書き込み処理をここに記述（MVPモックではPrintのみ） ---
        print("ウィジェットから ¥\(amount) の支出が記録されました。")
        
        // 処理完了後、全ウィジェットに変更を通知してリロード（再描画）させる
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}

// MARK: - Provider
struct InputWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> InputWidgetEntry {
        InputWidgetEntry(date: Date(), remainingBudget: 150000)
    }

    func getSnapshot(in context: Context, completion: @escaping (InputWidgetEntry) -> ()) {
        let entry = InputWidgetEntry(date: Date(), remainingBudget: 150000)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // 実際にはここでSwiftData等から最新の残高を取得する
        let entry = InputWidgetEntry(date: Date(), remainingBudget: 150000)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct InputWidgetEntry: TimelineEntry {
    let date: Date
    let remainingBudget: Int // 現在の残高を上部に出すため
}

// MARK: - UI Widget View
struct InputWidgetEntryView: View {
    var entry: InputWidgetProvider.Entry

    var body: some View {
        VStack(spacing: 0) {
            // 上部：現在の全体残高をシンプルに表示
            VStack(spacing: 2) {
                Text("REMAINING")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                Text("¥\(entry.remainingBudget)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(Theme.spaceGreen)
            }
            .padding(.top, 15)
            .padding(.bottom, 10)
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.horizontal, 20)
            
            // 下部：クイック入力ボタン群（交互に配置するなどの工夫）
            VStack(spacing: 12) {
                Text("Tap to spend (食費)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
                
                // ボタン列1
                HStack(spacing: 15) {
                    QuickButton(amount: 500)
                    QuickButton(amount: 1000)
                    QuickButton(amount: 1500)
                }
                
                // ボタン列2
                HStack(spacing: 15) {
                    QuickButton(amount: 3000)
                    QuickButton(amount: 5000)
                    QuickButton(amount: 10000)
                }
            }
            .padding(.top, 5)
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

// AppIntentを呼び出すボタン部品
struct QuickButton: View {
    let amount: Int
    
    var body: some View {
        Button(intent: QuickExpenseIntent(amount: amount)) {
            Text("¥\(amount)")
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.spaceNavyLighter)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview(as: .systemLarge) {
    InputWidget()
} timeline: {
    InputWidgetEntry(date: .now, remainingBudget: 150000)
}
