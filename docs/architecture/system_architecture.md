# No-Look-Budget: System Architecture

このドキュメントは「No-Look-Budget」アプリのシステム概要を定義します。

```mermaid
graph TD
    %% Lock Screen / Notification Level
    LA[Live Activity / Dynamic Island] -->|Read/Update State| Ext(App Extension Layer)
    WG[iOS Widgets] -->|Read Shared DB| Ext
    
    %% Core Main App Level
    Main[Main App - SwiftUI / MVVM] -->|Read/Write Shared State| AppGroup(App Group / UserDefaults)
    Main -->|Manage Local Data| LocalDB(SwiftData)
    Ext -->|Read Data| AppGroup
    
    %% Security Layer (Keychain)
    subgraph Security Layer [セキュア情報管理: ID/Token/連携キー類]
        KeyChain[(iOS Keychain)]
        KeyChain -->|Secure Fetch| Main
        KeyChain -.->|将来: クラウド動機・APIトークン等| Main
    end
    
    %% External Synchronization
    LocalDB -.->|将来: バックアップ機能| CloudKit[(iCloud / CloudKit)]
    
    %% Marketing & BI
    subgraph Analytics & Monetization
        Tele[Firebase / Analytics]
        Ads[StoreKit / In-App Purchase]
        Main --> Tele
        Main --> Ads
    end

    classDef core fill:#4285F4,stroke:#fff,stroke-width:2px,color:#fff;
    classDef target fill:#34A853,stroke:#fff,stroke-width:2px,color:#fff;
    classDef secure fill:#EA4335,stroke:#fff,stroke-width:2px,color:#fff;
    
    class LA,WG target;
    class KeyChain secure;
    class Main core;
```

## アーキテクチャの解説
1. **Live Activity / Widget 中心の設計:** ユーザーがアプリアイコンをタップせずに情報を直感で取得・確認するための根幹部分。
2. **Security First (Keychain層):** 金銭やアカウント情報を扱うため、平文でのUserDefaults保存は避け、暗号化される領域である「Keychain」を中心に機密データを扱います。
3. **拡張性とマネタイズ:** 将来的にStoreKitによるサブスクリプション実装や、Firebaseを用いたユーザーアナリティクスなど、マーケターとして有用なツールを統合できる枠組みを持たせています。
