# バナー広告マネタイズ ガイド

> 作成: 2026-03-16 / 対象: Orbit Budget iOS アプリ

---

## 1. 広告の種類と特徴

### 1.1 バナー広告（Banner Ad）

画面の上部または下部に常時表示される横長の広告フォーマット。

- **サイズ**: 320×50px（標準）/ Adaptive Banner（画面幅に自動フィット・推奨）
- **特徴**: 常時表示されるためインプレッション数が最大化しやすい
- **UX への影響**: 最小。ユーザーの操作フローを中断しない
- **審査通過率**: 最も高い。金融アプリでの採用実績も豊富
- **CPM目安（日本）**: ¥200〜¥500

### 1.2 インタースティシャル広告（Interstitial Ad）

画面遷移のタイミングで画面全体を覆うフルスクリーン広告。

- **サイズ**: フルスクリーン
- **特徴**: 高いクリック率だが、強制的に表示されるためユーザー体験を大きく阻害する
- **UX への影響**: 大。「突然広告が出た」と感じさせ、アンインストールの動機になりやすい
- **審査注意点**: Apple は「ユーザーの自然な操作フローを妨げる広告」に厳しい。表示頻度・タイミングを慎重に設計しないとリジェクトのリスクがある
- **CPM目安（日本）**: ¥800〜¥2,000
- **Orbit Budget への適性**: 低。家計管理は毎日使う日常ツールのため、ストレスを与えるフォーマットは避けるべき

### 1.3 リワード広告（Rewarded Ad）

ユーザーが自発的に動画広告を視聴することで、アプリ内の特典を獲得できる広告。

- **特徴**: ユーザーの自発的参加のため心理的反発が少ない。単価が最も高い
- **UX への影響**: 適切な設計であれば低い
- **実装難易度**: 高。「広告を見ると何が得られるか」という特典設計が必要
- **金融アプリとの相性**: やや難しい。「広告を見ると予算枠が広がる」等の特典設計は Free to Play ゲームのような感覚になり、家計管理ツールのコンセプトとミスマッチになる可能性がある
- **CPM目安（日本）**: ¥1,500〜¥4,000
- **Orbit Budget への適性**: 中。Phase E 以降の検討課題とする

### 1.4 ネイティブ広告（Native Ad）

アプリのコンテンツと同じレイアウト・デザインに溶け込む広告フォーマット。

- **特徴**: コンテンツと一体感があるためクリック率が高く、UX も損ないにくい
- **実装難易度**: 高。広告ビューを手動でカスタムレイアウトに組み込む必要がある
- **UX への影響**: 最小〜なし（適切に実装した場合）
- **審査注意点**: 広告であることが明示されていること（「広告」ラベル必須）
- **Orbit Budget への適性**: 中。月次振り返り画面への組み込みであれば自然に溶け込む

### Orbit Budget への推奨

**バナー広告（案A: ダッシュボード最下部）を第一候補とする。**

理由:
1. 実装工数が最小（UIViewRepresentable でのラップのみ）
2. 毎日使うダッシュボードでインプレッション数が最大化する
3. ユーザーの操作フローを一切妨げない
4. App Store 審査でのリジェクトリスクが最も低い
5. `isPremiumEnabled` フラグとの統合が単純明快

---

## 2. 収益の仕組み

### 2.1 CPM（Cost Per Mille）

1,000インプレッション（広告が1,000回表示）あたりに得られる収益。

```
収益 = (インプレッション数 / 1,000) × CPM単価
```

- バナー広告の場合、ユーザーが画面を開いている間は継続的にインプレッションが発生する
- Fill Rate（広告の埋まり率）は通常 70〜90%。全てのリクエストに広告が配信されるわけではない

### 2.2 CPC（Cost Per Click）

ユーザーが広告を1回クリックするごとに得られる収益。

```
収益 = クリック数 × CPC単価
```

- バナー広告のクリック率（CTR）は通常 0.1〜0.5%
- AdMob は CPM と CPC を組み合わせた eCPM（effective CPM）で実際の収益を算出する

### 2.3 日本市場の目安単価（2025年実績ベース）

