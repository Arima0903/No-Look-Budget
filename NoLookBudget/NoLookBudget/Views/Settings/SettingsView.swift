import SwiftUI
import SwiftData
import WidgetKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderHour") private var reminderHour = 21
    @State private var themeSelection = 0 // 0: Auto, 1: Dark, 2: Light
    @State private var hapticEnabled = true
    @State private var showPaywall = false

    @AppStorage("isPremiumEnabled") private var isPremiumEnabled = false
    @AppStorage("widgetPercentageDisplay") private var widgetPercentageDisplay = false

    var body: some View {
        NavigationStack {
            Form {
                // プレミアムセクション
                Section {
                    Button(action: {
                        showPaywall = true
                    }) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            VStack(alignment: .leading) {
                                Text(isPremiumEnabled ? "Premium アクティブ" : "Orbit Budget Premium")
                                    .fontWeight(.bold)
                                    .foregroundColor(isPremiumEnabled ? .yellow : .white)
                                Text("カスタムカテゴリ・借金の分割・高度な管理")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))

                // ウィジェット設定（プレミアム機能）
                if isPremiumEnabled {
                    Section(header: Text("ウィジェット設定").foregroundColor(.gray)) {
                        Toggle(isOn: $widgetPercentageDisplay) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("金額をパーセント表示にする")
                                    .foregroundColor(.white)
                                Text("ウィジェット上の金額を非表示にし、予算消化率（%）のみ表示します")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .tint(.yellow)
                        .onChange(of: widgetPercentageDisplay) { _, _ in
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }

                // 通知設定
                Section(header: Text("通知設定").foregroundColor(.gray)) {
                    Toggle(isOn: $notificationsEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("通知")
                                .foregroundColor(.white)
                            Text("毎日のリマインダー・月末レポート・予算警告を通知します")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .tint(.yellow)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        if newValue {
                            NotificationService.rescheduleAll()
                        } else {
                            NotificationService.cancelAll()
                        }
                    }

                    if notificationsEnabled {
                        HStack {
                            Text("リマインダー時刻")
                                .foregroundColor(.white)
                            Spacer()
                            Picker("", selection: $reminderHour) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text("\(hour):00").tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.yellow)
                            .onChange(of: reminderHour) { _, newHour in
                                NotificationService.scheduleDailyReminder(hour: newHour, minute: 0)
                            }
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))

                // 体験とシステム
                Section(header: Text("システム設定").foregroundColor(.gray)) {
                    Toggle("触覚フィードバック（振動）", isOn: $hapticEnabled)
                        .tint(.yellow)
                }
                .listRowBackground(Color.white.opacity(0.05))

                #if DEBUG
                // デバッグ用
                Section(header: Text("デバッグ・開発用").foregroundColor(.gray)) {
                    Toggle("Premiumフラグの強制切替", isOn: $isPremiumEnabled)
                        .tint(.yellow)
                        .onChange(of: isPremiumEnabled) { _, _ in
                            // プレミアム状態変更時にスナップショットを再生成してウィジェットを即時更新
                            WidgetDataManager.save(context: SharedModelContainer.shared.mainContext)
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                }
                .listRowBackground(Color.white.opacity(0.05))
                #endif

                // サポート・その他
                Section(header: Text("その他").foregroundColor(.gray)) {
                    NavigationLink(destination: UsageGuideView()) {
                        Label("使い方・ウィジェットの置き方", systemImage: "questionmark.circle")
                            .foregroundColor(.white)
                    }
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Label("プライバシーポリシー", systemImage: "lock.shield")
                            .foregroundColor(.white)
                    }
                    NavigationLink(destination: TermsOfServiceView()) {
                        Label("利用規約", systemImage: "doc.text")
                            .foregroundColor(.white)
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))

                // バージョン情報
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 5) {
                            Text("Orbit Budget")
                                .font(.footnote.bold())
                                .foregroundColor(.gray)
                            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("設定")
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.1, green: 0.1, blue: 0.11).ignoresSafeArea())
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                        .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        // 通知設定を反映
                        if notificationsEnabled {
                            NotificationService.rescheduleAll()
                        } else {
                            NotificationService.cancelAll()
                        }
                        // ウィジェットスナップショットを再生成して即時更新
                        WidgetDataManager.save(context: SharedModelContainer.shared.mainContext)
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
        .accessibilityIdentifier("settingsView")
    }
}

#Preview {
    SettingsView()
}
