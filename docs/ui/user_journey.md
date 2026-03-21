# Orbit Budget: ユーザー利用フロー (検証済・最新版)

「ADHD層・めんどくさがり層」に特化したUX設計から、無駄な機能（Undoや当月間の予算振替）を削ぎ落とし、全体予算内でやりくりする「月末の振り返りと目標設定」を最重要イベントとして定義したフローです。

---

## 1. 導入 (Onboarding)
単なる初期設定だけでなく、最大の価値である「ウィジェットの設置」までを完了させるフロー。
また、浪費家が確実にお金を残せるよう、「固定費と先取り貯金」を真っ先に天引きし、残った額を「変動費（アプリで管理する予算）」として定義する仕組みを取り入れます。

```mermaid
graph TD
    classDef user fill:#E1F5FE,stroke:#03A9F4,stroke-width:2px,color:#000
    classDef app fill:#F1F8E9,stroke:#8BC34A,stroke-width:2px,color:#000

    subgraph ユーザー
        U1[アプリを開く]:::user --> U2[使い方を理解し<br>月の収入を入力]:::user
        U2 --> U3[固定費と目標貯蓄額<br>先取り貯金を引く]:::user
        U3 --> U4[残りの金額を変動費とし<br>各カテゴリ内訳を入力]:::user
        U4 --> U5[締め日を設定]:::user
        U5 --> U6[ウィジェットの<br>設置方法ガイドを見る]:::user
        U6 --> U7[ホーム画面に<br>ウィジェットを配置]:::user
    end

    subgraph アプリ本体
        A1[チュートリアル画面]:::app --> A2[収入・固定費・貯金設定ウィザード]:::app
        A2 --> A3[変動費カテゴリ設定ウィザード]:::app
        A3 --> A4[ウィジェット設置<br>チュートリアル画面]:::app
        A4 --> A5[ダッシュボード<br>DashboardView]:::app
    end

    U1 -.-> A1
    U2 -.-> A2
    U3 -.-> A2
    U4 -.-> A3
    U5 -.-> A3
    U6 -.-> A4
    U7 -.-> A5
```
* **必要な画面:** スプラッシュ・チュートリアル画面、**固定費・貯蓄設定画面（Income & Fixed Cost Setup）**、**変動費カテゴリ設定画面**、ウィジェット設置手順ガイド画面

---

## 2. 記録 (Logging) - 日常の出費入力
支出が発生した際に行う、極限まで摩擦を減らしたアクション。間違えた場合は詳細画面から訂正する（Undoボタンで隠さない）。

```mermaid
graph TD
    classDef user fill:#E1F5FE,stroke:#03A9F4,stroke-width:2px,color:#000
    classDef widget fill:#FFF3E0,stroke:#FF9800,stroke-width:2px,color:#000
    classDef app fill:#F1F8E9,stroke:#8BC34A,stroke-width:2px,color:#000

    subgraph ユーザー
        U1[支払い完了]:::user --> U2[ウィジェットを確認]:::user
        U2 --> U3[該当カテゴリのグラフをタップ]:::user
        U3 --> U4[電卓で金額を入力]:::user
        U4 -->|自分の出費| U5[使うボタン押下]:::user
        U4 -->|立替の場合| U6[立替スイッチをON]:::user
        U6 --> U7[立替プールへ逃がす]:::user
        U5 --> U8[記録完了・画面閉じる]:::user
        U7 --> U8
        U8 -->|間違えた場合| U9[アプリを開いて履歴を編集]:::user
    end

    subgraph ウィジェット
        W1[色で状態表示<br>NoLookBudgetWidget]:::widget --> W2[入力画面起動]:::widget
    end

    subgraph アプリ本体
        A1[入力モーダル表示<br>QuickInputModalView]:::app --> A2{条件分岐}:::app
        A2 -->|通常| A3[データベース保存]:::app
        A2 -->|立替| A4[立替としてDB保存]:::app
        A3 --> A5[ハプティック振動]:::app
        A4 --> A5
        A5 -.-> U8
        A6[カテゴリ詳細・履歴一覧画面]:::app
    end

    U2 -.-> W1
    U3 -.-> W2
    W2 -.-> A1
    U4 -.-> A1
    U5 -.-> A2
    U7 -.-> A2
    U9 -.-> A6
```
* **必要な画面:** ホームウィジェット、`QuickInputModalView`、**取引履歴一覧・編集画面（後から直す用）**

---

## 3. 確認 (Monitoring) - 現在状況の把握
色による直感的な把握と、原因深掘り（何に使いすぎたか）のアクション。

