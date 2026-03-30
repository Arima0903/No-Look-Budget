# CHANGELOG

このファイルは No-Look-Budget プロジェクトの全変更履歴を記録します。
フォーマット: `[日付] 種別 | 変更内容 | 変更理由`

---

## [2026-03-25] — 金額表示の3桁カンマ区切り対応

### 改善

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `Utils/CurrencyFormatter.swift`（新規）, `Views/Main/DashboardView.swift`, `Views/Main/QuickInputModalView.swift`, `ViewModels/QuickInputViewModel.swift`, `Views/Main/CategoryDetailView.swift`, `Views/Main/TransactionHistoryView.swift`, `Views/Review/MonthlyReviewView.swift`, `ViewModels/MonthlyReviewViewModel.swift`, `Views/Settings/BudgetConfigurationView.swift`, `Views/Settings/CategoryConfigurationView.swift` |
| **変更内容** | 共通の `formatCurrency()` ユーティリティ関数を新規作成し、アプリ全体の金額表示を3桁カンマ区切りに統一。ダッシュボード、入力モーダル、カテゴリ詳細、取引履歴、月次レビュー、予算設定、カテゴリ設定の全画面に適用。入力中の計算式（expressionText）はカンマ区切りの対象外 |
| **変更理由** | 大きな金額（例: 150000）の視認性が悪く、ユーザーが桁数を誤認するリスクがあったため |

---

## [2026-03-25] — 入力モーダルからカテゴリ編集画面を直接開けるように

### 機能追加

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Views/Main/QuickInputModalView.swift` |
| **変更内容** | QuickInputModalView の「予算項目を選択」セクションに「編集」ボタンを追加。タップで CategoryConfigurationView をモーダル表示し、カテゴリの追加・編集・削除・並び替えが可能。閉じた後はカテゴリ一覧を自動再取得。収入モード時は編集ボタン非表示 |
| **変更理由** | 入力中にカテゴリを編集したい場合、設定画面まで戻る必要があったためUX改善 |

---

## [2026-03-25] — チュートリアル Step 2 にDuolingo風ウィジェット配置促進UI追加

### 機能追加

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Views/Onboarding/TutorialView.swift` |
| **変更内容** | TutorialView の Step 2（ウィジェット配置）で、通常のナビゲーションボタンの代わりにDuolingo風の半強制UIを表示。大きな緑色CTAボタン「ウィジェットを追加する」をメインに配置し、「あとで」ボタンは意図的に小さく薄く表示。CTAタップ時はアラートで追加手順を案内し、次のステップへ進む。「戻る」ボタンも維持 |
| **変更理由** | ウィジェット配置がアプリのコアバリュー（No-Look Experience）に直結するため、チュートリアル内で強く促すことでウィジェット設置率の向上を狙う |

---

## [2026-03-25] — カテゴリ詳細画面から取引の編集・削除を可能に

### 機能追加

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/ViewModels/CategoryDetailViewModel.swift`, `NoLookBudget/Views/Main/CategoryDetailView.swift` |
| **変更内容** | CategoryDetailView の履歴リストにタップで編集（QuickInputModalView表示）、スワイプで削除の機能を追加。CategoryDetailViewModel に TransactionService を導入し deleteTransaction メソッドを追加。BudgetDetailView と同じ編集パターンを採用 |
| **変更理由** | カテゴリ詳細画面から取引の修正・削除ができず、ダッシュボードに戻る必要があったためUX改善 |

---

## [2026-03-25] — デフォルトカテゴリ6種の自動生成

### 機能追加

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/ViewModels/DashboardViewModel.swift` |
| **変更内容** | `fetchData()` 内でカテゴリが空かつ初回起動時にデフォルトカテゴリ6種（食費・交際費・日用品・趣味・衣服・その他）を自動生成。UserDefaults の `hasCreatedDefaultCategories` フラグで再生成を防止 |
| **変更理由** | 初回起動時にカテゴリが空のため支出入力ができず、ユーザーが設定画面で手動作成する必要があった。UX改善のためデフォルトカテゴリを自動生成する |

---

## [2026-03-17] — ダッシュボードバグ修正（円グラフ・レイアウト・バナー）

### バグ修正

#### BUG-003: 大きい円グラフが常に全緑になる問題

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Views/Main/DashboardView.swift`（`BudgetGaugeView`） |
| **変更内容** | `targetRatio` computed property を追加し、`onChange` の監視対象を `budget?.spentAmount` 単独から `targetRatio`（`spentAmount` / `totalAmount` / `incomeAmount` を統合した計算値）に変更。`updateRatio()` も `targetRatio` を参照するよう統一 |
| **変更理由** | `@Observable` な SwiftData モデルのプロパティ変化をまとめて捕捉できず、ダッシュボード初回表示時に `animatedRatio` が 0 のまま固まっていた |

#### BUG-004: ダッシュボードのコンテンツが見切れる問題

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Views/Main/DashboardView.swift` |
| **変更内容** | メインコンテンツ `VStack` を `ScrollView(showsIndicators: false)` でラップし、全コンテンツをスクロール可能に変更 |
| **変更理由** | ナビゲーションバーの年月セレクタ追加により情報量が増え、カテゴリゲージ2行目が画面外に溢れていた |

