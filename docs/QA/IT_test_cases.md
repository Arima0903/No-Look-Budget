# No-Look-Budget IT（結合テスト）仕様書

| 項目 | 内容 |
|------|------|
| ドキュメントID | IT-001 |
| バージョン | 1.0 |
| 最終更新日 | 2026-03-06 |
| 対応設計書 | BD-001 / DD-001 |
| テストレベル | 結合テスト（Integration Test） |
| 実施方法 | XCTest + シミュレータ操作 |

---

## 1. テスト方針

ITでは、View ⇔ ViewModel ⇔ Service ⇔ SwiftData の結合動作を検証する。
インメモリのSwiftDataコンテナを使用し、実際のデータフローを通しでテストする。

---

## 2. テストケース

### 2.1 支出入力→ダッシュボード反映

| ID | テスト観点ID | テスト項目 | 操作 | 期待結果 |
|----|------------|----------|------|---------|
| IT-001 | TP-10 | 支出入力でダッシュボード連動 | QuickInputVMで支出500保存 → DashboardVM.fetchData() | Dashboard側のrecentTransactionsに該当支出あり、Budget残高減少 |
| IT-002 | TP-10 | カテゴリ予算も連動 | QuickInputVMで食費500保存 | DashboardVM.categoriesの食費.spentAmount増加 |
| IT-003 | TP-11 | 臨時収入で予算増加連動 | QuickInputVMで収入50000保存 | DashboardVM.currentBudget.totalAmount増加 |

### 2.2 立替入力→各画面連動

| ID | テスト観点ID | テスト項目 | 操作 | 期待結果 |
|----|------------|----------|------|---------|
| IT-004 | TP-12 | 立替2段入力の保存と表示 | iou=5000, myExpense=2000で保存 → DashboardVM.fetchData() | 自己支出分(2000)がrecentTransactionsに表示 |
| IT-005 | TP-12 | 立替分は予算に影響しない | iou=5000, myExpense=2000で保存 | Budget.spentAmount += 2000のみ（3000は影響なし） |
| IT-006 | TP-12 | 立替分が履歴に表示される | iou=5000, myExpense=2000 | TransactionHistoryVMに2件表示（IOU=3000, 支出=2000） |

### 2.3 編集・削除→予算復元

| ID | テスト観点ID | テスト項目 | 操作 | 期待結果 |
|----|------------|----------|------|---------|
| IT-007 | TP-13 | 支出編集で差分反映 | 500→1000に編集 | Budget.spentAmount差分+500、カテゴリも連動 |
| IT-008 | TP-14 | 支出削除で予算復元 | 1000の支出を削除 | Budget.spentAmount -= 1000、カテゴリも復元 |
| IT-009 | TP-15 | 固定費は履歴から削除不可 | isFixedCost=trueの履歴を削除操作 | 削除されない（guard で弾かれる） |

### 2.4 月跨ぎ処理

| ID | テスト観点ID | テスト項目 | 操作 | 期待結果 |
|----|------------|----------|------|---------|
| IT-010 | TP-16 | 月次レビュー実行 | processMonthlyReview | 次月Budgetが生成、借金繰越反映 |
| IT-011 | TP-16 | 借金回収処理 | recoverDebt(source, target, amount) | 各カテゴリのspentAmount調整 |

### 2.5 設定変更→データ連動

| ID | テスト観点ID | テスト項目 | 操作 | 期待結果 |
|----|------------|----------|------|---------|
| IT-012 | TP-17 | カテゴリ追加 | ConfigurationVMでカテゴリ追加 | DashboardVMのcategoriesに反映 |
| IT-013 | TP-17 | 固定費追加→トランザクション生成 | FixedCostSetting追加 → 保存 | isFixedCost=trueのExpenseTransactionが自動生成 |
| IT-014 | TP-18 | 予算額変更 | Budget.totalAmount変更 | DashboardVMのremainingAmount連動 |
