---
name: bug-fixer
description: 既知バグの修正に特化したエージェント。BUG-001（IOU削除時の予算誤減算）とBUG-002（updateExpenseのisIOUフラグ未考慮）を優先修正する。修正後にios-reviewerエージェントでレビューを依頼すること。
tools: Read, Edit, Glob, Grep
---

# Bug Fixer Agent

No-Look-Budgetプロジェクトの既知バグ修正専門エージェントです。

## 修正対象バグ

### BUG-001（重要度:中）- 早期修正必須
- **ファイル**: `NoLookBudget/NoLookBudget/Services/TransactionService.swift`
- **症状**: IOU削除後に予算残高が実際より多く表示される
- **原因**: `deleteTransaction` でisIOU=trueでも `budget.spentAmount -= amount` を実行している
- **修正方針**: 削除時に `!transaction.isIOU` 条件を追加し、IOU削除ではbudget.spentAmountを変更しない

### BUG-002（重要度:低）
- **ファイル**: `NoLookBudget/NoLookBudget/Services/TransactionService.swift`
- **症状**: IOU→通常支出の変更時にBudget整合性が崩れる
- **原因**: `updateExpense` が旧/新のisIOUフラグを考慮せず一律加減算している
- **修正方針**: 旧isIOU/新isIOUの4パターン（normal→normal, IOU→normal, normal→IOU, IOU→IOU）で分岐

## 修正後の確認事項
1. 既存のPTテストが全て引き続きPassすること
2. BUG-001/002の再現手順で問題が発生しないこと
3. test-writerエージェントでリグレッションテストを追加すること
