# No-Look-Budget 初期実装計画

## 目指すゴール
Figma等のツールの代わりにSwiftUIモックでUI/UX検証を完了させました。
ここからは、導入した強力な専門スキル（`swiftui-expert-skill`, `ui-ux-pro-max`, `architecture-patterns`, `swiftui-ui-patterns`, `qa-test-planner` 等）と、テスト駆動開発（TDD）・体系的デバッグの手法をフル活用し、堅牢で拡張性の高い**SwiftData連携（CRUD処理）および借金ロジックの本実装**へ移行します。

---

## User Review Required

> [!IMPORTANT]
> **Figma契約の不要論について**
> SwiftUIは非常に強力な宣言的UIフレームワークであり、デザインツール（Figma）で絵を描くのと同じかそれ以上のスピードで「実際のアプリ画面」を構築できます。
> 余計なコストをかけず、**「実際のiPhoneシミュレーター上で動く（アニメーションする）SwiftUIモック」**を作ることで、最も正確に触り心地を検証できます。

> [!NOTE]
> **Apple Wallet 連携に関する技術検証**
> サードパーティ製アプリから「Apple Payで決済された瞬間の金額と店舗情報」をバックグラウンドで完全に自動取得するAPIは、Appleのセキュリティ制限上非常に厳しい可能性があります。
> 万が一技術的に不可能な場合、別のローフリクション入力（ショートカットアプリとの連携や、強力な通知からの直接入力など）へのピボットが必要になるため、まずはこの技術調査（PoC）を最優先で行います。

---

## Proposed Changes

今回は初期立ち上げフェーズのため、主にプロトタイプとしての土台を作ります。

### 1. 調査・PoC (Proof of Concept)
まずはソースコードを書く前に、以下の仕様を公式ドキュメントや検証コードで調査・確定させます。
* **[NEW] Apple Wallet連携の技術仕様調査**
  * `PassKit` や `FinanceKit`（iOS 17.4+）などの現状の仕様から、決済フックが可能か調査。
* **[NEW] WidgetKitの動的更新調査**
  * iOS 18環境において、アプリを起動せずにウィジェット側からインタラクティブに残高を減らすアクション（AppIntents）がどこまでリッチに表現できるかを検証。

### 2. データモデル設計
アプリ内完結のローカルDBとして、最新の `SwiftData` を用いたスキーマを定義します。
* **[NEW] `Models/Budget.swift`**: 全体の予算と残高を管理するモデル。（前月の予算超過分を次月以降の予算金額から自動減額する「借金繰越機能」を包含する）
* **[NEW] `Models/ItemCategory.swift`**: 項目別の予算（POKER, NOMIKAI等）を管理するモデル。
* **[NEW] `Models/IOUManager.swift`**: 立替プール（別枠）を管理・集計するモデル

### 3. SwiftUI モックアプリ構築 (MVP UI) - **[完了]**
Figmaの代わりに、ダミーデータを使って動くUIモックを作成し、画面遷移と基本レイアウトの検証を完了しました。

### 4. [NEXT] 実データ連携・ビジネスロジック実装（SwiftData CRUD処理）
ここからが本番のアプリケーション設計・実装フェーズです。導入したスキル（`architecture-patterns`, `systematic-debugging`, `test-driven-development`等）に基づき、以下のサイクルで進めます。

* **[NEW] ViewModel / DataManagerの構築**
  * Viewからデータの処理ロジックを分離するため、`SwiftData` をラップする Repository パターンや ViewModel (MVVM) を導入します。
* **[NEW] CRUD処理の実装と結合**
  * `QuickInputModalView` からの支出登録（Create）
  * `DashboardView` への予算・残高の自動反映（Read / Update）
  * `TransactionHistoryView` での履歴の編集・削除（Update / Delete）
* **[NEW] 月跨ぎの初期化＆借金プールへのロジック適用**
  * `MonthlyReviewView` にて、予算オーバー分を翌月の予算から引く（または借金プールへ入れる）ロジックの実装。

### 5. 高度なUI/UXの洗練とウィジェット実装
* データのCRUDが安定した段階で、`swiftui-ui-patterns` と `ui-ux-pro-max` のスキルを適用し、トランジションアニメーションやコンポーネントの再利用性を高めます。
* **アプリ外アクションの実装**:
  * `NoLookBudgetWidget.swift`: 予算状況（色・グラデーション）をダイナミックに可視化するウィジェット
  * ディープリンク（`nolookbudget://dashboard`, `nolookbudget://category/[カテゴリ名]`）を利用したアプリ本体へのルーティング機能の実装。

### 6. コンプライアンス・法務要件
各種ガイドラインやライセンスを遵守するための事前設定（一部完了済）。
各種ガイドラインやライセンスを遵守するための事前設定を行います。
* **[NEW] `docs/compliance/app_store_guidelines.md`**: App Store審査のリスク管理ドキュメント。
* **[NEW] `docs/compliance/oss_licenses.md`**: OSS依存とコピーレフト回避のライセンス管理リスト。
* **[NEW] `docs/compliance/intellectual_property.md`**: フォント・画像等の知財管理ルール。

---

## Verification Plan

### Manual Verification
1. **[UI検証]**
   提供したSwiftUIコードをユーザーの手元（MacのXcode）でビルド＆Runしていただき、シミュレーターまたは実機のiPhone上で「残高の見え方」「立替スワイプ/トグルの触り心地」を直接テスト（Vibe Check）していただきます。
2. **[アーキテクチャ・技術検証]**
   事前調査レポート（PoC結果）をマークダウン形式で提出し、実現不可能な機能があった場合の代替案について合意を取ります。
3. **[コンプライアンス検証]**
   利用するサードパーティ製ライブラリにGPL等の違反ライセンスが含まれていないか、初期設定の段階でリストをチェックします。