#### BUG-005: 「前月の借金」警告バナーが小さい円グラフを押し出す問題

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Views/Main/DashboardView.swift` |
| **変更内容** | 「前月の借金により予算修正が必要です」ボタンを全幅カードから高さ 36pt のコンパクトピル（`caption2` / 横帯）に変更 |
| **変更理由** | フルサイズボタンがカテゴリゲージを画面外に押し出していた |

#### BUG-006: 予算オーバーバナーが円グラフエリアに重なる問題

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Views/Main/DashboardView.swift` |
| **変更内容** | 予算オーバー警告バナーをコンテンツ最上部から「記録をつける」ボタンの直上（円グラフの下）に移動。デザインも全幅カードからコンパクトインラインバナーに変更 |
| **変更理由** | 上部バナーが円グラフ表示領域を圧迫し、円グラフが見えない・バナーが他コンテンツと重なる問題があった |

---

## [2026-03-16] — カレンダー改善・年月セレクタ・ドキュメント整備

### 機能改善

#### IMPR-001: カレンダーの日別支出表示を視認性向上

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Views/Main/CalendarView.swift` |
| **変更内容** | 金額テキストを `size 7 / gray` → `size 9 / white.opacity(0.8)` に変更。支出ゼロ日の空白を小さな Circle ドット（白・低透明度）に変更 |
| **変更理由** | MoneyForward/Zaim 相当の「毎日記録できているか」を視覚的に確認できるようにするため |

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Views/Main/CalendarView.swift` |
| **変更内容** | フレームを `width: 260, height: 260` 固定 → `maxWidth: .infinity`（画面幅いっぱい）に変更 |
| **変更理由** | TabView 内でカレンダーが画面幅を活かせるようにするため |

#### FEAT-004: ホーム画面に年月セレクタを追加（過去月閲覧機能）

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/ViewModels/DashboardViewModel.swift` |
| **変更内容** | `selectedYear` / `selectedMonth` / `isCurrentMonth` / `selectedMonthTitle` を追加。`fetchData()` の `Date()` 固定を除去し選択月を参照するよう変更。過去月閲覧中は Budget 自動作成をしない。recentTransactions のフィルタを選択月の日付範囲に絞り込み |
| **変更理由** | 過去の月のデータを閲覧できるようにするため |

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Views/Main/DashboardView.swift` |
| **変更内容** | Toolbar `.principal` を `◀ 2026年3月 ▶` の年月セレクタに変更。過去月表示中はラベルが warmOrange に。記録ボタンのラベルを `isCurrentMonth ? "記録をつける" : "今月に記録する"` に。TabView 高さを `300 → 340` に拡大。残り予算ラベルも選択月を反映 |
| **変更理由** | 年月セレクタの UI 実装 |

### ドキュメント整備

| 変更内容 | 変更理由 |
|---|---|
| `docs/project/release_roadmap.md` 新規作成 | App Store 公開までの全工程を可視化するため |
| `docs/marketing/ads_monetization_guide.md` 新規作成 | バナー広告による収益化の仕組みと UI 案を整理するため |
| `CHANGELOG.md` 作成 | 機能追加・バグ修正の全変更履歴を記録するため（今後必須） |
| `.claude/agents/` に developer / ui-ux-designer / qa-engineer / release-manager / product-manager を追加 | AgentTeam 体制を構築するため |

---

## [2026-03-16] — Claude Code 引き継ぎセッション

### バグ修正

#### BUG-001: ウィジェットが常に¥250,000を表示する問題
| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudgetWidget/NoLookBudgetWidget.swift` |
| **変更内容** | `getSnapshot()` のハードコード値（250,000 / 100,000）を削除し、SwiftData から実データを取得するよう変更。`getTimeline()` のフォールバック値も `0` に変更 |
| **変更理由** | ウィジェットがスナップショット（ホーム画面プレビュー）でも常にハードコードされたダミーデータを返していたため、実際の予算と支出が反映されなかった |

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Views/Main/DashboardView.swift` |
| **変更内容** | `BudgetGaugeView` の `?? 250000.0` / `?? 100000.0` / `?? 150000` / デフォルト比率 `0.4` をすべて `0` / `0.0` に変更 |
| **変更理由** | 予算未設定時にハードコード値で表示されてしまい、ユーザーに誤った残高を見せていた |

