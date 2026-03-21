# Orbit Budget テスト結果報告書 (改訂版)

| 項目 | 内容 |
|------|------|
| 実施日 | 2026-03-16 |
| 実施者 | 開発エージェント (Claude Code) |
| 実施方法 | コードレビューベースの静的検証（前回比較・バグ修正確認） |
| 前回レポート | docs/QA/test_results_20260306.md |

---

## 1. 前回報告バグの対応状況

### ✅ BUG-001: deleteTransaction が IOU 削除時に Budget.spentAmount を誤減算する
**→ 修正済み（2026-03-06以降の実装で対応）**

現在のコード（`TransactionService.swift` L191）:
```swift
} else if !transaction.isIOU {
    // 通常支出の場合のみ予算を復元する（立替は予算に影響していないため復元不要）
```
`!transaction.isIOU` の条件が追加されており、IOU削除時に Budget.spentAmount を変更しない実装になっている。

### ✅ BUG-002: updateExpense が IOU フラグを考慮しない
**→ 修正済み（2026-03-06以降の実装で対応）**

現在のコード（`TransactionService.swift` L128-157）:
```swift
if !oldIsIOU {
    // 旧が通常支出の場合のみ、Budget・Categoryから差し戻す
    ...
}
if !isIOU {
    // 新が通常支出の場合のみ、Budget・Categoryに加算
    ...
}
```
旧isIOU / 新isIOU の両方を考慮した実装になっており、4パターン全て正しく処理される。

---

## 2. テストファイル構成（2026-03-16時点）

| ファイル | テスト対象 | テスト種別 |
|---------|----------|-----------|
| `TransactionServiceTests.swift` | TransactionService（CRUD・月次処理） | PT |
| `QuickInputViewModelTests.swift` | calculateResult / logExpense | PT |
| `IntegrationTests.swift` | サービス横断データフロー | IT |

---

## 3. PT（プログラムテスト）結果

### 3.1 TransactionService（静的検証）

| ID | テスト名 | 判定 | 根拠 |
|----|---------|:----:|------|
| PT-TS-001 | 通常支出追加で Budget.spentAmount 増加 | ✅ Pass | `addExpense(isIOU:false)` で `budget.spentAmount += amount` |
| PT-TS-002 | IOU追加で Budget.spentAmount 変化なし | ✅ Pass | `isIOU=true` パスでは budget 加算なし |
| PT-TS-003 | 通常支出追加で Category.spentAmount も増加 | ✅ Pass | `category.spentAmount += amount` |
| PT-TS-004a | 通常支出削除で Budget・Category 復元 | ✅ Pass | `else if !transaction.isIOU` で正しく復元 |
| PT-TS-004b | IOU削除で Budget.spentAmount 変化なし | ✅ Pass | `else if !transaction.isIOU` により IOU は復元処理をスキップ（BUG-001修正済み） |
| PT-TS-005 | 月跨ぎ借金繰越で次月 spentAmount に加算 | ✅ Pass | `processMonthlyReview` で `initialSpent = overAmount` |
| PT-TS-006 | 臨時収入追加で Budget.totalAmount 増加 | ✅ Pass | `budget.totalAmount += amount` |
| PT-TS-007a | 通常→通常の更新で差分反映 | ✅ Pass | 旧取消し→新加算の2ステップで正しく差分適用 |
| PT-TS-007b | IOU→通常の更新で Budget に加算（BUG-002） | ✅ Pass | `if !oldIsIOU` / `if !isIOU` による4パターン分岐（修正済み） |
| PT-TS-007c | 通常→IOUの更新で Budget から取消（BUG-002） | ✅ Pass | 旧通常分が取り消され、新IOU分は加算されない |
| PT-TS-Extra | 臨時収入削除で totalAmount 復元 | ✅ Pass | `transaction.isIncome` で `budget.totalAmount -= amount` |
| PT-TS-Extra | 臨時収入更新で差分が totalAmount に反映 | ✅ Pass | `diff = amount - oldAmount` → `budget.totalAmount += diff` |
| PT-TS-Extra | recoverDebt で source/target カテゴリ調整 | ✅ Pass | `sourceCat.totalAmount -= amount` / `targetCat.spentAmount -= amount` |
| PT-TS-Extra | 金額0の支出は保存されない | ✅ Pass | `guard amount > 0 else { return }` |
| PT-TS-Extra | 複数支出の合算が正しく累積 | ✅ Pass | `+=` による累積ロジック |

### 3.2 calculateResult（静的検証）

