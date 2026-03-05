# No-Look-Budget 詳細設計書

| 項目 | 内容 |
|------|------|
| ドキュメントID | DD-001 |
| バージョン | 2.0 |
| 最終更新日 | 2026-03-06 |
| 対応基本設計 | BD-001 |

## 改版履歴

| バージョン | 日付 | 変更内容 | 変更者 |
|-----------|------|---------|--------|
| 1.0 | 2026-03-06 | 初版作成 | 開発チーム |
| 2.0 | 2026-03-06 | deleteTransaction/updateExpenseのIOU判定追加、境界値・エッジケース仕様追加、ViewModel状態一覧表追加 | 開発チーム |

---

## 1. クラス設計

### 1.1 Model層

基本設計書 §2 に定義したエンティティを SwiftData `@Model` マクロで実装する。

| ファイル | クラス | 責務 |
|----------|--------|------|
| `Budget.swift` | `Budget` | 月次予算の管理 |
| `Budget.swift` | `FixedCostSetting` | 固定費テンプレートの管理 |
| `ItemCategory.swift` | `ItemCategory` | 支出カテゴリの管理 |
| `ExpenseTransaction.swift` | `ExpenseTransaction` | 取引履歴の管理 |
| `IOURecord.swift` | `IOURecord` | 立替プールの管理 |
| `SharedModelContainer.swift` | `SharedModelContainer` | App Group対応のSwiftDataコンテナ共有 |

### 1.2 Service層

#### TransactionServiceProtocol メソッド一覧

| メソッド | 引数 | 戻り値 | 対応要件 | 説明 |
|----------|------|--------|---------|------|
| `addExpense` | `amount: Double, category: ItemCategory?, isIOU: Bool` | `throws` | FR-001,002 | 支出/立替の追加 |
| `addIncome` | `amount: Double` | `throws` | FR-003 | 臨時収入の追加 |
| `processMonthlyReview` | `currentDate: Date` | `throws` | FR-008 | 月跨ぎ処理 |
| `recoverDebt` | `sourceCategoryName, targetCategoryName, amount` | `throws` | FR-008 | 借金回収 |
| `updateExpense` | `id: UUID, amount, category, isIOU` | `throws` | FR-005 | 支出の更新（isIOU考慮） |
| `updateIncome` | `id: UUID, amount: Double` | `throws` | FR-005 | 収入の更新 |
| `deleteTransaction` | `id: UUID` | `throws` | FR-005 | トランザクション削除と予算復元（isIOU考慮） |

### 1.3 ViewModel層

| ファイル | クラス | 対応画面 | 主要@Published プロパティ |
|----------|--------|---------|--------------------------|
| `QuickInputViewModel.swift` | `QuickInputViewModel` | SCR-002 | `expressionText`, `iouExpression`, `myExpenseExpression`, `currentFocus`, `inputMode`, `isIOUMode`, `showAlert`, `alertMessage` |
| `DashboardViewModel.swift` | `DashboardViewModel` | SCR-001 | `currentBudget`, `categories`, `recentTransactions`, `dailySpending` |
| `TransactionHistoryViewModel.swift` | `TransactionHistoryViewModel` | SCR-003 | `transactions` |
| `CategoryDetailViewModel.swift` | `CategoryDetailViewModel` | SCR-004 | `category`, `transactions` |
| `IOUViewModel.swift` | `IOUViewModel` | SCR-005 | `unresolvedIOUs`, `resolvedIOUs` |
| `MonthlyReviewViewModel.swift` | `MonthlyReviewViewModel` | SCR-006 | `currentBudget`, `overAmount` |
| `ConfigurationViewModel.swift` | `ConfigurationViewModel` | SCR-007/008 | `budget`, `categories`, `fixedCosts` |
| `DebtRecoveryViewModel.swift` | `DebtRecoveryViewModel` | (ダイアログ) | `sourceCategories` |

