import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ZStack {
            Theme.spaceNavy.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    termsHeader(
                        title: "利用規約",
                        updatedAt: "2026年3月17日"
                    )

                    // 事業者情報
                    termsSection(
                        title: "事業者情報",
                        body: "サービス提供者：[開発者氏名または屋号]（以下「開発者」）\n\n本規約における「開発者」とは、Orbit Budgetを開発・提供する個人開発者を指します。"
                    )

                    termsSection(
                        title: "第1条（本規約の適用）",
                        body: "本利用規約（以下「本規約」）は、Orbit Budget（以下「本アプリ」）の利用に関する条件を定めるものです。本アプリをダウンロード・インストールした時点で、本規約に同意したものとみなします。\n\n本規約に同意いただけない場合は、本アプリのご利用をお控えください。"
                    )

                    termsSection(
                        title: "第2条（サービスの内容）",
                        body: "本アプリは、個人の家計管理を支援するiOSアプリケーションです。予算設定・支出記録・ウィジェット表示などの機能を提供します。\n\nサービス内容は予告なく変更・追加・廃止される場合があります。重要な変更がある場合は可能な限りアプリ内でご通知します。"
                    )

                    termsSection(
                        title: "第3条（無料版とCOMMANDER PLAN）",
                        body: "本アプリは無料で基本機能をご利用いただけます。一部の高度な機能（借金の長期分割・高度な分析等）はCOMMANDER PLAN（有料サブスクリプション）の加入が必要です。\n\n【自動更新について】\nCOMMANDER PLANは月額自動更新型サブスクリプションです。購入日から起算して月単位で自動的に更新されます。\n\n【解約方法】\niOSの「設定」→「Apple ID」→「サブスクリプション」からいつでも解約できます。解約は次回更新日の24時間前までに行う必要があります。期間途中での解約による返金は、App Storeの返金ポリシーに従います。\n\n料金・無料トライアルの有無など最新情報はApp Storeの購入画面をご確認ください。"
                    )

                    termsSection(
                        title: "第4条（禁止事項）",
                        body: "以下の行為を禁止します。\n\n• 本アプリのリバースエンジニアリング・改ざん\n• 本アプリを用いた違法行為または第三者への損害行為\n• 不正な手段によるプレミアム機能の利用\n• その他、開発者が合理的な理由に基づき不適切と判断する行為"
                    )

                    termsSection(
                        title: "第5条（免責事項）",
                        body: "本アプリは家計管理の補助ツールであり、金融・税務・投資に関する専門的なアドバイスを提供するものではありません。\n\nアプリの利用によって生じた損害（データの消失・誤った予算判断等）について、開発者は法令上許容される範囲において責任を負いません。ただし、開発者の故意または重大な過失に起因する損害については、この限りではありません。\n\niOSのアップデートその他の事情によりサービスが停止・終了する場合があります。その際に生じた損害についても同様とします。"
                    )

                    termsSection(
                        title: "第6条（知的財産権）",
                        body: "本アプリのデザイン・ロゴ・コードその他の著作物に関する権利は開発者に帰属します。無断複製・転載・配布を禁じます。\n\nApple、iOS、App Storeは Apple Inc. の登録商標です。"
                    )

                    termsSection(
                        title: "第7条（規約の変更）",
                        body: "開発者は必要に応じて本規約を変更できるものとします。変更後の規約は本画面への掲載をもって効力を生じます。重要な変更の場合はアプリ内でご通知します。\n\n変更後も引き続き本アプリを使用した場合、変更後の規約に同意したものとみなします。"
                    )

                    termsSection(
                        title: "第8条（準拠法・管轄）",
                        body: "本規約は日本法に準拠します。本アプリの利用に関して紛争が生じた場合、開発者とお客様は誠意をもって協議の上解決するものとします。\n\n協議が整わない場合、お客様の住所地またはお客様が指定する日本国内の裁判所を管轄裁判所とすることができます。消費者契約法その他の強行法規が適用される場合は、当該法規が優先されます。"
                    )

                    // 免責注記
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Text("本規約はリリース前に専門の弁護士による確認を受けることを推奨します。")
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
        .navigationTitle("利用規約")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private func termsHeader(title: String, updatedAt: String) -> some View {
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

    private func termsSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))

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
        TermsOfServiceView()
    }
}
