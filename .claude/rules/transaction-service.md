---
description: TransactionService.swiftに適用される特別ルール（既知バグへの注意）
paths:
  - "NoLookBudget/NoLookBudget/Services/TransactionService.swift"
---

# TransactionService 編集時の注意事項

## ⚠️ 既知バグ（必ず確認・修正すること）

### BUG-001（重要度:中）
`deleteTransaction` メソッドでisIOU=trueのトランザクション削除時に `budget.spentAmount -= amount` が誤実行される。
- **修正**: `if !transaction.isIOU { budget.spentAmount -= amount }` の条件を追加

### BUG-002（重要度:低）
`updateExpense` メソッドがisIOUフラグを考慮せず一律で budget.spentAmount を加減算する。
- **修正**: 旧/新のisIOUの組み合わせ4パターンで分岐させる

## isIOUロジックの原則
- `addExpense(isIOU: false)` → `budget.spentAmount += amount`（予算に影響する）
- `addExpense(isIOU: true)` → `budget.spentAmount` は**変更しない**（予算に影響しない）
- 削除・更新時も上記の対称性を必ず保つこと

## テスト要件
このファイルを変更した場合、`NoLookBudgetTests/` に対応するテストを追加・更新すること。