---

## 2. 処理詳細設計

### 2.1 addExpense — 支出/立替追加

```
入力: amount, category, isIOU
前提条件: amount > 0

処理:
  1. ExpenseTransaction(amount, categoryId, isIOU, isIncome=false) を生成
  2. if isIOU == true:
       IOURecord(amount, title=category.name) を生成
       → Budget / Category への影響なし
  3. if isIOU == false:
       if category != nil:
         category.spentAmount += amount
       Budget(最新月).spentAmount += amount
  4. context.save()
  5. WidgetCenter.shared.reloadAllTimelines()
```

### 2.2 deleteTransaction — 削除と予算復元

```
入力: id (UUID)
処理:
  1. id で ExpenseTransaction を検索
  2. 分岐:
     ┌─ isIncome == true:
     │    Budget.totalAmount -= amount (min: 0)
     ├─ isIOU == false && isIncome == false:
     │    Budget.spentAmount -= amount (min: 0)
     │    Category.spentAmount -= amount (min: 0)
     └─ isIOU == true:
          → Budget / Category への復元処理なし
  3. context.delete(transaction)
  4. context.save()
  5. reloadWidgets()
```

### 2.3 updateExpense — 支出更新（isIOU考慮）

```
入力: id, amount, category, isIOU
処理:
  1. id で既存トランザクションを検索
  2. 旧isIOUの値を保存 (oldIsIOU = transaction.isIOU)
  3. if oldIsIOU == false:
       旧金額をBudget / Categoryから差し戻す
  4. トランザクションを更新 (amount, categoryId, isIOU)
  5. if isIOU == false:
       新金額をBudget / Categoryに加算
  6. context.save()
  7. reloadWidgets()
```

### 2.4 logExpense (QuickInputViewModel) — 立替2段入力保存

```swift
func logExpense() -> Bool {
    // ① IOUモード判定
    guard inputMode == .expense && isIOUMode else {
        return handleNormalExpense()
    }

    // ② 計算結果の取得
    let totalAmount = calculateResult(for: iouExpression)
    let myExpenseAmount = calculateResult(for: myExpenseExpression)

    // ③ バリデーション (VLD-101): 初期値"0"は未入力扱い
    if myExpenseExpression == "0" {
        showAlert("自分の支出額を入力してください")
        return false
    }

    // ④ バリデーション (VLD-102): 総額 >= 自己支出
    if totalAmount < myExpenseAmount {
        showAlert("立替総額が自分の支出額より小さくなっています")
        return false
    }

    // ⑤ トランザクション生成（2件）
    let actualIOUAmount = totalAmount - myExpenseAmount
    if actualIOUAmount > 0:
        addExpense(amount: actualIOUAmount, isIOU: true)
    if myExpenseAmount > 0:
        addExpense(amount: myExpenseAmount, isIOU: false)

    return true
}
```

### 2.5 calculateResult — 計算式評価

```
入力: expressionText (String)
処理:
  1. 記号置換: "×"→"*", "÷"→"/", "％"→"/100"
  2. 文字種チェック: [0-9+-*/.() ] 以外 → nil
  3. 末尾チェック: 末尾が演算子/小数点 → nil
  4. 連続演算子チェック (++, --, **, //, +-, -+, */, /*) → nil
  5. NSExpression(format:) で評価
  6. 結果が負数なら "0" を返す
戻り値: 計算結果の文字列 or nil
```

#### 境界値・エッジケース仕様

