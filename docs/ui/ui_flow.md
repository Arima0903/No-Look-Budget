# No-Look-Budget: UI Flow (画面遷移図)

アプリの画面遷移と主要なユーザー導線の設計です。MVP（初期リリース）における画面構成を表現しています。

```mermaid
graph TD
    classDef main fill:#212121,stroke:#4CAF50,stroke-width:2px,color:#fff;
    classDef modal fill:#212121,stroke:#FF9800,stroke-width:2px,color:#fff;
    classDef detail fill:#212121,stroke:#9C27B0,stroke-width:2px,color:#fff;
    classDef widget fill:#1E1E1E,stroke:#03A9F4,stroke-width:2px,color:#fff;

    %% Entry Points
    HomeScreenWidget[ホーム画面ウィジェット<br>NoLookBudgetWidget]:::widget
    
    %% Core App
    subgraph App [No-Look-Budget App]
        Dashboard[メインダッシュボード<br>DashboardView]:::main
        InputModal[1タップ入力モーダル 兼 電卓<br>QuickInputModalView]:::modal
        
        subgraph Details [詳細・設定系]
            CategoryDetail[カテゴリ別詳細画面<br>CategoryDetailView]:::detail
            DebtRecovery[借金回収設定画面<br>DebtRecoveryView]:::detail
            DebtSourceSelection[減額元選択画面<br>DebtRecoverySourceSelectionView]:::detail
        end
    end

    %% Flows (Widget)
    HomeScreenWidget -->|Tap 円グラフ(例: 食費)| InputModal
    HomeScreenWidget -->|Tap その他領域| Dashboard

    %% Flows (In-App)
    Dashboard -->|Tap "QUICK-SYNC & LOG"| InputModal
    Dashboard -->|Tap 小ウィジェット（各カテゴリ）| CategoryDetail
    
    CategoryDetail -->|Tap "回収プランを決める"| DebtRecovery
    DebtRecovery -->|Tap "次へ（減額元の選択）"| DebtSourceSelection
    
    %% Return Flows
    InputModal -->|金額入力 ＋ "使う(=)"タップ| Dashboard
    CategoryDetail -.->|Back| Dashboard
    DebtSourceSelection -.->|完了後自動遷移| Dashboard
```

## 各画面のスクリーンショット（プレースホルダー）

※開発中のため、スクリーンショットは仮の枠組みです。実装が進み次第、適宜画像をアップデートしてください。

### 1. 予算可視化ウィジェット (NoLookBudgetWidget)
ホーム画面に配置される、開かずとも予算の消化具合を色で把握できる巨大ゲージ。
`[ここにウィジェットのスクショを配置]`

### 2. メインダッシュボード (DashboardView)
全体予算の可視化と、各項目の小ウィジェットが並ぶホーム画面。
`[ここにダッシュボードのスクショを配置]`

### 3. クイック入力・電卓モーダル (QuickInputModalView)
ウィジェットから直行できる、1タップで予算項目を選択し、電卓で計算・入力が完結する画面。
`[ここに入力モーダルのスクショを配置]`

### 4. カテゴリ別詳細・借金警告 (CategoryDetailView)
各カテゴリの詳細状況と、過去に使いすぎた予算（借金）がある場合にアラートが出る画面。
`[ここにカテゴリ詳細のスクショを配置]`

### 5. 借金回収プラン設定 (DebtRecoveryView / DebtRecoverySourceSelectionView)
使いすぎたマイナス分を、「翌月一括でどこかのカテゴリから引く」のか、「数ヶ月に分割する(プレミアム機能)」のかを選択する画面。
`[ここに借金回収画面のスクショを配置]`