| 広告種別 | CPM目安 | Fill Rate目安 | 備考 |
|---|---|---|---|
| バナー（標準 320×50） | ¥200〜¥500 | 75〜85% | 金融カテゴリは比較的高単価 |
| アダプティブバナー | ¥300〜¥600 | 80〜90% | 標準より高単価になりやすい |
| インタースティシャル | ¥800〜¥2,000 | 85〜95% | 表示機会が限られるため注意 |
| リワード動画 | ¥1,500〜¥4,000 | 90〜95% | 高単価だが実装と UX 設計が複雑 |
| ネイティブ | ¥400〜¥800 | 70〜80% | デザイン次第でCTR向上 |

> 注意: 単価は季節・時期・広告主の予算によって大きく変動する。Q4（10〜12月）は単価が上昇しやすい。

---

## 3. 収益試算

### DAU 1,000人での月次試算（バナー広告）

前提条件:
- DAU: 1,000人
- 1ユーザーあたりの1日のセッション数: 平均 2回
- 1セッションあたりのバナー表示時間: 平均 30秒
- アダプティブバナーの CPM: ¥400（中間値）
- Fill Rate: 80%

```
月間インプレッション数
= DAU × セッション数/日 × 日数 × Fill Rate
= 1,000 × 2 × 30 × 0.8
= 48,000 インプレッション/月

月間収益
= (48,000 / 1,000) × ¥400
= ¥19,200/月
```

> ただし AdMob は Google のプラットフォーム手数料（32%）を差し引いた金額が支払われる。
> 手取り概算: ¥19,200 × 0.68 ≒ **¥13,000/月**

### DAU別の月次収益試算表

| DAU | 月間インプレッション | 推定月収（手取り） |
|---|---|---|
| 500人 | 24,000 | ¥6,500〜 |
| 1,000人 | 48,000 | ¥13,000〜 |
| 3,000人 | 144,000 | ¥39,000〜 |
| 10,000人 | 480,000 | ¥130,000〜 |

> Phase E 初月の目標 ¥5,000/月 は DAU 400人程度から達成可能な現実的な数値。

---

## 4. AdMob 実装ステップ（詳細版）

### ステップ1: Google AdMob アカウント登録・お支払い設定

#### 1-1. アカウント作成