| 入力 | 期待結果 | 理由 |
|------|---------|------|
| "0" | "0" | 正常な数値 |
| "" | nil | 空文字は不正 |
| "999999999999999" | (整数上限に依存) | 15文字制限で入力は防止済み |
| "100-200" | "0" | 負数は0として返す |
| "100." | nil | 末尾小数点は不完全式 |
| "0+0" | "0" | 正常（VLD-101で入力済みとみなされる） |

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
│ [食費] [交際費] [変動費]      │  ← カテゴリ選択 (2行3列)
│ [    ] [    ] [    ]         │
├──────────────────────────────┤
│ [C ] [％] [÷] [⌫]           │  ← キーパッド (5行4列)
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
│ みんなの立替分        金額   │  ← 上段（フォーカス時: 橙枠・橙文字）
│ 自分自身の支出        金額   │  ← 下段（フォーカス時: 白枠・白文字）
├──────────────────────────────┤
│ 対象のカテゴリ(立替用)       │  ← ラベル変化
│ [食費] [交際費] [変動費]      │
├──────────────────────────────┤
│         (キーパッド)          │  ← activeBindingで対象切替
│         [=立替]              │  ← ボタン文言変化
└──────────────────────────────┘
```

### 3.2 フォーカス管理

| 状態 | 上段（立替分） | 下段（自己支出） | キーパッドBindingの対象 |
|------|-------------|----------------|----------------------|
| `currentFocus == .iou` | オレンジ枠線・オレンジ文字・背景強調 | グレー文字・枠線なし | `iouExpression` |
| `currentFocus == .myExpense` | グレー文字・枠線なし | 白枠線・白文字・背景強調 | `myExpenseExpression` |

### 3.3 確定ボタンの動的テキスト

| inputMode | isIOUMode | isEditing | ボタン表示 |
|-----------|:---------:|:---------:|-----------|
| expense | false | false | 「使う」 |
| expense | true | false | 「立替」 |
| income | - | false | 「追加」 |
| - | - | true | 「更新」 |

---

## 4. エラーハンドリング設計

### 4.1 バリデーションエラー

| ID | 契機 | 表示方法 | ユーザーアクション | 画面挙動 |
|----|------|---------|-----------------|---------|
| VLD-101 | 立替確定時に自己支出が初期値"0"のまま | Alert ダイアログ | OK をタップ | モーダルは閉じない。再入力可能 |
| VLD-102 | 立替確定時に立替総額 < 自己支出 | Alert ダイアログ | OK をタップ | モーダルは閉じない。再入力可能 |

### 4.2 データベースエラー

| 契機 | 現状の処理 | 改善予定 |
|------|-----------|---------|
| SwiftData context.save() 失敗 | `try?` で握りつぶし | ユーザーフレンドリーなAlert表示 |
| SwiftData fetch 失敗 | `try?` で空配列/nil返却 | ログ出力の追加 |

---

## 5. 計算式キーパッド仕様

### 5.1 ボタン配置

| 行 | Col1 | Col2 | Col3 | Col4 |
|----|------|------|------|------|
| 1 | C | ％ | ÷ | ⌫ |
| 2 | 7 | 8 | 9 | × |
| 3 | 4 | 5 | 6 | - |
| 4 | 1 | 2 | 3 | + |
| 5 | 0 | 00 | . | = |

### 5.2 ボタン挙動

| ボタン | 挙動 | 制約 |
|--------|------|------|
| C | 式を `"0"` にリセット | - |
| ⌫ | 末尾1文字削除。1文字の場合は `"0"` にリセット | - |
| = | `onCommit()` を呼び出し（保存処理実行） | - |
| 演算子 (+,-,×,÷,％,.) | 末尾が既に演算子なら置換 | 式は最大15文字 |
| 数字 (0-9, 00) | 現在値が `"0"` なら置換、それ以外は末尾追加 | 式は最大15文字 |

### 5.3 ボタン色設計

| ボタン種別 | 前景色 | 背景 |
|-----------|--------|------|
| 数字 | 白 | ultraThinMaterial |
| 演算子/機能 | グレー | white.opacity(0.15) |
| C / ⌫ | グレー | white.opacity(0.1) |
| = (通常/収入) | 黒 or 白 | 緑グラデーション |
| = (立替) | 白 | オレンジ→赤グラデーション |
