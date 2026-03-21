# Orbit Budget テスト結果報告書

| 項目 | 内容 |
|------|------|
| 実施日 | 2026-03-06 |
| 実施者 | 開発エージェント |
| 実施方法 | コードレビューベースの静的検証（xcodebuild利用不可のため） |

---

## 1. 実施概要

Xcode CLT環境のみ（`xcodebuild` 利用不可）のため、PT/ITテストケースを **ソースコードのトレース（静的解析）** により実施しました。各テストケースについて、対象コードのロジックを追い、期待結果と一致するかを判定しています。

STテストはシミュレータ/実機での手動操作が必要なため、今回のスコープ外です。

---

## 2. PT（プログラムテスト）結果

### 2.1 QuickInputViewModel

| ID | テスト項目 | 結果 | 根拠 |
|----|----------|:----:|------|
| PT-QI-001 | 通常支出の保存 | ✅ Pass | `logExpense()` L126-127: `calculateResult()` でamountを取得 → `addExpense(isIOU: false)` を呼び出し。return true |
| PT-QI-002 | 金額0の支出は保存されない | ✅ Pass | L127: `amount > 0` の guard で弾かれ `return false` |
| PT-QI-003 | 立替2段入力の正常保存 | ✅ Pass | L116: `actualIOUAmount = 5000 - 2000 = 3000` → L118-119: `addExpense(3000, isIOU:true)`、L121-122: `addExpense(2000, isIOU:false)` |
| PT-QI-004 | VLD-101: 自己支出未入力 | ✅ Pass | L105: `myExpenseExpression == "0"` → `showAlert = true`, `return false` |
| PT-QI-005 | VLD-102: 総額<自己支出 | ✅ Pass | L110: `totalAmount < myExpenseAmount` → `showAlert = true`, `return false` |
| PT-QI-006 | 自己支出0回避("0+0") | ✅ Pass | `"0+0"` は `calculateResult` で `"0"` と評価され、L105の条件 `myExpenseExpression == "0"` は false（"0+0" ≠ "0"）。以降、myExpenseAmount=0 なのでIOU(5000)のみ保存 |
| PT-QI-007 | 臨時収入の保存 | ✅ Pass | L136-137: `inputMode == .income` → `addIncome(amount)` を呼び出し |

### 2.2 calculateResult

| ID | テスト項目 | 結果 | 根拠 |
|----|----------|:----:|------|
| PT-CR-001 | 単純な数値 "500" | ✅ Pass | NSExpression("500") → 500 |
| PT-CR-002 | 四則演算 "100+200" | ✅ Pass | NSExpression("100+200") → 300 |
| PT-CR-003 | 掛け算 "100×3" | ✅ Pass | L66: `×` → `*` に置換 → NSExpression("100*3") → 300 |
| PT-CR-004 | 割り算 "300÷3" | ✅ Pass | L67: `÷` → `/` に置換 → NSExpression("300/3") → 100 |
| PT-CR-005 | 末尾演算子 "100+" | ✅ Pass | L76: 末尾が `+` → `return nil` |
| PT-CR-006 | 連続演算子 "100++200" | ✅ Pass | L81: `expression.contains("++")` → `return nil` |
| PT-CR-007 | 不正文字 "abc" | ✅ Pass | L71: validChars.inverted にヒット → `return nil` |
| PT-CR-008 | 負の結果 "100-200" | ✅ Pass | L89: `intValue = -100` → `intValue >= 0` は false → `return "0"` |
| PT-CR-009 | パーセント "1000％" | ✅ Pass | L68: `％` → `/100` に置換 → NSExpression("1000/100") → 10 |

### 2.3 TransactionService

| ID | テスト項目 | 結果 | 根拠 |
|----|----------|:----:|------|
| PT-TS-001 | 支出追加で予算残高減少 | ✅ Pass | `addExpense` L38-47: isIOU=false → category.spentAmount += amount, budget.spentAmount += amount |
| PT-TS-002 | 立替追加で予算不変 | ✅ Pass | `addExpense` L32-37: isIOU=true → IOURecord作成のみ、category/budgetのspentAmountは変化しない |
| PT-TS-003 | カテゴリ予算も連動 | ✅ Pass | L39-41: `category.spentAmount += amount` |
| PT-TS-004 | 削除で予算復元 | ⚠️ **要確認** | `deleteTransaction` L178-188: isIOU=false の支出は正しく復元。**ただし isIOU=true の立替を削除した場合も `budget.spentAmount -= amount` される（L181）。これはBudgetに加算されていないのに減算するバグの可能性あり** |
| PT-TS-005 | 月跨ぎ借金繰越 | ✅ Pass | `processMonthlyReview` L75-84: overAmount計算 → initialSpent として次月に繰越 |
| PT-TS-006 | 臨時収入でtotalAmount増加 | ✅ Pass | `addIncome` L62: `budget.totalAmount += amount` |
| PT-TS-007 | 更新で差分反映 | ⚠️ **要確認** | `updateExpense` L114-142: 旧amount取消→新amount適用。**ただし isIOU の考慮がなく、IOU→通常支出の切替時にBudget整合性が崩れる可能性あり** |

