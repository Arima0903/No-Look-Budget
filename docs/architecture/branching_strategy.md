# No-Look-Budget ブランチ戦略

> 最終更新: 2026-03-18

---

## 概要

3層ブランチ構造（main → feature → userstory）を採用。
機能単位で統合し、ユーザーストーリー単位で細かく開発を進める。
CI/CDの実行タイミングはブランチ階層に応じて最適化されている。

---

## ブランチ構成

```
main (保護ブランチ・リリース可能)
  │
  ├── feature/<機能名>                 ... 機能統合ブランチ
  │     ├── userstory/<ストーリー名>   ... 個別タスクの開発
  │     ├── userstory/<ストーリー名>
  │     └── userstory/<ストーリー名>
  │
  ├── fix/<バグ名>                     ... バグ修正
  ├── hotfix/<緊急修正名>              ... 本番緊急パッチ
  └── release/v<バージョン>            ... リリース準備
```

### 各ブランチの役割

| ブランチ | 用途 | マージ先 | CI実行 | ライフサイクル |
|---|---|---|---|---|
| `main` | 常にリリース可能な安定版 | - | フルCI + リリース準備 | 永続 |
| `feature/*` | 機能単位の統合ブランチ | `main` | フルCI（ビルド+全テスト） | PR マージ後に削除 |
| `userstory/*` | 個別タスクの開発 | `feature/*` | 軽量CI（ビルド確認のみ） | PR マージ後に削除 |
| `fix/*` | バグ修正 | `main` | フルCI | PR マージ後に削除 |
| `hotfix/*` | 本番の緊急バグ修正 | `main` | フルCI | PR マージ後に削除 |
| `release/v*` | App Store 提出前の最終確認 | `main` | フルCI + アーカイブ | タグ付け後に削除 |

---

## CI/CD 実行タイミング設計

### 実行タイミング一覧

```
userstory/* → feature/* へのPR
  └─ 🔵 軽量CI: ビルド確認のみ（高速フィードバック）

feature/* → main へのPR
  └─ 🟢 フルCI: ビルド + 全テスト + スキルセキュリティチェック

main へのpush（マージ完了時）
  └─ 🟢 フルCI: ビルド + 全テスト（マージ後の統合確認）

release/v* タグのpush
  └─ 🔴 リリースCI: アーカイブビルド + GitHub Release 作成
```

### なぜこのタイミングか

| タイミング | 理由 |
|---|---|
| userstory → feature で軽量CI | 頻繁にPRが発生するため、高速フィードバックを優先。ビルドが通ることだけ確認 |
| feature → main でフルCI | 機能全体の統合テスト。main に入る前の最終ゲート |
| main push でフルCI | マージ後に他の変更との競合がないか最終確認 |
| タグpush でリリースCI | リリースビルドとGitHub Release の自動生成 |

---

## ワークフロー

### 1. 通常の機能開発（3層フロー）

```
1. main から feature/add-admob を作成
2. feature/add-admob から userstory/admob-banner-view を作成
3. userstory ブランチで実装・コミット
4. userstory → feature へPR作成 → 軽量CI（ビルド確認）
5. CI通過後 feature にマージ
6. 他のuserstoryも同様に feature にマージ
7. 機能が完成したら feature → main へPR作成 → フルCI
8. CI通過後 main にマージ（Squash Merge 推奨）
9. feature ブランチを削除
```

### 2. バグ修正

```
1. main から fix/xxx を作成
2. 修正・テスト追加
3. fix → main へPR作成 → フルCI
4. CI通過後 main にマージ
```

### 3. App Store リリース

```
1. main から release/v1.x.x を作成
2. バージョン番号更新・最終動作確認
3. TestFlight ビルド（手動 or CI）
4. 問題なければ main にマージ
5. main に git tag v1.x.x を打つ → リリースCI
6. release ブランチを削除
```

### 4. 緊急修正（Hotfix）

```
1. main から hotfix/xxx を作成
2. 最小限の修正
3. hotfix → main へPR作成 → フルCI
4. CI通過後 main にマージ
5. 必要に応じて即座にリリース
```

---

## ブランチ命名規則

```
feature/add-admob-banner                    # 機能統合ブランチ
  userstory/admob-banner-view               # バナーUI実装
  userstory/admob-premium-toggle            # プレミアム切り替え
  userstory/admob-integration-test          # 統合テスト

feature/improve-widget-design               # 機能統合ブランチ
  userstory/widget-new-layout               # 新レイアウト
  userstory/widget-dark-mode-fix            # ダークモード修正

fix/budget-calculation-error                # バグ修正
hotfix/crash-on-launch                      # 緊急修正
release/v1.0.0                              # リリース準備
```

- 英語の kebab-case を使用
- 短く明確に内容が伝わる名前にする
- userstory は対応する feature ブランチから必ず分岐させる

---

## ブランチ保護ルール

### main ブランチ

| ルール | 設定値 |
|---|---|
| Require pull request before merging | ON |
| Require status checks to pass | ON（フルCI: ビルド+テスト） |
| Require branches to be up to date | ON |
| Allow force pushes | OFF |
| Allow deletions | OFF |

### feature/* ブランチ（推奨）

| ルール | 設定値 |
|---|---|
| Require status checks to pass | ON（軽量CI: ビルドのみ） |
| Allow force pushes | OFF |

---

## バージョニング（Semantic Versioning）

`MAJOR.MINOR.PATCH` 形式を採用:

| 区分 | いつ上げるか | 例 |
|---|---|---|
| MAJOR | 大規模な破壊的変更 | 1.0.0 → 2.0.0 |
| MINOR | 新機能追加（後方互換あり） | 1.0.0 → 1.1.0 |
| PATCH | バグ修正・軽微な変更 | 1.0.0 → 1.0.1 |

### 現在の計画

- `v1.0.0` — MVP リリース（Phase C）
- `v1.1.0` — フィードバック反映アップデート（Phase D）
- `v1.2.0` — AdMob / サブスクリプション導入（Phase E）

---

## Git タグ運用

リリース時に Annotated Tag を付与:

```bash
git tag -a v1.0.0 -m "MVP リリース: App Store 初回公開"
git push origin v1.0.0
```

---

## コミットメッセージ規約

[Conventional Commits](https://www.conventionalcommits.org/) に準拠:

```
<type>(<scope>): <description>

feat(widget): ロック画面ウィジェットを追加
fix(budget): 月またぎ時の予算リセット不具合を修正
docs(readme): セットアップ手順を更新
refactor(dashboard): ViewModel のロジックを整理
test(transaction): TransactionService の境界値テストを追加
chore(ci): GitHub Actions ワークフローを追加
```