#### BUG-002: 予算設定を開き直すと収入・先取り貯金が0にリセットされる問題
| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/ViewModels/ConfigurationViewModel.swift` |
| **変更内容** | `fetchData()` で当月予算を明示的に検索するよう変更。`saveBudget()` で収入・貯金フィールドが空文字の場合は既存値を保持するよう変更（`?? 0` → nil チェックに変更） |
| **変更理由** | フィールドが空文字のとき `Double("") ?? 0` が `0.0` として評価され、既存の収入・貯金データを上書きしていた |

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Services/TransactionService.swift` |
| **変更内容** | `processMonthlyReview()` で次月 Budget 作成時に `incomeAmount` / `savingsAmount` を前月から引き継ぐよう変更 |
| **変更理由** | 翌月予算作成時にこれらの値が nil になり、予算設定画面で 0 表示されていた |

---

### 機能追加 / 変更

#### FEAT-001: 「使う」「追加」「立替」ボタンを「確定」に統一
| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Views/Main/QuickInputModalView.swift` |
| **変更内容** | `CalculatorKeypad` の `=` ボタンラベルを `isEditing ? "更新" : "確定"` に統一（旧: モードに応じて「使う」「追加」「立替」と分岐） |
| **変更理由** | ユーザーリクエスト。モードによってボタン名が変わる仕様が直感的でなかった |

#### FEAT-002: ホーム画面に月別カレンダービューを追加（右スワイプ）
| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Views/Main/CalendarView.swift`（新規作成） |
| **変更内容** | 日別支出をグリッド表示するカレンダービューを新規作成。支出額に応じて色が変化（spaceGreen / warmOrange / coralRed）。今日の日付をハイライト表示 |
| **変更理由** | ユーザーリクエスト。1日ごとの支出を確認できる機能が必要だった |

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Views/Main/DashboardView.swift` |
| **変更内容** | ホーム画面の円グラフ（BudgetGaugeView）を `TabView(.page)` でラップし、右スワイプで CalendarView に遷移できるよう変更 |
| **変更理由** | カレンダービューへのナビゲーション導線を実装するため |

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/ViewModels/DashboardViewModel.swift` |
| **変更内容** | `@Published var dailySpending: [Int: Double]` を追加。`fetchData()` 内で日別支出を集計して保持するよう変更 |
| **変更理由** | CalendarView にデータを渡すため |

#### FEAT-003: 支出入力モーダルにメモ欄を追加（折りたたみ式）
| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Models/ExpenseTransaction.swift` |
| **変更内容** | `memo: String?` プロパティを追加 |
| **変更理由** | メモ機能実装のためのデータモデル拡張 |

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Services/TransactionService.swift` |
| **変更内容** | `TransactionServiceProtocol` の `addExpense` / `updateExpense` に `memo: String?` 引数を追加。後方互換のための `protocol extension` を追加。実装側でメモを保存・更新するよう変更 |
| **変更理由** | メモ機能実装のためのサービス層拡張 |

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/ViewModels/QuickInputViewModel.swift` |
| **変更内容** | `@Published var memo: String` / `showMemoField: Bool` を追加。`logExpense()` でメモをサービスに渡すよう変更 |
| **変更理由** | メモ機能実装のための ViewModel 拡張 |

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudget/Views/Main/QuickInputModalView.swift` |
| **変更内容** | `MemoInputSection` コンポーネントを新規追加（折りたたみ式 UI）。カテゴリグリッド下に配置。20字上限・文字数カウンター表示 |
| **変更理由** | ユーザーリクエスト。案A〜Cを提案し、案B（折りたたみ式）が選択された |

---

### テスト追加

#### PT・IT テスト追加（2026-03-16）
| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudgetTests/TransactionServiceTests.swift` |
| **変更内容** | 3件 → 15件に拡充（IOU削除・更新のリグレッションテスト含む） |

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudgetTests/QuickInputViewModelTests.swift`（新規作成） |
| **変更内容** | PT 16件（計算ロジック・ログ処理） |

| 項目 | 内容 |
|---|---|
| **変更ファイル** | `NoLookBudgetTests/IntegrationTests.swift`（新規作成） |
| **変更内容** | IT 14件（E2E フロー検証） |

---

### 開発環境整備（2026-03-16）

| 変更内容 | 変更理由 |
|---|---|
| `CLAUDE.md` 作成（`GEMINI.md` から移植・拡張） | Antigravity から Claude Code へのプロジェクト引き継ぎ |
| `.claude/agents/ios-reviewer.md` 作成 | コードレビュー自動化 |
| `.claude/agents/test-writer.md` 作成 | テスト作成の標準化 |
| `.claude/agents/bug-fixer.md` 作成 | バグ修正作業の効率化 |
| `.claude/rules/swiftui-views.md` 作成 | View 実装ルールの自動適用 |
| `.claude/rules/transaction-service.md` 作成 | サービス層編集時の注意事項の自動適用 |

---

## 変更種別の凡例

| 種別 | 内容 |
|---|---|
| `fix` | バグ修正 |
| `feat` | 機能追加 |
| `refactor` | リファクタリング（動作変更なし） |
| `test` | テスト追加・修正 |
| `docs` | ドキュメントのみの変更 |
| `chore` | 開発環境・設定の変更 |