| ID | テスト名 | 判定 | 根拠 |
|----|---------|:----:|------|
| PT-CR-001 | 単純数値 "500" → "500" | ✅ Pass | NSExpression評価 |
| PT-CR-002 | 加算 "100+200" → "300" | ✅ Pass | NSExpression評価 |
| PT-CR-003 | 掛け算 "100×3" → "300" | ✅ Pass | `×` → `*` 置換後にNSExpression評価 |
| PT-CR-004 | 割り算 "300÷3" → "100" | ✅ Pass | `÷` → `/` 置換後にNSExpression評価 |
| PT-CR-005 | 末尾演算子 "100+" → nil | ✅ Pass | `"+-*/.".contains(last)` チェック |
| PT-CR-006 | 連続演算子 "100++" → nil | ✅ Pass | `expression.contains("++")` チェック |
| PT-CR-007 | 不正文字 "abc" → nil | ✅ Pass | validChars.inverted チェック |
| PT-CR-008 | 負の結果 "100-200" → "0" | ✅ Pass | `intValue >= 0 ? "\(intValue)" : "0"` |
| PT-CR-009 | パーセント "1000％" → "10" | ✅ Pass | `％` → `/100` 置換後にNSExpression評価 |

### 3.3 logExpense（静的検証）

| ID | テスト名 | 判定 | 根拠 |
|----|---------|:----:|------|
| PT-QI-001 | 通常支出の保存（return true） | ✅ Pass | `calculateResult()` > 0 → `addExpense(isIOU:false)` → true |
| PT-QI-002 | 金額0では保存されない（return false） | ✅ Pass | `guard let amount = ... , amount > 0 else { return false }` |
| PT-QI-003 | 2段入力（IOU=3000, 自己=2000）の正常保存 | ✅ Pass | `actualIOUAmount = 5000-2000 = 3000` → 2件保存 |
| PT-QI-004 | VLD-101: 自己支出未入力（"0"）でエラー | ✅ Pass | `myExpenseExpression == "0"` → showAlert |
| PT-QI-005 | VLD-102: 総額 < 自己支出でエラー | ✅ Pass | `totalAmount < myExpenseAmount` → showAlert |
| PT-QI-006 | 自己支出 "0+0" はバリデーション通過 | ✅ Pass | `"0+0" ≠ "0"` → IOU(5000)のみ保存 |
| PT-QI-007 | 臨時収入の保存 | ✅ Pass | `inputMode == .income` → `addIncome(amount)` |

---

## 4. IT（結合テスト）結果

| ID | テスト名 | 判定 | 根拠 |
|----|---------|:----:|------|
| IT-001 | 支出登録 → Budget.spentAmount 反映 | ✅ Pass | addExpense → budget.spentAmount 連動 |
| IT-002 | カテゴリ予算も連動 | ✅ Pass | addExpense → category.spentAmount 連動 |
| IT-003 | 臨時収入 → Budget.totalAmount 連動 | ✅ Pass | addIncome → budget.totalAmount 連動 |
| IT-004 | 立替2段入力の保存と分離 | ✅ Pass | IOU(3000) + 通常(2000) の2件保存、Budget は 2000 のみ反映 |
| IT-005 | 立替は Budget に影響しない | ✅ Pass | addExpense(isIOU:true) で budget/category 未更新 |
| IT-006 | 立替が ExpenseTransaction に保存される | ✅ Pass | isIOU=true でも ExpenseTransaction に保存 |
| IT-007 | 支出編集で差分反映 | ✅ Pass | updateExpense で旧取消→新加算（BUG-002修正済み） |
| IT-008 | IOU削除で Budget 変化なし | ✅ Pass | deleteTransaction で !isIOU 条件（BUG-001修正済み） |
| IT-009 | 固定費フラグが正しく設定される | ✅ Pass | isFixedCost=true で保存（UIガードは ViewModel レイヤー） |
| IT-010 | 月次レビューで次月 Budget 作成・借金繰越 | ✅ Pass | processMonthlyReview → nextBudget.spentAmount = overAmount |
| IT-011 | 借金回収で source/target カテゴリ調整 | ✅ Pass | recoverDebt → source.totalAmount--, target.spentAmount-- |
| IT-012 | カテゴリ追加の永続化 | ✅ Pass | context.insert → fetch で取得可能 |
| IT-013 | 固定費追加 → isFixedCost=true のトランザクション生成 | ✅ Pass | ExpenseTransaction(isFixedCost:true) で保存 |
| IT-014 | 予算額変更で remainingAmount 連動 | ✅ Pass | @Transient の `totalAmount - spentAmount` が自動更新 |

---

## 5. ST（システムテスト）

| ID | テスト項目 | 結果 |
|----|----------|:----:|
| ST-001〜010 | 全ケース | ⏸ 未実施 |

> シミュレータ/実機での手動操作が必要。ユーザーによる実施待ち。

---

## 6. サマリ

| テストレベル | 総数 | Pass | 要確認 | 未実施 | Pass率 |
|-------------|------|------|--------|--------|--------|
| PT（TransactionService） | 15 | 15 | 0 | 0 | **100%** |
| PT（calculateResult） | 9 | 9 | 0 | 0 | **100%** |
| PT（logExpense） | 7 | 7 | 0 | 0 | **100%** |
| IT | 14 | 14 | 0 | 0 | **100%** |
| ST | 10 | 0 | 0 | 10 | - |
| **合計** | **55** | **45** | **0** | **10** | **100%**（実施分） |

> **前回（2026-03-06）比較: Pass率 86.7% → 100% に改善。BUG-001・BUG-002 は修正済み確認。**
