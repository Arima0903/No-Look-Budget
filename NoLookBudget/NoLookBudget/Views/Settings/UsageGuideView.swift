import SwiftUI

struct UsageGuideView: View {
    @State private var selectedSection = 0

    private let sections = ["基本の使い方", "ウィジェット設置"]

    var body: some View {
        ZStack {
            Theme.spaceNavy.ignoresSafeArea()

            VStack(spacing: 0) {
                // セクション切替ピッカー
                Picker("", selection: $selectedSection) {
                    ForEach(0..<sections.count, id: \.self) { i in
                        Text(sections[i]).tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                ScrollView(showsIndicators: false) {
                    if selectedSection == 0 {
                        basicGuideContent
                    } else {
                        widgetGuideContent
                    }
                }
            }
        }
        .navigationTitle("使い方ガイド")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    // MARK: - 基本の使い方

    private var basicGuideContent: some View {
        VStack(spacing: 20) {
            guideStep(
                number: 1,
                icon: "yensign.circle.fill",
                iconColor: Color(red: 0.4, green: 0.9, blue: 0.6),
                title: "まず予算を設定する",
                body: "右上のメニュー → 「予算・カテゴリ設定」を開き、手取り収入・先取り貯金・固定費を入力します。残りが「今月使える変動費」として自動計算されます。"
            )
            guideStep(
                number: 2,
                icon: "plus.circle.fill",
                iconColor: Color(red: 0.4, green: 0.7, blue: 1.0),
                title: "支出を記録する",
                body: "ホーム画面下部の「記録をつける」ボタンをタップ。テンキーで金額を入力し、カテゴリを選択したら「確定」。ウィジェットを見ながら操作しなくても記録できます。"
            )
            guideStep(
                number: 3,
                icon: "person.2.fill",
                iconColor: Color(red: 1.0, green: 0.6, blue: 0.2),
                title: "立替を記録する（飲み会など）",
                body: "支出記録画面で「立替」トグルをオンにします。「みんなの立替分」と「自分自身の支出」を分けて入力でき、あとで精算するための記録が残ります。"
            )
            guideStep(
                number: 4,
                icon: "chart.bar.fill",
                iconColor: Color(red: 0.6, green: 0.4, blue: 1.0),
                title: "月末に振り返る",
                body: "右上のメニュー → 「月次振り返り」で今月の結果を確認できます。予算内に収められた月の節約額は累計で記録され、あなたの頑張りを可視化します。"
            )
            guideStep(
                number: 5,
                icon: "arrow.left.arrow.right",
                iconColor: Color(red: 1.0, green: 0.4, blue: 0.4),
                title: "過去月のデータを見る",
                body: "ホーム画面上部の「＜ ＞」ボタンで過去月を切り替えて閲覧できます。カレンダーを左にスワイプすると日別の支出カレンダーも確認できます。"
            )

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // MARK: - ウィジェット設置ガイド

    private var widgetGuideContent: some View {
        VStack(spacing: 20) {
            // 説明ヘッダー
            VStack(spacing: 10) {
                Image("astronaut_mascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .blendMode(.screen)
                    .opacity(0.9)

                Text("ホーム画面にウィジェットを置くことで、アプリを開かなくても残り予算を一目で確認できます。")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.top, 10)

            widgetStep(
                number: 1,
                title: "ホーム画面を長押し",
                body: "iPhoneのホーム画面の何もない場所を長押しします。アイコンが揺れ始めたら次のステップへ。"
            )
            widgetStep(
                number: 2,
                title: "「＋」ボタンをタップ",
                body: "画面左上に表示される「＋」ボタンをタップします。ウィジェット追加メニューが開きます。"
            )
            widgetStep(
                number: 3,
                title: "「Orbit Budget」を検索",
                body: "検索バーに「Orbit」と入力するか、リストをスクロールしてアプリを見つけます。"
            )
            widgetStep(
                number: 4,
                title: "ウィジェットサイズを選ぶ",
                body: "左右にスワイプしてサイズを選択します。「大」サイズでは残り予算・カテゴリ別の残高を一覧できます。"
            )
            widgetStep(
                number: 5,
                title: "「ウィジェットを追加」をタップ",
                body: "ボタンをタップすると、ホーム画面にウィジェットが追加されます。好きな位置にドラッグして配置を完了させましょう。"
            )

            // ヒント
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.subheadline)
                VStack(alignment: .leading, spacing: 4) {
                    Text("ヒント")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                    Text("ウィジェットのデータが古い場合は、アプリを一度開くと最新の情報に更新されます。")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineSpacing(3)
                }
            }
            .padding(16)
            .background(Color.yellow.opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
            )

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // MARK: - コンポーネント

    private func guideStep(number: Int, icon: String, iconColor: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("STEP \(number)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(iconColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(iconColor.opacity(0.15))
                        .cornerRadius(4)

                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }

                Text(body)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Material.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private func widgetStep(number: Int, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(number)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(body)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Material.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        UsageGuideView()
    }
}
