# No-Look-Budget: UI Flow

アプリの画面遷移と主要なユーザー導線の設計です。

```mermaid
graph TD
    classDef main fill:#212121,stroke:#4CAF50,stroke-width:2px,color:#fff;
    classDef split fill:#212121,stroke:#F44336,stroke-width:2px,color:#fff;
    classDef widget fill:#1E1E1E,stroke:#03A9F4,stroke-width:2px,color:#fff;
    classDef hidden fill:#333333,stroke:#9E9E9E,stroke-width:1px,stroke-dasharray: 5 5,color:#fff;

    %% Entry Points
    LockScreenWidget[iOS Lock Screen Widget]:::widget
    HomeScreenWidget[iOS Home Screen Widget]:::widget
    
    %% Core App
    subgraph App [No-Look-Budget App]
        Dashboard[メインダッシュボード<br>（全体予算グラフ ＋ 項目別小ウィジェット）]:::main
        InputModal[1タップ入力モーダル<br>（テンキー ＋ 「立替」切り替えスイッチ）]:::main
        ItemDetail[項目別詳細画面<br>（履歴・設定）]:::main
        Config[全体設定・予算修正]:::hidden
    end

    %% Flows
    LockScreenWidget -->|Tap| Dashboard
    HomeScreenWidget -->|Tap| Dashboard
    
    Dashboard -->|Tap "QUICK-SYNC & LOG"| InputModal
    Dashboard -->|Tap 小ウィジェット（例: POKER）| ItemDetail
    Dashboard -->|Long Press 小ウィジェット| InputModal
    
    InputModal -->|金額入力 ＋ 通常登録| Dashboard
    InputModal -->|金額入力 ＋ 立替(Front)タブで登録| Dashboard
    %% ※立替登録時は、全体の残高ゲージには影響を与えず、立替専用の小ウィジェット（IOU）に追加される

    Dashboard -->|Settings Icon| Config
```

## 画面遷移の要件（マーケティング戦略に基づく）
* 「開かなくてもわかる管理」を実現するため、**最重要UIはアプリアイコンを開いた画面ではなく、ロック画面・ホーム画面のウィジェット**です。
* **Frictionless Nomikai Sync（立替セパレーター）**: 「入力画面でのトグルスイッチ（案B）」を採用します。テンキー画面で直感的に「自分の出費」か「立替」かを切り替えられ、将来的な回収管理にも繋がる拡張性を持たせます。
* Apple Wallet連携（自動入力）が発生した場合は、アプリを開いた際（またはバックグラウンド）で自動的にDashboardのメイン残高が更新されます。
