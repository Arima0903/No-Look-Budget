import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var notificationsEnabled = true
    @State private var themeSelection = 0 // 0: Auto, 1: Dark, 2: Light
    @State private var hapticEnabled = true
    @State private var showPaywall = false
    @State private var lockScreenHideNumbers = false

    @AppStorage("isPremiumEnabled") private var isPremiumEnabled = false

    private let appGroupSuite = "group.com.arima0903.NoLookBudget"
    private let hideNumbersKey = "lockScreen_hide_numbers"
    
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
                                Text(isPremiumEnabled ? "Premium アクティブ" : "No-Look-Budget Premium")
                                    .fontWeight(.bold)
                                    .foregroundColor(isPremiumEnabled ? .yellow : .white)
                                Text("借金の分割・さらに高度な管理")
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
                
                // 体験とシステム
                Section(header: Text("システム設定").foregroundColor(.gray)) {
                    Toggle("通知（月末の借金警告など）", isOn: $notificationsEnabled)
                        .tint(.yellow)
                    Toggle("触覚フィードバック（振動）", isOn: $hapticEnabled)
                        .tint(.yellow)
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                #if DEBUG
                // デバッグ用
                Section(header: Text("デバッグ・開発用").foregroundColor(.gray)) {
                    Toggle("Premiumフラグの強制切替", isOn: $isPremiumEnabled)
                        .tint(.yellow)
                }
                .listRowBackground(Color.white.opacity(0.05))
                #endif
                
                // ロック画面ウィジェット設定（Premium）
                Section(header: Text("ロック画面ウィジェット").foregroundColor(.gray)) {
                    HStack {
                        Toggle("数値をプライベートモードにする", isOn: isPremiumEnabled ? $lockScreenHideNumbers : .constant(false))
                            .tint(.yellow)
                            .disabled(!isPremiumEnabled)
                            .onChange(of: lockScreenHideNumbers) { _, newValue in
                                guard isPremiumEnabled else { return }
                                UserDefaults(suiteName: appGroupSuite)?.set(newValue, forKey: hideNumbersKey)
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        if !isPremiumEnabled {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                    }
                    if !isPremiumEnabled {
                        Text("Premiumプランで利用可能。ロック画面に表示する数値を隠します。")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))

                // サポート・その他
                Section(header: Text("その他").foregroundColor(.gray)) {
                    NavigationLink("使い方・ウィジェットの置き方", destination: Text("Guide"))
                    NavigationLink("プライバシーポリシー", destination: Text("Privacy"))
                    NavigationLink("利用規約", destination: Text("Terms"))
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                // バージョン情報
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 5) {
                            Text("No-Look-Budget")
                                .font(.footnote.bold())
                                .foregroundColor(.gray)
                            Text("Version 1.0.0")
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
                        .foregroundColor(.yellow)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear {
                // App Group から設定値を読み込む
                lockScreenHideNumbers = UserDefaults(suiteName: appGroupSuite)?.bool(forKey: hideNumbersKey) ?? false
            }
        }
    }
}

#Preview {
    SettingsView()
}
