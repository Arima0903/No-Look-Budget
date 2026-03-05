# No-Look-Budget PT（プログラムテスト）仕様書

| 項目 | 内容 |
|------|------|
| ドキュメントID | PT-001 |
| バージョン | 1.0 |
| 最終更新日 | 2026-03-06 |
| 対応設計書 | DD-001 |
| テストレベル | 単体テスト（Unit Test） |
| 実施方法 | XCTest フレームワーク |

---

## 1. テスト方針

PTでは各クラス・関数を単体で検証する。外部依存（SwiftData等）はインメモリコンテナまたはモックで置き換える。

---

## 2. テストケース

### 2.1 QuickInputViewModel

| ID | テスト観点ID | テスト項目 | 入力 | 期待結果 |
|----|------------|----------|------|---------|
| PT-QI-001 | TP-01 | 通常支出の保存 | amount=500, category=食費, isIOU=false | ExpenseTransaction が1件追加、logExpense()がtrueを返す |
| PT-QI-002 | TP-01 | 金額0の支出は保存されない | expressionText="0" | logExpense()がfalseを返す |
| PT-QI-003 | TP-02 | 立替2段入力の正常保存 | iou=5000, myExpense=2000 | IOU(3000)と支出(2000)の2件追加 |
| PT-QI-004 | TP-03 | バリデーション: 自己支出未入力 | iou=5000, myExpense="0" | showAlert=true, alertMessage含む「自分の支出額を入力」 |
| PT-QI-005 | TP-03 | バリデーション: 総額<自己支出 | iou=1000, myExpense=3000 | showAlert=true, alertMessage含む「立替総額が…小さく」 |
| PT-QI-006 | TP-02 | 立替のみ(自己支出0の回避) | iou=5000, myExpense="0+0" | myExpenseが0として計算、IOU(5000)のみ1件追加 |
| PT-QI-007 | TP-01 | 臨時収入の保存 | inputMode=income, amount=50000 | isIncome=trueのExpenseTransaction追加 |

### 2.2 calculateResult

| ID | テスト観点ID | テスト項目 | 入力 | 期待結果 |
|----|------------|----------|------|---------|
| PT-CR-001 | TP-04 | 単純な数値 | "500" | "500" |
| PT-CR-002 | TP-04 | 四則演算 | "100+200" | "300" |
| PT-CR-003 | TP-04 | 掛け算記号(×) | "100×3" | "300" |
| PT-CR-004 | TP-04 | 割り算記号(÷) | "300÷3" | "100" |
| PT-CR-005 | TP-04 | 末尾演算子 | "100+" | nil |
| PT-CR-006 | TP-04 | 連続演算子 | "100++200" | nil |
| PT-CR-007 | TP-04 | 不正文字 | "abc" | nil |
| PT-CR-008 | TP-04 | 負の結果 | "100-200" | "0" |
| PT-CR-009 | TP-04 | パーセント | "1000％" | "10" |

### 2.3 TransactionService

| ID | テスト観点ID | テスト項目 | 前提 | 操作 | 期待結果 |
|----|------------|----------|------|------|---------|
| PT-TS-001 | TP-05 | 支出追加で予算残高減少 | Budget(total=100000, spent=0) | addExpense(500, 食費, false) | Budget.spentAmount==500 |
| PT-TS-002 | TP-06 | 立替追加で予算不変 | Budget(total=100000, spent=0) | addExpense(3000, 食費, true) | Budget.spentAmount==0 |
| PT-TS-003 | TP-05 | カテゴリ予算も連動 | ItemCategory(spent=0) | addExpense(500, そのカテゴリ, false) | category.spentAmount==500 |
| PT-TS-004 | TP-07 | 削除で予算復元 | Budget(spent=500) | deleteTransaction(id) | Budget.spentAmount==0 |
| PT-TS-005 | TP-08 | 月跨ぎ借金繰越 | Budget(total=100000, spent=120000) | processMonthlyReview() | 次月Budget.totalAmount == 100000-20000 |
| PT-TS-006 | TP-09 | 臨時収入でtotalAmount増加 | Budget(total=100000) | addIncome(50000) | Budget.totalAmount==150000 |
| PT-TS-007 | TP-07 | 更新で差分反映 | 支出500円あり | updateExpense(id, 1000) | Budget.spentAmount差分+500 |
