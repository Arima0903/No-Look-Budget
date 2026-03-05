# No-Look-Budget 詳細設計書

| 項目 | 内容 |
|------|------|
| ドキュメントID | DD-001 |
| バージョン | 1.0 |
| 最終更新日 | 2026-03-06 |
| 対応基本設計 | BD-001 |

---

## 1. クラス設計

### 1.1 Model層

基本設計書 §2 に定義したエンティティを SwiftData `@Model` マクロで実装する。
各エンティティはファイル単位で分離する。

| ファイル | クラス | 責務 |
|----------|--------|------|
| `Budget.swift` | `Budget` | 月次予算の管理 |
| `Budget.swift` | `FixedCostSetting` | 固定費テンプレートの管理 |
| `ItemCategory.swift` | `ItemCategory` | 支出カテゴリの管理 |
| `ExpenseTransaction.swift` | `ExpenseTransaction` | 取引履歴の管理 |
| `IOURecord.swift` | `IOURecord` | 立替プールの管理 |
| `SharedModelContainer.swift` | `SharedModelContainer` | App Group対応のSwiftDataコンテナ共有 |

### 1.2 Service層

| ファイル | プロトコル/クラス | メソッド | 責務 |
|----------|------------------|---------|------|
| `TransactionService.swift` | `TransactionServiceProtocol` | (下記参照) | CRUD操作のインターフェース |
| `TransactionService.swift` | `TransactionService` | (下記参照) | 具象実装 |

#### TransactionServiceProtocol メソッド一覧

| メソッド | 引数 | 戻り値 | 説明 |
|----------|------|--------|------|
| `addExpense` | `amount: Double, category: ItemCategory?, isIOU: Bool` | `throws` | 支出/立替の追加 |
| `addIncome` | `amount: Double` | `throws` | 臨時収入の追加 |
| `processMonthlyReview` | `currentDate: Date` | `throws` | 月跨ぎ処理 |
| `recoverDebt` | `sourceCategoryName, targetCategoryName, amount` | `throws` | 借金回収 |
| `updateExpense` | `id: UUID, amount, category, isIOU` | `throws` | 支出の更新 |
| `updateIncome` | `id: UUID, amount: Double` | `throws` | 収入の更新 |
| `deleteTransaction` | `id: UUID` | `throws` | トランザクション削除と予算復元 |

### 1.3 ViewModel層

| ファイル | クラス | 対応画面 | 責務 |
|----------|--------|---------|------|
| `DashboardViewModel.swift` | `DashboardViewModel` | SCR-001 | 予算データ取得・表示状態管理・推移グラフ生成 |
| `QuickInputViewModel.swift` | `QuickInputViewModel` | SCR-002 | 入力式管理・バリデーション・保存処理 |
| `TransactionHistoryViewModel.swift` | `TransactionHistoryViewModel` | SCR-003 | 履歴データ取得・削除 |
| `CategoryDetailViewModel.swift` | `CategoryDetailViewModel` | SCR-004 | カテゴリ別履歴・予算表示 |
| `IOUViewModel.swift` | `IOUViewModel` | SCR-005 | 立替一覧・回収処理 |
| `MonthlyReviewViewModel.swift` | `MonthlyReviewViewModel` | SCR-006 | 月末レビューデータ・次月処理 |
| `ConfigurationViewModel.swift` | `ConfigurationViewModel` | SCR-007/008 | 予算設定・カテゴリCRUD・固定費同期 |
| `DebtRecoveryViewModel.swift` | `DebtRecoveryViewModel` | (ダイアログ) | 借金回収ソース選択 |

---

## 2. 処理詳細設計

### 2.1 QuickInputViewModel — 立替2段入力の保存処理

```swift
func logExpense() -> Bool {
    // ① IOUモード判定
    guard inputMode == .expense && isIOUMode else {
        // 通常の1段入力処理へ分岐
        return handleNormalExpense()
    }

    // ② 計算結果の取得
    let totalAmount = calculateResult(for: iouExpression) -> Double
    let myExpenseAmount = calculateResult(for: myExpenseExpression) -> Double

    // ③ バリデーション (VLD-101)
    if myExpenseExpression == "0" {
        showAlert("自分の支出額を入力してください")
        return false
    }

    // ④ バリデーション (VLD-102)
    if totalAmount < myExpenseAmount {
        showAlert("立替総額が自分の支出額より小さくなっています")
        return false
    }

    // ⑤ 実立替金の算出
    let actualIOUAmount = totalAmount - myExpenseAmount

    // ⑥ トランザクション生成
    if actualIOUAmount > 0 {
        transactionService.addExpense(amount: actualIOUAmount, isIOU: true)
        // → Budget.spentAmount は変化しない
    }
    if myExpenseAmount > 0 {
        transactionService.addExpense(amount: myExpenseAmount, isIOU: false)
        // → Budget.spentAmount += myExpenseAmount
        // → ItemCategory.spentAmount += myExpenseAmount
    }

    return true
}
```