```mermaid
graph TD
    classDef user fill:#E1F5FE,stroke:#03A9F4,stroke-width:2px,color:#000
    classDef widget fill:#FFF3E0,stroke:#FF9800,stroke-width:2px,color:#000
    classDef app fill:#F1F8E9,stroke:#8BC34A,stroke-width:2px,color:#000

    subgraph ユーザー
        U1[現在状況を知りたい]:::user --> U2[ウィジェット色を見る<br>緑/黄/赤]:::user
        U2 -->|赤色を発見| U3[アプリを起動・ダッシュボード確認]:::user
        U3 -->|詳細履歴を見たい| U4[小ウィジェットをタップ]:::user
        U4 --> U5[カテゴリ専用画面で<br>今月の履歴を確認]:::user
    end

    subgraph ウィジェット
        W1[リアルタイム色表示<br>NoLookBudgetWidget]:::widget
    end

    subgraph アプリ本体
        A1[ダッシュボード<br>DashboardView]:::app --> A2[カテゴリ詳細表示<br>CategoryDetailView]:::app
        A2 --> A3[画面下部の<br>出費履歴リスト表示]:::app
    end

    U2 -.-> W1
    U3 -.-> A1
    U4 -.-> A2
    U5 -.-> A3
```
* **必要な画面:** `DashboardView`、`CategoryDetailView`（下半分の履歴リスト）

---

## 4. 月末の振り返りと翌月目標 (Review & Adjusting) 【重要】
「全体予算をクリアできたか（成功）」の確認と、月を跨いだ時の借金ペナルティ（翌月補填）を決める一大イベント。

```mermaid
graph TD
    classDef user fill:#E1F5FE,stroke:#03A9F4,stroke-width:2px,color:#000
    classDef app fill:#F1F8E9,stroke:#8BC34A,stroke-width:2px,color:#000
    classDef premium fill:#E8EAF6,stroke:#3F51B5,stroke-width:2px,stroke-dasharray: 5 5,color:#000

    subgraph ユーザー
        U1[月末・締め日が到来]:::user --> U2[アプリを開く]:::user
        U2 --> U3[今月の全体収支レポートを確認<br>黒字か赤字か]:::user
        U3 -->|赤字カテゴリがある| U4[借金回収プランを選択<br>例: 来月一括]:::user
        U4 -->|課金済み| U5[借金回収プランを選択<br>例: 3ヶ月分割]:::user
        U4 --> U6[減額元カテゴリ<br>例: 来月の娯楽費 を選択]:::user
        U5 --> U6
        U6 --> U7[翌月の予算を最終決定]:::user
        U3 -->|全体クリア成功| U7
        U7 --> U8[新しい月がスタート]:::user
    end

    subgraph アプリ本体
        A0[月末到来通知]:::app --> A1[月末振り返りレポート画面<br>MonthlyReviewView]:::app
        A1 --> A2[プラン選択画面<br>DebtRecoveryView]:::app
        A2 -->|プレミアム機能| A3[分割・長期間回収メニュー<br>※未購入時はPaywallへ]:::premium
        A2 --> A4[減額元選択画面<br>DebtRecoverySourceSelectionView]:::app
        A1 --> A5[次月予算決定画面]:::app
        A4 --> A5
        A5 --> A6[来月の予算定義を<br>保存しグラフリセット]:::app
    end

    U1 -.-> A0
    U2 -.-> A1
    U3 -.-> A1
    U4 -.-> A2
    U5 -.-> A3
    U6 -.-> A4
    U7 -.-> A5
    U8 -.-> A6
```
* **必要な画面:** **月末振り返りレポート画面（MonthlyReviewView）**、`DebtRecoveryView`、`DebtRecoverySourceSelectionView`、**次月予算決定・確認画面**

---

## 5. 管理・設定 (Management & App Settings)
アプリ全体の環境設定や有償機能のアンロックに関するアクション。

```mermaid
graph TD
    classDef user fill:#E1F5FE,stroke:#03A9F4,stroke-width:2px,color:#000
    classDef app fill:#F1F8E9,stroke:#8BC34A,stroke-width:2px,color:#000

    subgraph ユーザー
        U1[設定アイコンをタップ]:::user --> U2[各種設定や月の開始日<br>テーマ等を変更]:::user
        U1 --> U3[プレミアム機能をタップ]:::user
        U3 --> U4[課金決済]:::user
    end

    subgraph アプリ本体
        A1[設定画面<br>SettingsView]:::app --> A2[通知・テーマ・開始日設定]:::app
        A1 --> A3[プレミアム案内<br>PaywallView]:::app
        A3 --> A4[StoreKitによる<br>サブスクリプション処理]:::app
    end

    U2 -.-> A2
    U3 -.-> A3
    U4 -.-> A4
```
* **必要な画面:** 設定（Settings）画面、プレミアム案内（Paywall）画面