1. [https://admob.google.com](https://admob.google.com) にアクセス
2. Google アカウントでサインイン → 「AdMob を使い始める」をクリック
3. 国/地域「日本」、タイムゾーン「(GMT+09:00) 東京」を選択
4. 利用規約に同意して「AdMob アカウントを作成」

#### 1-2. お支払い情報の設定（⚠️ つまずきポイント）

アカウント作成後、画面上部に **「お支払いの設定が完了していません」** というバナーが表示される場合がある。初回登録で支払い方法を設定済みでもこのバナーが消えないケースがある。以下の手順で対処する。

**原因1: 銀行口座の名義が全角カタカナになっている**

AdMob（Google Payments）は口座名義に **半角カタカナ + 半角スペース** を要求する。全角カタカナで入力すると登録が完了しない。

| 入力項目 | ❌ 誤った例 | ✅ 正しい例 |
|---|---|---|
| 口座名義（姓 名） | タグチ コウジ | ﾀｸﾞﾁ ｺｳｼﾞ |
| 姓名の区切り | 全角スペース | 半角スペース |

> **半角カタカナの入力方法（Mac）**: 日本語入力でカタカナを入力 → `Control + ;` で半角カタカナに変換。または「システム設定 → キーボード → 入力ソース」で半角カタカナ入力を有効にする。

**原因2: 口座種別が「貯蓄」になっている**

デフォルトが「貯蓄（Savings）」になっている場合がある。個人の普通預金口座は **「普通（Checking）」** を選択すること。

**対処手順:**

1. [https://payments.google.com](https://payments.google.com) にアクセス（AdMob とは別画面）
2. 「設定」→「お支払い方法」を開く
3. 既存の銀行口座情報を削除
4. 「お支払い方法を追加」→ 銀行口座を再登録（半角カタカナで名義入力）
5. 口座種別を **「普通」** に設定
6. 登録後、Google から **テストデポジット（25円未満の少額振込）** が2〜4営業日以内に届く
7. 届いた金額を AdMob の「今すぐ確認」画面でドロップダウンから選択して送信
8. 金額が一致すれば口座登録完了 → 「お支払いの設定が完了していません」バナーが消える

> テストデポジットが届かない場合は土日祝を除いて5営業日待つ。複数回口座を削除・再登録した場合、複数のデポジットが振り込まれることがあるので注意。

**原因3: お支払いプロファイルの住所・名前が未確認**

AdMob 管理画面 → 「お支払い」→「お支払い情報」→ 「設定を管理する」で、住所・名前がすべて入力されていることを確認する。空欄があると設定未完了扱いになる。

#### 1-3. アプリの追加（⚠️ バンドルIDについて）

Orbit Budget はまだ App Store に公開していないため、**「非公開アプリ」** としてセットアップする。この場合、初期登録時にバンドルIDの入力欄は表示されない（これは正常な動作）。

**非公開アプリのセットアップ手順:**

1. AdMob サイドバー → 「アプリ」→「アプリを追加」
2. 「アプリはサポートされているアプリストアに登録されていますか？」→ **「いいえ」** を選択
3. プラットフォーム → **「iOS」** を選択
4. アプリ名 → **「Orbit Budget」**（App Store に出す予定の名前）を入力
5. ユーザーに関する指標を有効にする（推奨）
6. 「アプリを追加」をクリック

> この時点では **バンドルID (`com.arima0903.NoLookBudget`) の入力欄は出てこない**。非公開アプリでは、アプリ名とプラットフォームだけで登録される。

**バンドルIDの紐付け（App Store 公開後に行う）:**

App Store にアプリを公開した後、以下の手順でバンドルIDを紐づける:

1. AdMob サイドバー → 「アプリ」→「すべてのアプリを表示」
2. 該当アプリの「ストア」列にある **「ストアを追加」** をクリック
3. App Store でアプリを検索（アプリ名・デベロッパー名・アプリURL で検索可能）
4. 見つかったアプリの横の「追加」をクリック → 自動的にバンドルIDが紐づけられる

> App Store 公開直後は検索に反映されるまで **24〜48時間**（最長1週間）かかることがある。見つからない場合はApp Store の URL を直接貼り付けて検索するとよい。

または「アプリの設定」ページからもリンク可能:

1. アプリ名をクリック → サイドバーの「アプリの設定」
2. 「アプリストア」セクション → 「ストアを追加」

#### 1-4. 広告ユニットの作成

1. アプリ追加後の画面で「広告ユニットを追加」をクリック（後からでも可）
2. 「バナー」を選択
3. 広告ユニット名を入力（例: `dashboard_bottom_banner`）
4. 「広告ユニットを作成」
5. 表示される **広告ユニット ID**（`ca-app-pub-XXXXXXXX/YYYYYYYY`）をメモ
6. 「完了」をクリック

アプリ一覧画面で確認できる **アプリ ID**（`ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`）も必ず控えておく。

> ⚠️ 広告ユニット ID（スラッシュ `/` 区切り）とアプリ ID（チルダ `~` 区切り）は別物。混同注意。

#### 1-5. 現時点でのステータスまとめ

| 状態 | 説明 |
|---|---|
| お支払い設定 | 半角カナで銀行口座登録 → テストデポジット確認で完了 |
| アプリ登録 | 「非公開」として登録済み。バンドルIDは App Store 公開後にリンク |
| 広告ユニット ID | 取得済み。開発中はテスト用 ID を使用 |
| アプリの準備状況 | 「審査が必要」表示 → App Store 公開&リンク後に審査開始 |
| 広告配信 | 非公開アプリは配信制限あり。テスト広告は表示可能 |

> AdMob アカウント審査には数日〜2週間かかる場合がある。Phase D 期間中に先行申請すること。

### ステップ2: Swift Package Manager で SDK 追加

Xcode → File → Add Package Dependencies から以下の URL を追加:

```
https://github.com/googleads/swift-package-manager-google-mobile-ads
```

または `Package.swift` に直接追加:

```swift
dependencies: [
    .package(
        url: "https://github.com/googleads/swift-package-manager-google-mobile-ads",
        from: "11.0.0"
    )
]
```

### ステップ3: Info.plist に GADApplicationIdentifier を追加

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
```

> テスト時は Google 公式のテスト用アプリ ID（`ca-app-pub-3940256099942544~1458002511`）を使用すること。
> 本番の広告ユニット ID を開発中に使用すると AdMob アカウントが停止されるリスクがある。

### ステップ4: PrivacyInfo.xcprivacy への記載

AdMob SDK は以下のプライバシー関連 API を使用するため、`PrivacyInfo.xcprivacy` に記載が必要:

```xml
<key>NSPrivacyAccessedAPITypes</key>
<array>
    <!-- User Defaults（SDK 内部使用） -->
    <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array>
            <string>CA92.1</string>
        </array>
    </dict>
</array>
```

また、App Store Connect の Privacy Nutrition Label で「広告データの使用」を正確に申告すること。AdMob が収集するデータ（デバイス ID・広告インタラクション等）は Google のプライバシーポリシーに基づく。

### ステップ5: SwiftUI BannerAdView の実装例

```swift
import SwiftUI
import GoogleMobileAds

// GADBannerView を UIViewRepresentable でラップ
struct AdMobBannerView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
        bannerView.load(GADRequest())
        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

// isPremiumEnabled フラグで表示を制御するラッパー
struct BannerAdView: View {
    @AppStorage("isPremiumEnabled") private var isPremiumEnabled = false

    // テスト時は Google 公式テスト ID を使用
    // 本番リリース前に実際の広告ユニット ID に置き換える
    private let adUnitID = "ca-app-pub-3940256099942544/2934735716" // テスト用

    var body: some View {
        if !isPremiumEnabled {
            AdMobBannerView(adUnitID: adUnitID)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
        }
    }
}
```

### ステップ6: `isPremiumEnabled` フラグとの統合

`isPremiumEnabled` は `@AppStorage` で管理し、StoreKit 2 のトランザクション検証と連携させる。

```swift
// PremiumManager.swift（概要）
class PremiumManager: ObservableObject {
    @AppStorage("isPremiumEnabled") var isPremiumEnabled = false

    func updatePremiumStatus() async {
        // StoreKit 2 でアクティブなサブスクリプションを確認
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productType == .autoRenewable {
                    await MainActor.run {
                        self.isPremiumEnabled = true
                    }
                }
            }
        }
    }
}
```

ダッシュボードへの組み込みイメージ:

```swift
struct DashboardView: View {
    var body: some View {
        VStack(spacing: 0) {
            // 既存のダッシュボードコンテンツ
            DashboardContentView()

            // 画面最下部に広告（プレミアムユーザーには非表示）
            BannerAdView()
        }
    }
}
```

---

## 5. App Store 審査注意点（金融カテゴリ）

### データ収集に関する申告

- Orbit Budget はデータをローカルにのみ保存し、外部サーバーに送信しない
- ただし AdMob SDK は広告配信のために一部のデバイスデータを使用する
- App Store Connect の **Privacy Nutrition Label** で以下を正確に申告する必要がある:
  - 「広告データ」: 使用あり（AdMob による）
  - 「ユーザーのデータ」: 収集なし（アプリ自体による）

### 広告がコア機能を阻害しないこと

- Guideline 4.0 Design: 広告がアプリのコア機能ボタンを覆ったり、誤タップを誘発したりしてはならない
- バナー広告の下端は画面の Safe Area 内に収めること（ホームインジケータと重ならないよう注意）
- 広告のタップ領域と機能ボタンのタップ領域が重複しないレイアウト設計が必要

### Age Rating: 17+（金融カテゴリの規定）

- Finance カテゴリのアプリは原則として Age Rating 17+ が適用される
- App Store Connect のコンテンツ申告で「成人向けコンテンツ」ではなく「金融取引」として申告する

### Privacy Nutrition Label の正確な記載

```
データの収集とプライバシー

