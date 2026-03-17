import SwiftUI

// MARK: - 月別カレンダービュー
// DashboardView の円グラフを右にスワイプすると表示されるカレンダー。
// 1日ごとの支出合計を確認できる。

struct CalendarView: View {
    let budget: Budget?
    let dailySpending: [Int: Double]  // 日付(1〜31) → 合計支出

    private let calendar = Calendar.current
    private let weekDaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    private var today: Date { Date() }

    /// 表示対象月（予算の月、なければ今月）
    private var targetMonth: Date {
        budget?.month ?? today
    }

    /// その月の1日
    private var startOfMonth: Date {
        let comps = calendar.dateComponents([.year, .month], from: targetMonth)
        return calendar.date(from: comps) ?? today
    }

    /// その月の日数
    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30
    }

    /// 月の最初の曜日オフセット（日曜=0）
    private var firstWeekdayOffset: Int {
        (calendar.component(.weekday, from: startOfMonth) - 1 + 7) % 7
    }

    /// 月の合計支出
    private var totalMonthSpending: Double {
        dailySpending.values.reduce(0, +)
    }

    /// 日別の最大支出（ゲージ表示のスケーリング用）
    private var maxDailySpending: Double {
        dailySpending.values.max() ?? 1
    }

    var body: some View {
        VStack(spacing: 12) {
            // ヘッダー: 月表示 + 合計支出
            HStack {
                Text(monthTitle)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("今月の合計支出")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("¥\(Int(totalMonthSpending))")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.coralRed)
                }
            }
            .padding(.horizontal, 4)

            // 曜日ヘッダー
            HStack(spacing: 0) {
                ForEach(weekDaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(symbol == "日" ? Theme.coralRed.opacity(0.8) : .gray)
                        .frame(maxWidth: .infinity)
                }
            }

            // カレンダーグリッド
            let totalCells = firstWeekdayOffset + daysInMonth
            let rows = Int(ceil(Double(totalCells) / 7.0))

            VStack(spacing: 4) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { col in
                            let cellIndex = row * 7 + col
                            let day = cellIndex - firstWeekdayOffset + 1

                            if day < 1 || day > daysInMonth {
                                // 空白セル
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1.0, contentMode: .fit)
                            } else {
                                CalendarDayCell(
                                    day: day,
                                    spending: dailySpending[day] ?? 0,
                                    maxSpending: maxDailySpending,
                                    isToday: isToday(day: day),
                                    isSunday: col == 0
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: targetMonth)
    }

    private func isToday(day: Int) -> Bool {
        let todayComps = calendar.dateComponents([.year, .month, .day], from: today)
        let targetComps = calendar.dateComponents([.year, .month], from: targetMonth)
        return todayComps.year == targetComps.year &&
               todayComps.month == targetComps.month &&
               todayComps.day == day
    }
}

// MARK: - 日付セル

private struct CalendarDayCell: View {
    let day: Int
    let spending: Double
    let maxSpending: Double
    let isToday: Bool
    let isSunday: Bool

    /// 支出比率（0〜1）: 最大支出日を基準にスケール
    private var spendingRatio: Double {
        guard maxSpending > 0 else { return 0 }
        return min(spending / maxSpending, 1.0)
    }

    /// 支出レベルで色を変える（Astronautテーマ準拠）
    private var spendingColor: Color {
        if spending <= 0 { return .clear }
        if spendingRatio > 0.7 { return Theme.coralRed.opacity(0.7) }
        if spendingRatio > 0.4 { return Theme.warmOrange.opacity(0.6) }
        return Theme.spaceGreen.opacity(0.5)
    }

    var body: some View {
        VStack(spacing: 1) {
            // 日付数字
            Text("\(day)")
                .font(.system(size: 10, weight: isToday ? .black : .regular, design: .rounded))
                .foregroundColor(isToday ? .black : (isSunday ? Theme.coralRed.opacity(0.8) : .white.opacity(0.8)))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isToday ? Theme.spaceGreen : (spending > 0 ? spendingColor : Color.white.opacity(0.04)))
                )

            // 支出額（あれば表示）
            if spending > 0 {
                Text("¥\(formatAmount(spending))")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                // 支出なし（未記録）: 小さなドットで視覚的に区別
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 4, height: 4)
                    .frame(height: 11)  // 金額テキストと高さを揃える
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// 金額を短縮表示（1000以上は「1.2k」形式）
    private func formatAmount(_ amount: Double) -> String {
        if amount >= 10000 {
            return "\(Int(amount / 1000))k"
        } else if amount >= 1000 {
            return String(format: "%.1fk", amount / 1000)
        }
        return "\(Int(amount))"
    }
}

#Preview {
    ZStack {
        Theme.spaceNavy.ignoresSafeArea()
        CalendarView(
            budget: nil,
            dailySpending: [
                1: 2500, 3: 8000, 5: 15000, 7: 3200,
                10: 6000, 12: 22000, 15: 4500, 18: 9800,
                20: 1200, 22: 35000, 25: 7800, 28: 5600
            ]
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
