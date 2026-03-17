# No-Look-Budget: Claude Code ガイドライン

> このファイルはAntigravity（Gemini）から引き継いだプロジェクトをClaudeCodeで継続開発するための統合ガイドラインです。
> 元ファイル: `GEMINI.md`（引き続き参照可）

---

## 1. プロジェクトのゴール（経営視点）

1. **Primary Goal:** 浪費家（まずはユーザー自身）の浪費癖を減らし、健全な家計管理を実現すること。
2. **Business Goal:** アプリをマネタイズ（サブスクリプションや機能課金等）し、App Storeで公開・リリースし収益化すること。

### コンセプトの魂
- 「ADHD向け：開かなくてもわかる管理（No-Look Experience）」
- 「飲み会対応：立替金セパレーターの極限の簡略化（スワイプ分離）」

---

## 2. 開発・設計思想 (Design & Security First)

- **UI/UX First:** プログラム（MVP）を書き始める前に、必ずFigmaや画像生成などを通じて画面UIのイメージ合わせを行うこと。
- **Security First:** お金を扱うアプリのため、IDやAPIキー、個人情報などは `Keychain` で厳重に管理。ソースコードへのハードコーディングは厳禁。
- **Numeric Input Policy:** 数値入力（金額など）は **必ず独自のカスタムキーパッドを使用**。iOS標準キーボード（TextField等）による直接入力は禁止。全角・半角混在やクラッシュを防ぐ。
- **Marketing Perspective:** 競合アプリとの差別化（「開かせない」「ADHD向け」「立替分離の低負荷」）を各機能実装のたびに確認すること。

---

## 3. 技術スタック・アーキテクチャ

- **Language:** Swift
- **Framework:** SwiftUI
- **Design Style:** Astronautテーマ（Deep Space宇宙×HUD）。ダークモード必須。
- **Architecture:** MVVM + Repository Pattern
- **Data:** SwiftData（App Group共有によるウィジェット連携）
- **Naming Convention:** [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) に厳格に準拠。
- **App Group ID:** `group.com.arima0903.NoLookBudget`

### アーキテクチャ構成
```
View (SwiftUI) → ViewModel → Repository → SwiftData Container
                                              ↕ (App Group)
                                         Widget Extension
```

---

## 4. 作業範囲・フォルダ構成

- **Working Directory:** `/Users/taguchikoji/Desktop/vibecoding/second-business/No-Look-Budget`
- **Source:** `NoLookBudget/NoLookBudget/` 以下（Models, ViewModels, Views, Services, Utils）
- **Widget:** `NoLookBudget/NoLookBudgetWidget/`
- **Tests:** `NoLookBudget/NoLookBudgetTests/`
- **Docs:** `docs/` 以下（設計書・議事録など）
- **Minutes:** 議事録は必ず `docs/minutes/` に保存。

---

## 5. 開発手法・フロー

- **Agile:** 小さな機能単位でリリース・確認を繰り返す。
- **TDD:** 機能実装前にXCTestコードを記述。
- **Architecture Docs:** `docs/architecture/` や `docs/ui/` に都度メンテナンス。
- **Executive Reporting:** `docs/reports/` に進捗サマリを作成。

---

## 6. デザインテーマ: Astronaut（宇宙飛行士）

詳細は `docs/design/astronaut_theme_guidelines.md` を参照。

### 必須ルール
1. **全モーダルに `.preferredColorScheme(.dark)` を付与する**（sheet/fullScreenCoverで引き継がれないため）
2. **独自テンキーUIを使用する**（iOS標準キーボード禁止）
3. **既存のレイアウト・機能を勝手に変更・削除しない**（円グラフの数など）

### カラーパレット
- 背景: Deep Space Navy（`#080B14` 〜 `#1A1A2E`）
- 残高・安全: ミントグリーン（`#22C55E` 〜 `#4ADE80`）
- 消費・警告: コーラルレッド（`#EF4444`）
- UIスタイル: Glassmorphism（`Ultra Thin Material`）、カプセル型

---

## 7. 現在の実装状況（2026-03-16時点）

### 完了済み
- SwiftUI UI/UXモック実装（全画面）
- Astronautテーマのビジュアル統合
- SwiftData モデル定義（Budget, ItemCategory, ExpenseTransaction, IOURecord）
- MVVM ViewModelレイヤー（Dashboard, QuickInput, Configuration等）
- TransactionService（CRUD）
- ウィジェット拡張（NoLookBudgetWidget）
- App Group設定
- BUG-001 / BUG-002 修正済み（2026-03-16）
- CalendarView 追加（ホーム右スワイプで日別支出確認）
- QuickInput メモ欄追加（折りたたみ式・20字）
- ウィジェット表示値のバグ修正（ハードコード値除去）
- ボタン文言「確定」統一

### 既知のバグ

なし（2026-03-16時点）

### テスト状況（2026-03-16）

- PT: 31件 100% Pass
- IT: 14件 100% Pass
- ST: 10件 pending（シミュレータ/実機での手動操作が必要）

### 変更履歴

詳細は `CHANGELOG.md` を参照。

---

## 8. スコープ外事項

> **Apple Wallet (Apple Pay) 連携はMVPスコープ外。** サードパーティAPI未公開のため。当面はウィジェットからの超高速手動入力を磨き込む。

---

## 9. コミュニケーション・教育的配慮

- **Explain for Beginner:** ユーザーはiOS開発初心者（Xcodeは導入済み）。専門用語は噛み砕いて解説。
- **Doc over Code:** なぜその設計にしたのか理由を添える。

---

## 10. スキル（.agent/skills/）

### code-reviewer
- コードの品質・安全性・可読性チェック
- `docs/QA/` との連携

### ios-expert-engineer
- SwiftUI、WidgetKit、SwiftDataの専門的なアドバイス
- MVVM徹底、コンポーネント化、TDD実施、教育的解説

### find-skills
- `npx skills` コマンドでのスキル検索・インストール支援
