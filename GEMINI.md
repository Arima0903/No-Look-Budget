# No-Look-Budget: Project Guidelines & Rules

## 1. プロジェクトのゴール（経営視点）
1. **Primary Goal:** 浪費家（まずはユーザー自身）の浪費癖を減らし、健全な家計管理を実現すること。
2. **Business Goal:** アプリをマネタイズ（サブスクリプションや機能課金等）し、App Storeで公開・リリースし収益化すること。

## 2. 開発・設計思想 (Design & Security First)
- **UI/UX First:** プログラム（MVP）を書き始める前に、必ずFigmaや画像生成などを通じて画面UIのイメージ合わせを行うこと。プロトタイプで触り心地とビジュアルを検証する。
- **Security First:** お金を扱うアプリケーションであるため、IDやAPIキー、個人情報などセキュアに扱うべき情報は `Keychain` などを用いて厳重に管理し、情報漏洩を防ぐセキュアな設計を徹底すること。ソースコードへのハードコーディングは厳禁。
- **Numeric Input Policy:** 数値を入力させる箇所（金額など）については、アプリ全体の方針として**必ず独自の「入力モーダル（カスタムキーパッド等）」を使用**すること。標準のキーボード（TextField等）による直接入力は、半角・全角の混在やクラッシュのリスクを防ぐためUI方針として禁止とする。
- **Marketing Perspective:** マーケターとしての視点を常に持ち、競合アプリ（既存の入力型家計簿アプリなど）との差別化要因（「開かせない」「ADHD向け」「立替分離の低負荷」）が保たれているかを、各機能実装のたびに確認・検証すること。

## 3. 技術スタック・アーキテクチャ
- **Language:** Swift
- **Framework:** SwiftUI
- **Design Style:** モダン、クリーン、直感的（Apple純正アプリに近い使い心地）。ダークモード重視、色による直感的なフィードバックを主体とする。
- **Architecture:** MVVM (Model-View-ViewModel)
- **Naming Convention:** [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) に厳格に準拠。

## 4. 作業範囲・フォルダ構成
- **Working Directory:** `/Users/taguchikoji/Desktop/vibecoding/second-business/No-Look-Budget`
- **Separation of Concerns:** `docs`（設計書や議事録など）とソースコード（Xcodeプロジェクト等）は明確なフォルダ階層として分離すること。
- **Global Docs:** プロジェクト全体に関わる資料（`GEMINI.md` など）はルート配下に統合。
- **Minutes:** 議事録は必ず `docs/minutes/` ディレクトリ内に保存・管理すること。

## 5. 開発手法・フロー
- **Agile Development:** 小さな機能単位でリリース・確認を繰り返す。
- **TDD (Test Driven Development):** 機能を実装する前にテストコードを記述。
- **Architecture Docs:** アーキテクチャの図解、サービスフロー、UIフローなどのドキュメントを `docs/architecture` や `docs/ui` に作成し、都度メンテナンスする。

## 6. コミュニケーション・教育的配慮
- **Explain for Beginner:** ユーザーはiOS開発初心者・Xcode未導入である前提に立ち、まずは開発環境の構築から丁寧に、専門用語を極力噛み砕いて説明すること。
- **Doc over Code:** なぜその設計にしたのか理由を添える。
- **Executive Reporting:** 経営者・ビジネスサイドにも進捗がひと目で伝わるよう、逐一報告資料（マークダウンスライド形式、サマリー画像等）を `docs/reports/` に作成すること。

## 7. プロジェクトの魂（コンセプト）
- 「ADHD向け：開かなくてもわかる管理（No-Look Experience）」
- 「飲み会対応：立替金セパレーターの極限の簡略化（スワイプ分離）」

## 8. エージェントの行動指針
エージェントは、SKILLS.mdに定義されたiOS開発のベストプラクティスに基づき、特にWidgetKitの最適化とSwiftUIのコンポーネント化においてシニアレベルのコードを出力すること。