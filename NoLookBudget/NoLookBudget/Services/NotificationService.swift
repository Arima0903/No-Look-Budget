import Foundation
import UserNotifications

// MARK: - ローカル通知管理サービス
// UNUserNotificationCenter を使用して各種リマインダー・警告通知を管理する

@MainActor
enum NotificationService {

    // MARK: - 通知識別子

    private enum Identifier {
        static let dailyReminder = "daily_reminder"
        static let monthlyReview = "monthly_review"
        static let budgetWarning = "budget_warning"
        static let budgetOver = "budget_over"
        static let weeklyIOU = "weekly_iou_reminder"
        static let inactivity = "inactivity_reminder"
    }

    // MARK: - UserDefaults キー

    private enum DefaultsKey {
        static let notificationsEnabled = "notificationsEnabled"
        static let reminderHour = "reminderHour"
        static let reminderMinute = "reminderMinute"
    }

    // MARK: - デフォルト値

    private static let defaultReminderHour = 21
    private static let defaultReminderMinute = 0

    // MARK: - ヘルパー

    private static var center: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }

    private static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: DefaultsKey.notificationsEnabled)
    }

    private static var reminderHour: Int {
        let hour = UserDefaults.standard.integer(forKey: DefaultsKey.reminderHour)
        // UserDefaults の integer はキーが存在しない場合 0 を返すため、
        // 0 かつ明示的に設定されていない場合はデフォルト値を使用
        if hour == 0 && UserDefaults.standard.object(forKey: DefaultsKey.reminderHour) == nil {
            return defaultReminderHour
        }
        return hour
    }

    private static var reminderMinute: Int {
        let minute = UserDefaults.standard.integer(forKey: DefaultsKey.reminderMinute)
        if minute == 0 && UserDefaults.standard.object(forKey: DefaultsKey.reminderMinute) == nil {
            return defaultReminderMinute
        }
        return minute
    }

    // MARK: - 1. 通知許可を要求

    /// ユーザーに通知許可を求める。許可された場合は UserDefaults に有効フラグを保存する。
    static func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            UserDefaults.standard.set(granted, forKey: DefaultsKey.notificationsEnabled)
            return granted
        } catch {
            print("[NotificationService] 通知許可リクエスト失敗: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - 2. 毎日のリマインダー

    /// 毎日指定時刻に記録リマインダーを通知する
    static func scheduleDailyReminder(hour: Int, minute: Int) {
        guard isEnabled else { return }

        // 既存の通知を削除してから再登録
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.dailyReminder])

        let content = UNMutableNotificationContent()
        content.title = "今日の支出を記録しましょう"
        content.body = "まだ今日の記録がありません。サッと入力して把握しておきましょう。"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.dailyReminder,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("[NotificationService] デイリーリマインダー登録失敗: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 3. 月次レビュー通知

    /// 毎月1日 9:00 に月次レポートの確認を促す通知
    static func scheduleMonthlyReviewNotification() {
        guard isEnabled else { return }

        center.removePendingNotificationRequests(withIdentifiers: [Identifier.monthlyReview])

        let content = UNMutableNotificationContent()
        content.title = "月次レポートが届きました"
        content.body = "先月の支出を振り返りましょう。改善ポイントが見つかるかもしれません。"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.monthlyReview,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("[NotificationService] 月次レビュー通知登録失敗: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 4. 予算警告通知（80%消費時）

    /// 予算の80%を消費した際に1回だけ警告通知を送る
    /// - Parameter remainingAmount: 残り予算額（円）
    static func scheduleBudgetWarning(remainingAmount: Int) {
        guard isEnabled else { return }

        center.removePendingNotificationRequests(withIdentifiers: [Identifier.budgetWarning])

        let content = UNMutableNotificationContent()
        content.title = "予算残り20%です"
        content.body = "残り \(remainingAmount.formatted())円 です。ペースに気をつけましょう。"
        content.sound = .default

        // 即時配信（1秒後）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: Identifier.budgetWarning,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("[NotificationService] 予算警告通知登録失敗: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 5. 予算オーバー通知

    /// 予算をオーバーした際に1回だけ通知を送る
    static func scheduleBudgetOverNotification() {
        guard isEnabled else { return }

        center.removePendingNotificationRequests(withIdentifiers: [Identifier.budgetOver])

        let content = UNMutableNotificationContent()
        content.title = "予算オーバーしました"
        content.body = "今月の予算を超過しました。支出を見直しましょう。"
        content.sound = .default

        // 即時配信（1秒後）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: Identifier.budgetOver,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("[NotificationService] 予算オーバー通知登録失敗: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 6. 毎週月曜のIOU未回収リマインダー

    /// 毎週月曜 10:00 に未回収の立替金がある場合に通知する
    /// - Parameter amount: 未回収総額（円）
    static func scheduleWeeklyIOUReminder(amount: Int) {
        guard isEnabled else { return }

        center.removePendingNotificationRequests(withIdentifiers: [Identifier.weeklyIOU])

        let content = UNMutableNotificationContent()
        content.title = "未回収の立替金があります"
        content.body = "合計 \(amount.formatted())円 の立替金が未回収です。回収を忘れずに。"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // 月曜日
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.weeklyIOU,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("[NotificationService] IOU週次リマインダー登録失敗: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 7. 72時間未利用リマインダー

    /// アプリを72時間利用していない場合にリマインダーを送る
    static func scheduleInactivityReminder() {
        guard isEnabled else { return }

        center.removePendingNotificationRequests(withIdentifiers: [Identifier.inactivity])

        let content = UNMutableNotificationContent()
        content.title = "最近記録していませんよ"
        content.body = "3日間記録がありません。サッと今日の支出を入力しましょう。"
        content.sound = .default

        // 72時間 = 259200秒
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 259200, repeats: false)
        let request = UNNotificationRequest(
            identifier: Identifier.inactivity,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("[NotificationService] 未利用リマインダー登録失敗: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 8. 全通知キャンセル

    /// 全ての保留中通知をキャンセルする
    static func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: - 9. 有効な通知を全て再スケジュール

    /// 現在の設定に基づいて、繰り返し系の通知を全て再登録する。
    /// アプリ起動時や設定変更時に呼び出す。
    static func rescheduleAll() {
        // 一旦全てキャンセル
        cancelAll()

        guard isEnabled else { return }

        // デイリーリマインダー
        scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)

        // 月次レビュー通知
        scheduleMonthlyReviewNotification()

        // 未利用リマインダー（アプリ起動時にリセット）
        scheduleInactivityReminder()
    }
}