---

## 3. IT（結合テスト）結果

| ID | テスト項目 | 結果 | 根拠 |
|----|----------|:----:|------|
| IT-001 | 支出入力→ダッシュボード反映 | ✅ Pass | QuickInputVM.logExpense() → TransactionService.addExpense() → DashboardVM.fetchData() で recentTransactions に含まれる |
| IT-002 | カテゴリ予算も連動 | ✅ Pass | addExpense 内で category.spentAmount += amount |
| IT-003 | 臨時収入→ダッシュボード連動 | ✅ Pass | addIncome → budget.totalAmount += amount → fetchData で反映 |
| IT-004 | 立替2段入力の保存と表示 | ✅ Pass | addExpense(isIOU:false) で自己支出分が保存 → DashboardVM.fetchData の recentTransactions に含まれる（isFixedCost==false のため表示対象） |
| IT-005 | 立替分は予算に影響しない | ✅ Pass | addExpense(isIOU:true) のパスでは budget.spentAmount を加算しない |
| IT-006 | 立替分が履歴に表示される | ✅ Pass | TransactionHistoryVM.fetchData は isFixedCost==false の全件を取得（isIOU も含む） |
| IT-007 | 支出編集で差分反映 | ⚠️ **要確認** | updateExpense は旧額を取消し新額を加算するが、isIOU の判定がない（PT-TS-007 と同じ問題） |
| IT-008 | 支出削除で予算復元 | ⚠️ **要確認** | PT-TS-004 と同じ問題。IOU削除時に誤減算の可能性 |
| IT-009 | 固定費は履歴から削除不可 | ✅ Pass | TransactionHistoryVM.deleteTransaction で `guard !item.isFixedCost` |
| IT-010 | 月次レビュー実行 | ✅ Pass | processMonthlyReview で次月Budget生成、借金繰越 |
| IT-011 | 借金回収処理 | ✅ Pass | recoverDebt でsource.totalAmount減額、target.spentAmount減額 |
| IT-012 | カテゴリ追加 | ✅ Pass | ConfigurationVM でcontext.insert → DashboardVM.fetchData で反映 |
| IT-013 | 固定費追加→トランザクション生成 | ✅ Pass | ConfigurationVM.saveConfiguration 内で FixedCostSetting → ExpenseTransaction(isFixedCost:true) を生成 |
| IT-014 | 予算額変更 | ✅ Pass | budget.totalAmount の変更 → remainingAmount(@Transient)が連動 |

---

## 4. ST（システムテスト）結果

| ID | テスト項目 | 結果 | 備考 |
|----|----------|:----:|------|
| ST-001〜ST-010 | 全ケース | ⏸ 未実施 | シミュレータ/実機での手動操作が必要。ユーザーによる実施待ち |

---

## 5. 発見された不具合・改善事項

### 🐛 BUG-001: deleteTransaction が IOU 削除時に Budget.spentAmount を誤減算する

| 項目 | 内容 |
|------|------|
| 重要度 | 中 |
| 該当ファイル | `TransactionService.swift` L178-181 |
| 内容 | `deleteTransaction` で isIOU=true のトランザクションを削除した場合、`budget.spentAmount -= amount` が実行される。しかし isIOU=true の追加時（`addExpense`）では budget.spentAmount に加算していないため、削除時に減算すると整合性が崩れる |
| 影響 | IOU削除後に予算残高が実際より多く表示される |
| 修正案 | L178 の分岐に `!transaction.isIOU` の条件を追加する |

### 🐛 BUG-002: updateExpense が IOU フラグを考慮しない

| 項目 | 内容 |
|------|------|
| 重要度 | 低（現在IOU編集のUI操作パスが限定的） |
| 該当ファイル | `TransactionService.swift` L110-145 |
| 内容 | `updateExpense` は旧金額を一律で `budget.spentAmount -= oldAmount` し、新金額を `budget.spentAmount += amount` する。isIOU の旧→新の変更パターンが考慮されていない |
| 影響 | IOU→通常支出 or 通常支出→IOU に変更した場合に Budget の整合性が崩れる |
| 修正案 | 旧isIOU/新isIOU に応じて加減算を分岐させる |

---

## 6. サマリ

| テストレベル | 総数 | Pass | 要確認 | 未実施 | Pass率 |
|-------------|------|------|--------|--------|--------|
| PT | 16 | 14 | 2 | 0 | 87.5% |
| IT | 14 | 12 | 2 | 0 | 85.7% |
| ST | 10 | 0 | 0 | 10 | - |
| **合計** | **40** | **26** | **4** | **10** | **86.7%**（実施分） |

> [!WARNING]
> BUG-001（IOU削除時の予算誤減算）は実運用で影響があるため、早期修正を推奨します。
