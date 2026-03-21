# Orbit Budget IT（結合テスト）仕様書

| 項目 | 内容 |
|------|------|
| ドキュメントID | IT-001 |
| バージョン | 2.0 |
| 最終更新日 | 2026-03-06 |
| 対応設計書 | BD-001 / DD-001 |
| テストレベル | 結合テスト（Integration Test） |
| 実施方法 | XCTest + インメモリSwiftDataコンテナ |

## 改版履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|---------|
| 1.0 | 2026-03-06 | 初版作成 |
| 2.0 | 2026-03-06 | IOU削除/更新テスト追加、共通前提条件の明示、テスト実施順序の整理 |

---

## 1. テスト方針

- ITでは、ViewModel ⇔ Service ⇔ SwiftData の**結合動作**を検証する
- インメモリの SwiftData コンテナを使用し、実際のデータフローを通しでテストする
- 各テストは前のテストの影響を受けないよう、`setUp` で初期化する

---

## 2. 共通前提条件

各テスト開始時に以下の初期データが投入済みであること。

| データ | 値 |
|--------|-----|
| Budget | month=当月, totalAmount=250000, spentAmount=0 |
| ItemCategory "食費" | totalAmount=50000, spentAmount=0, orderIndex=0 |
| ItemCategory "交際費" | totalAmount=30000, spentAmount=0, orderIndex=1 |

---

## 3. テストケース

### 3.1 支出入力→ダッシュボード反映

| ID | テスト観点ID | テスト項目 | 操作 | 期待結果 |
|----|------------|----------|------|---------|
| IT-001 | TP-10 | 支出入力でダッシュボード連動 | QuickInputVM: 食費500円を保存 → DashboardVM.fetchData() | recentTransactions に食費500円あり、Budget.remainingAmount == 249500 |
| IT-002 | TP-10 | カテゴリ予算も連動 | QuickInputVM: 食費500円を保存 | DashboardVM.categories の食費.spentAmount == 500 |
| IT-003 | TP-11 | 臨時収入で予算増加 | QuickInputVM: 臨時収入50000 | DashboardVM の budget.totalAmount == 300000 |

### 3.2 立替入力→各画面連動

| ID | テスト観点ID | テスト項目 | 操作 | 期待結果 |
|----|------------|----------|------|---------|
| IT-004 | TP-12 | 立替2段入力の保存と表示 | iou=5000, myExpense=2000 で保存 → DashboardVM.fetchData() | recentTransactions に自己支出2000円あり |
| IT-005 | TP-12 | 立替分は予算に影響しない | iou=5000, myExpense=2000 で保存 | Budget.spentAmount == 2000（3000は影響なし） |
| IT-006 | TP-12 | 立替分が履歴に表示 | iou=5000, myExpense=2000 で保存 | TransactionHistoryVM に2件表示（IOU=3000, 支出=2000） |

### 3.3 編集・削除→予算復元

| ID | テスト観点ID | テスト項目 | 操作 | 期待結果 |
|----|------------|----------|------|---------|
| IT-007 | TP-13 | 支出編集で差分反映 | 食費500→1000に編集 | Budget.spentAmount == 1000、食費.spentAmount == 1000 |
| IT-008 | TP-14 | 通常支出削除で予算復元 | 食費1000の支出を削除 | Budget.spentAmount == 0、食費.spentAmount == 0 |
| IT-009 | TP-14 | **IOU削除で予算不変** | IOU(3000)を削除 | **Budget.spentAmount が変化しないこと** |
| IT-010 | TP-15 | 固定費は履歴から削除不可 | isFixedCost=true の履歴を削除 | 削除されない |

### 3.4 月跨ぎ処理

| ID | テスト観点ID | テスト項目 | 操作 | 期待結果 |
|----|------------|----------|------|---------|
| IT-011 | TP-16 | 月次レビュー実行 | Budget(spent=270000) → processMonthlyReview | 次月Budget.spentAmount == 20000（借金繰越） |
| IT-012 | TP-16 | 借金回収処理 | recoverDebt("食費", "交際費", 5000) | 食費.totalAmount -= 5000、交際費.spentAmount -= 5000 |

### 3.5 設定変更→データ連動

| ID | テスト観点ID | テスト項目 | 操作 | 期待結果 |
|----|------------|----------|------|---------|
| IT-013 | TP-17 | カテゴリ追加 | ConfigurationVM でカテゴリ追加 | DashboardVM.categories に反映 |
| IT-014 | TP-17 | 固定費追加→トランザクション生成 | FixedCostSetting 追加 → 保存 | isFixedCost=true の ExpenseTransaction が自動生成 |
| IT-015 | TP-18 | 予算額変更 | Budget.totalAmount を 300000 に変更 | DashboardVM の remainingAmount == 300000 |

### 3.6 ソート順・0件データ

| ID | テスト観点ID | テスト項目 | 操作 | 期待結果 |
|----|------------|----------|------|---------|
| IT-016 | No.19 | 支出履歴のソート順 | 異なる日時で3件保存 → TransactionHistoryVM取得 | 日付降順で表示されること（TISカタログ 画面-20準拠） |
| IT-017 | No.20 | 0件データ時のダッシュボード | 支出0件の状態でDashboardVM.fetchData() | クラッシュせず空状態で表示されること |
| IT-018 | No.20 | 0件データ時の履歴画面 | 支出0件の状態でTransactionHistoryVM取得 | クラッシュせず空リスト表示 |

