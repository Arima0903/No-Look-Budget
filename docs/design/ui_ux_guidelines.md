# No-Look-Budget: UI/UX & Design Guidelines

本ドキュメントは、「No-Look-Budget」アプリにおけるデザインの一貫性（UI/UX）および実装時のルールを定めたガイドラインです。今後の機能追加や画面実装の際には、必ず本指針に沿って実装を行なってください。

## 1. 全体テーマ・基調カラー（Dark Mode First）
アプリ全体は**ダークモードを基本（Dark Mode First）**として設計されています。「黒に近いダークグレー」を背景に敷き、視認性の高いホワイトやアクセントカラーで情報を浮き上がらせるモダンなUI（Apple純正の流儀やGlassmorphismの要素）を目指します。

- **メイン背景色:** `Color(red: 0.1, green: 0.1, blue: 0.11)` または `Color(red: 0.08, green: 0.08, blue: 0.09)`
- **文字基本色:** `Color.white`
- **サブ文字色（説明書き、非強調等）:** `Color.gray`
- **アクセントカラー（メインアクション・ポジティブ）:** 
  - `Color.yellow` (ボタンテキスト、アイコンの強調など)
  - `Color(red: 0.4, green: 0.9, blue: 0.6)` (緑系 / 残高が潤沢な時、収入など)
- **警告・ネガティブカラー:** `Color.red`, `Color.orange` (支出過多、超過アラートなど)

---

## 2. モーダル・別画面遷移時の注意点（最重要）
SwiftUIにおいて、`.sheet` や `.fullScreenCover` などで別モーダルを呼び出した際、**大元のアプリのカラースキーム（ダークモード指定）が自動で引き継がれないケース**が多発します。

**【ルール】:**
モーダルとして呼び出される全てのView（NavigationStack等の根本）に対して、**必ず `.preferredColorScheme(.dark)` を明示的に修飾してください。**
これにより、背景がダークグレー（または黒）の際にテキストがデフォルトの「黒」になって暗闇に同化してしまうバグを未然に防ぎます。

```swift
// 実装例
.sheet(isPresented: $showModal) {
    SomeModalView()
        .preferredColorScheme(.dark) // 必須
}
```

---

## 3. 数値入力ポリシー（Custom NumberPad）
金額などの「数値」を入力させる場面において、iOS標準のキーボード（TextField等）は使用しません。全角半角の混在や予期せぬクリップボードペーストによるクラッシュを防ぐためです。

**【ルール】:**
数値を入力する箇所は、必ず独自の **`NumberPadModalView`** をシート展開して入力させてください。

- 呼び出し元のViewは、`@State` などで入力値を保持しバインディングとして渡す。
- ボタンとしてタップさせることで `NumberPadModalView` を展開。
- 金額表示部は「¥ 0000」の形式で視認性高く表示する。

---

## 4. パーツデザイン・視覚効果

### 4.1. ボタン（Buttons）
ユーザーがタップ可能な主要アクションボタンには、タップ感（スケールアニメーションやHaptic Feedback）を持たせます。
- **スタイル:** `ScaleButtonStyle` (押し込むと縮むアニメーション) を適用。
- **触覚フィードバック:** アクション実行時に `UIImpactFeedbackGenerator(style: .light)` などのHapticsを鳴らす。
- **背景:** 
  - メインボタン：グラデーションカラー（例: 緑系の流線）や `Color.yellow`。
  - リスト内のセルボタン：`Material.ultraThinMaterial` などを用いた擦りガラス風（Glassmorphism）を採用し、背景から少し浮かせた表現 (`.shadow`) を適用する。

### 4.2. リスト・フォーム要素（Lists / Forms）
iOS標準のリストスタイルは利用しつつ、背景透過性をコントロールしてダークな世界観を壊さないようにします。
- `Form` や `List` を使う場合は、`.scrollContentBackground(.hidden)` を指定して標準のグレー背景を消し、全体背景色 (`Color(red: 0.1, green: 0.1, blue: 0.11)`) を反映させる。
- セルの背景は `.listRowBackground(Color.white.opacity(0.05))` などの薄いホワイト透過を用いることで、コンテンツの境界を表現する。

### 4.3. タイポグラフィ（フォント）
- **金額などの主要数字:** `.font(.system(size: ..., weight: .bold, design: .rounded))` 
  - Rounded（丸ゴシック系）デザインを指定し、親しみやすさと視認性を高める。
- **見出し・タイトル:** `.headline` / `.title` などをベースに、ウェイトは太め (`.bold()`) に設定。
- **補足・注釈事項:** `.caption` / `.caption2` を使用し、色は `.gray` とすることで主張を抑える。

---

## 5. 画面構成のシンプル化 (Do NOT overcomplicate)
「No-Look-Budget」のコンセプトに従い、操作に必要な手数（タップ数）や文字情報は極限まで減らします。
- **不要な標準UIの排除:** 今回のEditButton削除のように、「スワイプで削除可能」「保存ボタンで確定可能」など、別の直感的な手段が提供されている場合は、画面上部の無駄なボタンを削り引き算のデザインを徹底する。
- 一つの画面に情報を詰め込みすぎず、本当に直近で必要な情報（今見なければならない予算・やばい支出）のみをハイライトする。
