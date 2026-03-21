---
description: SwiftUI Viewファイルに適用されるコーディングルール
paths:
  - "NoLookBudget/NoLookBudget/Views/**/*.swift"
---

# SwiftUI View コーディングルール

## 必須ルール

### ダークモード強制
`.sheet` / `.fullScreenCover` / `.popover` で呼び出すViewには**必ず** `.preferredColorScheme(.dark)` を付与すること。

```swift
// ✅ 正しい
.sheet(isPresented: $showModal) {
    SomeView()
        .preferredColorScheme(.dark) // 必須
}

// ❌ NG（背景が白くなりテキストが消える）
.sheet(isPresented: $showModal) {
    SomeView()
}
```

### 数値入力禁止
金額などの数値入力に `TextField` + iOS標準キーボードを使用しないこと。`NumberPadModalView` を使うこと。

### ビジネスロジック禁止
View内に直接ビジネスロジックやDB操作を書かないこと。必ずViewModelに委譲する。

```swift
// ✅ 正しい
Button("追加") { viewModel.addExpense() }

// ❌ NG
Button("追加") { context.insert(transaction) }
```

## 推奨パターン
- `@Environment(\.dismiss) var dismiss` でモーダルを閉じる
- Previewを必ず追加する
- 1つのViewファイルは1つの責務のみ
