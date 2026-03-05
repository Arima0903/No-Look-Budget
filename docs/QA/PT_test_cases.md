# No-Look-Budget PT（プログラムテスト）仕様書

| 項目 | 内容 |
|------|------|
| ドキュメントID | PT-001 |
| バージョン | 2.0 |
| 最終更新日 | 2026-03-06 |
| 対応設計書 | DD-001 |
| テストレベル | 単体テスト（Unit Test） |
| 実施方法 | XCTest フレームワーク |

## 改版履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|---------|
| 1.0 | 2026-03-06 | 初版作成 |
| 2.0 | 2026-03-06 | IOU削除/更新テスト追加、前提条件・事後条件の詳細化、境界値テスト追加 |

---

## 1. テスト方針

- PTでは各クラス・関数を**単体**で検証する
- 外部依存（SwiftData等）は `SharedModelContainer.createInMemoryContainer()` でインメモリ化
- 各テストケースは独立に実行可能（`setUp` で毎回初期データを投入）

---

## 2. テストケース

### 2.1 QuickInputViewModel

| ID | テスト観点ID | テスト項目 | 前提条件 | 入力 | 期待結果 | 事後条件 |
|----|------------|----------|---------|------|---------|---------|
| PT-QI-001 | TP-01 | 通常支出の保存 | カテゴリ「食費」選択済み | expressionText="500" | logExpense() → true | ExpenseTransaction 1件追加 (amount=500, isIOU=false) |
| PT-QI-002 | TP-01 | 金額0の支出は保存されない | - | expressionText="0" | logExpense() → false | トランザクション数変化なし |
| PT-QI-003 | TP-02 | 立替2段入力の正常保存 | isIOUMode=true, カテゴリ選択済み | iouExpression="5000", myExpenseExpression="2000" | logExpense() → true | IOU(3000) + 支出(2000) の2件追加 |
| PT-QI-004 | TP-03 | VLD-101: 自己支出未入力 | isIOUMode=true | iouExpression="5000", myExpenseExpression="0" | logExpense() → false, showAlert=true | alertMessage に「自分の支出額を入力」を含む |
| PT-QI-005 | TP-03 | VLD-102: 総額<自己支出 | isIOUMode=true | iouExpression="1000", myExpenseExpression="3000" | logExpense() → false, showAlert=true | alertMessage に「立替総額が…小さく」を含む |
| PT-QI-006 | TP-02 | 自己支出0回避("0+0") | isIOUMode=true | iouExpression="5000", myExpenseExpression="0+0" | logExpense() → true | IOU(5000) 1件のみ追加（myExpense=0なので支出トランザクションなし） |
| PT-QI-007 | TP-01 | 臨時収入の保存 | inputMode=income | expressionText="50000" | logExpense() → true | ExpenseTransaction (amount=50000, isIncome=true) 追加 |
| PT-QI-008 | TP-02 | 立替総額=自己支出（全額自己負担） | isIOUMode=true | iouExpression="3000", myExpenseExpression="3000" | logExpense() → true | 支出(3000) 1件のみ（actualIOUAmount=0なのでIOU生成なし） |

### 2.2 calculateResult

| ID | テスト観点ID | テスト項目 | 入力 | 期待結果 | 検証ポイント |
|----|------------|----------|------|---------|------------|
| PT-CR-001 | TP-04 | 単純な数値 | "500" | "500" | 基本動作 |
| PT-CR-002 | TP-04 | 加算 | "100+200" | "300" | 加算演算 |
| PT-CR-003 | TP-04 | 掛け算記号(×) | "100×3" | "300" | 記号変換 |
| PT-CR-004 | TP-04 | 割り算記号(÷) | "300÷3" | "100" | 記号変換 |
| PT-CR-005 | TP-04 | 末尾演算子 | "100+" | nil | 不完全式の拒否 |
| PT-CR-006 | TP-04 | 連続演算子 | "100++200" | nil | 不正式の拒否 |
| PT-CR-007 | TP-04 | 不正文字 | "abc" | nil | 文字種チェック |
| PT-CR-008 | TP-04 | 負の結果 | "100-200" | "0" | 負数→0変換 |
| PT-CR-009 | TP-04 | パーセント | "1000％" | "10" | ％→/100変換 |
| PT-CR-010 | TP-04 | ゼロ入力 | "0" | "0" | 境界値 |
| PT-CR-011 | TP-04 | 複合式 | "1000+500×2" | "3000" | 演算子優先順位 |
| PT-CR-012 | TP-04 | 末尾小数点 | "100." | nil | 不完全式の拒否 |
| PT-CR-013 | No.5 | 最大長(15文字) | "123456789012345" | 計算結果を返す | 上限値テスト（TISカタログ Val-6） |
| PT-CR-014 | No.6 | 16文字目の入力拒否 | 15文字の式に追加入力 | 16文字目が入力されないこと | 上限超過テスト（TISカタログ Val-8） |

### 2.3 TransactionService

| ID | テスト観点ID | テスト項目 | 前提条件 | 操作 | 期待結果 | 事後条件 |
|----|------------|----------|---------|------|---------|---------|
| PT-TS-001 | TP-05 | 支出追加で予算減少 | Budget(total=100000, spent=0) | addExpense(500, 食費, false) | - | Budget.spentAmount==500, Category.spentAmount==500 |
| PT-TS-002 | TP-06 | 立替追加で予算不変 | Budget(total=100000, spent=0) | addExpense(3000, 食費, true) | - | Budget.spentAmount==0, Category.spentAmount==0, IOURecord 1件 |
| PT-TS-003 | TP-05 | カテゴリなし支出 | Budget(total=100000, spent=0) | addExpense(500, nil, false) | - | Budget.spentAmount==500, カテゴリ影響なし |
| PT-TS-004 | TP-07 | 通常支出の削除で予算復元 | Budget(spent=500), 支出500あり | deleteTransaction(id) | - | Budget.spentAmount==0, Category.spentAmount==0 |
| PT-TS-005 | TP-07 | **IOU削除で予算不変** | Budget(spent=0), IOU(3000)あり | deleteTransaction(id) | - | **Budget.spentAmount==0**（復元処理なし） |
| PT-TS-006 | TP-08 | 月跨ぎ借金繰越 | Budget(total=100000, spent=120000) | processMonthlyReview() | - | 次月Budget作成、次月spentAmount==20000 |
| PT-TS-007 | TP-09 | 臨時収入でtotalAmount増加 | Budget(total=100000) | addIncome(50000) | - | Budget.totalAmount==150000 |
| PT-TS-008 | TP-07 | 通常支出の更新で差分反映 | Budget(spent=500), 支出500 | updateExpense(id, 1000, cat, false) | - | Budget.spentAmount==1000 |
| PT-TS-009 | TP-07 | **IOU→IOU更新で予算不変** | Budget(spent=0), IOU(3000) | updateExpense(id, 5000, cat, true) | - | **Budget.spentAmount==0** |
| PT-TS-010 | TP-05 | 金額0の支出は無視される | Budget(spent=0) | addExpense(0, 食費, false) | - | Budget.spentAmount==0（guard で弾かれる） |
| PT-TS-011 | TP-07 | 収入削除でtotalAmount減 | Budget(total=150000), 収入50000 | deleteTransaction(id) | - | Budget.totalAmount==100000 |
| PT-TS-012 | No.32 | 存在しないIDの削除でクラッシュしない | Budget(spent=0) | deleteTransaction(存在しないUUID) | - | エラー・クラッシュなし（TISカタログ DB-34準拠） |