■ データを使用してあなたをトラッキングすることはありません

■ このアプリが収集するデータ:
  - デバイス ID（広告配信のため・AdMob による）

■ このアプリが収集しないデータ:
  - 財務情報（すべてデバイス内のみに保存）
  - 連絡先、位置情報、健康データ等
```

---

## 6. UI配置案 3パターン

### 案A: ダッシュボード最下部固定バナー（推奨）

```
┌─────────────────────────────┐
│                             │
│    [今月の残高]              │
│    ¥ 32,500                 │
│                             │
│  [予算進捗バー ██████░░░░]   │
│                             │
│  [支出カテゴリ一覧]          │
│  食費   ¥8,200              │
│  交通費 ¥3,400              │
│  娯楽   ¥2,100              │
│                             │
│  [＋ 支出を記録]ボタン       │
│                             │
├─────────────────────────────┤
│  [   Google バナー広告    ]  │  ← 高さ 50px 固定
└─────────────────────────────┘
```

- **審査通過率**: 高（最もスタンダードな配置）
- **ユーザー体験への影響**: 最小（コンテンツ領域を圧迫しない）
- **実装難易度**: 低（DashboardView の VStack 末尾に BannerAdView を追加するだけ）
- **インプレッション数**: 最大（毎日開くダッシュボードに配置するため）

### 案B: 月次振り返り画面内ネイティブ広告（月1回・低侵襲）

```
┌─────────────────────────────┐
│  [3月の振り返り]             │
│                             │
│  今月の支出合計: ¥67,500     │
│  予算に対して: -¥2,500       │
│                             │
│  カテゴリ別グラフ            │
│  [■■■■□□] 食費  67%         │
│  [■■□□□□] 交通  33%         │
│                             │
├─────────────────────────────┤
│ [PR] ○○カードで支出を賢く管理 │  ← ネイティブ広告（「PR」ラベル必須）
│      ポイント還元率 2% →    │
├─────────────────────────────┤
│                             │
│  [来月の予算を設定する]      │
└─────────────────────────────┘
```

- **審査通過率**: 高（「PR」ラベルで広告であることを明示している）
- **ユーザー体験への影響**: ほぼなし（月1回の閲覧画面に配置）
- **実装難易度**: 中（ネイティブ広告のカスタムレイアウト実装が必要）
- **推定 CPM**: 標準より高い（コンテキストに合った広告が表示されやすい）
- **注意点**: 「PR」または「広告」ラベルの明示が App Store 審査で必須

### 案C: 支出履歴画面上部バナー（ダッシュボード体験を完全保護）

```
┌─────────────────────────────┐
│  [   Google バナー広告    ]  │  ← 高さ 50px
├─────────────────────────────┤
│  [支出履歴]                  │
│                             │
│  3/16  コンビニ   ¥520      │
│  3/15  スーパー   ¥2,340    │
│  3/14  電車       ¥210      │
│  3/13  ランチ     ¥980      │
│  3/12  コンビニ   ¥350      │
│  3/12  映画       ¥1,800    │
│                             │
│  [もっと見る]                │
└─────────────────────────────┘
```

- **審査通過率**: 高
- **ユーザー体験への影響**: 小（ダッシュボードは広告なしを維持できる）
- **実装難易度**: 低（バナー広告を上部に配置するだけ）
- **インプレッション数**: 中（支出履歴は毎日開く人と週1程度の人に分かれる）
- **ダッシュボードのプレミアム感**: 維持可能

### まとめ比較表

| | 案A（ダッシュボード下部） | 案B（月次振り返り内） | 案C（支出履歴上部） |
|---|---|---|---|
| 実装難易度 | 低 | 中 | 低 |
| インプレッション数 | 最大 | 最小 | 中 |
| 推定月収（DAU 1,000） | ¥13,000〜 | ¥2,000〜 | ¥6,000〜 |
| UX への影響 | 最小 | ほぼなし | 小 |
| ダッシュボードの広告 | あり | なし | なし |
| 審査通過率 | 高 | 高 | 高 |
| 推奨度 | 1位（★★★） | 2位（★★★） | 3位（★★） |

**最終推奨**: 収益最大化を優先するなら**案A**、ダッシュボードのプレミアム感を保ちつつ広告収益も得るなら**案B**との組み合わせが最適。

---

## 参考リンク

- AdMob 公式ドキュメント: [https://developers.google.com/admob/ios](https://developers.google.com/admob/ios)
- Google Mobile Ads SDK (SPM): [https://github.com/googleads/swift-package-manager-google-mobile-ads](https://github.com/googleads/swift-package-manager-google-mobile-ads)
- App Store Review Guidelines（広告）: [https://developer.apple.com/app-store/review/guidelines/#advertising](https://developer.apple.com/app-store/review/guidelines/#advertising)
- AdMob テスト用広告ユニット ID 一覧: [https://developers.google.com/admob/ios/test-ads](https://developers.google.com/admob/ios/test-ads)
- リリースロードマップ: `docs/project/release_roadmap.md`
