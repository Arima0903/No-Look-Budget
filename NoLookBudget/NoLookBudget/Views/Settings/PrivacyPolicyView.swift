import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ZStack {
            Theme.spaceNavy.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    policyHeader(
                        title: "プライバシーポリシー",
                        updatedAt: "2026年3月17日"
                    )

                    // 個人情報非収集の宣言
                    policySection(
                        title: "個人情報の収集について",
                        body: "Orbit Budget（以下「本アプリ」）は、お客様の個人情報（氏名・住所・メールアドレス・電話番号など、特定の個人を識別できる情報）を一切収集しません。\n\nそのため、本アプリは個人情報保護法上の「個人情報取扱事業者」には該当しませんが、お客様のデータを適切に取り扱う観点から、本ポリシーを公開しています。\n\nお問い合わせ：App Store サポートページよりご連絡ください"
                    )

                    policySection(
                        title: "1. 保存するデータについて",
                        body: "本アプリはご利用にあたって以下のデータを端末内にのみ保存します。これらは個人を特定できない家計管理データです。\n\n• 予算・支出・カテゴリに関するデータ\n• アプリの設定情報（通知・テーマ等）\n\nこれらのデータはお客様のデバイス内（SwiftData）にのみ保存され、開発者を含む第三者が閲覧・取得することは一切できません。外部サーバーへの送信も行いません。\n\nApp Store を通じた課金・購入情報はApple Inc. が処理・管理します。開発者はお客様の決済情報に一切アクセスしません。"
                    )

                    policySection(
                        title: "2. データの利用目的",
                        body: "収集した情報は以下の目的にのみ使用します。\n\n• アプリの機能提供（予算管理・支出記録・ウィジェット表示）\n• アプリ体験の改善\n\n第三者へのデータ提供・販売は行いません。"
                    )

                    policySection(
                        title: "3. ウィジェットについて",
                        body: "ホーム画面ウィジェットへのデータ表示のため、App Group（group.com.arima0903.NoLookBudget）を使用して端末内でデータを共有します。この共有はお客様のデバイス内でのみ完結し、外部に送信されません。"
                    )

                    policySection(
                        title: "4. 第三者サービス",
                        body: "本アプリは現時点でアナリティクスツールや広告SDKを使用していません。\n\n将来的に第三者SDKを導入する場合は、事前にポリシーを更新するとともに、アプリ内でご通知し、必要に応じてお客様の再同意を取得します。再同意が得られない場合、該当する機能の利用を強制しません。"
                    )

                    policySection(
                        title: "5. データの保管と削除",
                        body: "すべてのデータはお客様のデバイス内にのみ保管されます。アプリを削除することで、すべてのデータが完全に削除されます。"
                    )

                    policySection(
                        title: "6. データの管理権限",
                        body: "本アプリが保存するすべてのデータはお客様のデバイス内にのみ存在し、お客様が完全に管理しています。\n\n• 支出履歴の削除：アプリ内の操作でいつでも削除できます\n• 全データの削除：アプリをアンインストールすることで完全に消去されます\n• 開発者はお客様のデータにアクセスする手段を持ちません"
                    )

                    policySection(
                        title: "7. お子様のプライバシー",
                        body: "本アプリは13歳未満のお子様を対象としておらず、意図的にお子様の個人情報を収集することはありません。13歳未満のお子様の保護者の方がお子様のデータが収集されていると判断された場合は、App Storeサポートページよりお問い合わせください。"
                    )

                    policySection(
                        title: "8. ポリシーの変更",
                        body: "本ポリシーは予告なく変更される場合があります。重要な変更が生じた場合はアプリ内でご通知します。変更は本画面への掲載をもって効力を生じますので、定期的にご確認ください。"
                    )

                    policySection(
                        title: "9. お問い合わせ",
                        body: "プライバシーに関するご質問・ご要望・個人情報に関する請求については、App Store のサポートページよりお問い合わせください。"
                    )

                    // 免責注記
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Text("本ポリシーはリリース前に専門の弁護士による確認を受けることを推奨します。")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineSpacing(3)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationTitle("プライバシーポリシー")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private func policyHeader(title: String, updatedAt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("最終更新: \(updatedAt)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Material.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func policySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))

            Text(body)
                .font(.caption)
                .foregroundColor(.gray.opacity(0.9))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Material.ultraThinMaterial)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
