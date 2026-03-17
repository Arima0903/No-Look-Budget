import Foundation
import SwiftData

/// ウィジェットへのデータ橋渡し管理クラス
///
/// SwiftData はクロスプロセス（メインアプリ ↔ Widget Extension）の
/// データ可視性を保証しないため、UserDefaults (App Group) を経由してデータを共有する。
/// - メインアプリ側: save() でデータを書き込む
/// - ウィジェット側: UserDefaults を直接読み込む
///
/// App Group ID: group.com.arima0903.NoLookBudget

// MARK: - 共有データ構造（Codable）

struct WidgetBudgetSnapshot: Codable {
    let budgetTotal: Double   // 手取り総額（incomeAmount ?? totalAmount）
    let budgetSpent: Double   // 使用済み（固定費込み）
    let categories: [WidgetCategorySnapshot]
}

struct WidgetCategorySnapshot: Codable {
    let name: String
    let remainingAmount: Int  // 残り予算（マイナスあり）
    let ratio: Double         // 使用率（0〜1）
}

// MARK: - 書き込みロジック（メインアプリ専用）

@MainActor
enum WidgetDataManager {
    private static let suiteName = "group.com.arima0903.NoLookBudget"
    private static let key = "widget_budget_snapshot_v1"

    /// TransactionService / ConfigurationViewModel の save 後に呼ぶ
    static func save(context: ModelContext) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }

        // 当月予算を取得
        let budgetDesc = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.month, order: .reverse)])
        let budgets = (try? context.fetch(budgetDesc)) ?? []
        let calendar = Calendar.current
        let currentYM = calendar.dateComponents([.year, .month], from: Date())
        let budget = budgets.first(where: {
            let c = calendar.dateComponents([.year, .month], from: $0.month)
            return c.year == currentYM.year && c.month == currentYM.month
        }) ?? budgets.first

        let displayTotal = budget?.incomeAmount ?? budget?.totalAmount ?? 0.0
        let fixedAndSavings = displayTotal - (budget?.totalAmount ?? 0.0)
        let budgetSpent = (budget?.spentAmount ?? 0.0) + fixedAndSavings

        // カテゴリ取得
        let catDesc = FetchDescriptor<ItemCategory>(sortBy: [SortDescriptor(\.orderIndex)])
        let cats = (try? context.fetch(catDesc)) ?? []
        let catSnapshots = cats.prefix(6).map {
            WidgetCategorySnapshot(
                name: $0.name,
                remainingAmount: Int($0.totalAmount - $0.spentAmount),
                ratio: $0.totalAmount > 0 ? ($0.spentAmount / $0.totalAmount) : 0.0
            )
        }

        let snapshot = WidgetBudgetSnapshot(
            budgetTotal: displayTotal,
            budgetSpent: budgetSpent,
            categories: Array(catSnapshots)
        )

        if let encoded = try? JSONEncoder().encode(snapshot) {
            defaults.set(encoded, forKey: key)
        }
    }

    /// ウィジェット側から呼ぶ読み込みメソッド（Widgetターゲットからも参照可）
    static func load() -> WidgetBudgetSnapshot? {
        guard
            let defaults = UserDefaults(suiteName: suiteName),
            let data = defaults.data(forKey: key),
            let snapshot = try? JSONDecoder().decode(WidgetBudgetSnapshot.self, from: data)
        else { return nil }
        return snapshot
    }
}
