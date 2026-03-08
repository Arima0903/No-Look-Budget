import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var notificationsEnabled = true
    @State private var themeSelection = 0 // 0: Auto, 1: Dark, 2: Light
    @State private var hapticEnabled = true
    @State private var showPaywall = false
    
    @AppStorage("isPremiumEnabled") private var isPremiumEnabled = false
    
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
        }
    }
}

#Preview {
    SettingsView()
}