### 2.2 TransactionService.addExpense — 支出追加処理

```
入力: amount, category, isIOU
処理:
  1. ExpenseTransaction を生成し context に挿入
  2. category が指定されている場合:
     category.spentAmount += amount
  3. isIOU == false の場合のみ:
     Budget(当月).spentAmount += amount
  4. context.save()
  5. WidgetCenter.shared.reloadAllTimelines()
```

### 2.3 TransactionService.deleteTransaction — 削除と復元

```
入力: id (UUID)
処理:
  1. id で ExpenseTransaction を検索
  2. isIncome == true の場合:
     Budget.totalAmount -= amount
  3. isIOU == false && isIncome == false の場合:
     Budget.spentAmount -= amount
  4. categoryId があれば:
     ItemCategory.spentAmount -= amount
  5. context.delete(transaction)
  6. context.save()
  7. reloadWidgets()
```

### 2.4 calculateResult — 計算式評価

```
入力: expressionText (String)
処理:
  1. 記号置換: "×"→"*", "÷"→"/", "％"→"/100"
  2. 文字種チェック: [0-9+-*/.() ] 以外 → nil
  3. 末尾チェック: 末尾が演算子/小数点 → nil
  4. 連続演算子チェック → nil
  5. NSExpression(format:) で評価
  6. 結果が負数なら "0" を返す
戻り値: 計算結果の文字列 or nil
```

---

## 3. UI部品設計

### 3.1 入力モーダル (QuickInputModalView)

#### 通常モード

```
┌──────────────────────────────┐
│ [×]   [支出|臨時収入]  [立替] │  ← ヘッダー
├──────────────────────────────┤
│                        金額  │  ← 1段入力表示
│                     = ¥計算  │
├──────────────────────────────┤
│ [食費] [交際費] [変動費]      │  ← カテゴリ選択
│ [    ] [    ] [    ]         │
├──────────────────────────────┤
│ [C ] [％] [÷] [⌫]           │  ← キーパッド
│ [7 ] [8 ] [9 ] [×]          │
│ [4 ] [5 ] [6 ] [- ]          │
│ [1 ] [2 ] [3 ] [+ ]          │
│ [0 ] [00] [. ] [=使う]       │
└──────────────────────────────┘
```

#### 立替モード

```
┌──────────────────────────────┐
│ [×]   [支出|臨時収入]  [立替] │  ← オレンジグロー背景
├──────────────────────────────┤
│ みんなの立替分        金額   │  ← 上段（タップでフォーカス）
│ 自分自身の支出        金額   │  ← 下段（タップでフォーカス）
├──────────────────────────────┤
│ [食費] [交際費] [変動費]      │  ← カテゴリ選択
├──────────────────────────────┤
│         (キーパッド)          │  ← activeBindingで対象切替
└──────────────────────────────┘
```

### 3.2 フォーカス管理

| 状態 | 上段（IOU） | 下段（自己支出） |
|------|------------|----------------|
| `currentFocus == .iou` | オレンジ枠線・オレンジ文字 | グレー文字・枠線なし |
| `currentFocus == .myExpense` | グレー文字・枠線なし | 白枠線・白文字 |

キーパッドの `Binding<String>` は `currentFocus` に応じて `iouExpression` または `myExpenseExpression` に動的バインドする。

---

## 4. エラーハンドリング設計

### 4.1 バリデーションエラー

| ID | 契機 | 表示方法 | アクション |
|----|------|---------|-----------|
| VLD-101 | 立替確定時に自己支出未入力 | Alert ダイアログ | OK で閉じる、モーダルは閉じない |
| VLD-102 | 立替確定時に総額 < 自己支出 | Alert ダイアログ | OK で閉じる、モーダルは閉じない |

### 4.2 データベースエラー

| 契機 | 処理 |
|------|------|
| SwiftData save失敗 | `try?` で握りつぶし（現状）。将来的にはユーザーフレンドリーなアラート表示に改善予定 |

---

## 5. 計算式キーパッド仕様

### 5.1 ボタン配置

| 行 | ボタン1 | ボタン2 | ボタン3 | ボタン4 |
|----|---------|---------|---------|---------|
| 1 | C | ％ | ÷ | ⌫ |
| 2 | 7 | 8 | 9 | × |
| 3 | 4 | 5 | 6 | - |
| 4 | 1 | 2 | 3 | + |
| 5 | 0 | 00 | . | = |

### 5.2 ボタン挙動

| ボタン | 挙動 |
|--------|------|
| C | 式を `"0"` にリセット |
| ⌫ | 末尾1文字削除。1文字の場合は `"0"` に |
| = | `onCommit()` を呼び出し（保存処理実行） |
| 演算子 | 末尾が既に演算子なら置換。式は最大15文字 |
| 数字 | 現在値が `"0"` なら置換、それ以外は末尾追加 |
