# TestFlight リリース手順書

> 作成: 2026-03-19 / Orbit Budget

---

## 前提条件チェックリスト

| 項目 | 状態 | 備考 |
|---|---|---|
| Apple Developer Program 加入 | ✅ 完了 | 年額 ¥12,980（個人）・承認済み |
| Xcode インストール済み | 完了 | Xcode 26.3 |
| バンドルID | `com.arima0903.NoLookBudget` | 確定済み |
| Development Team | `SR4K79A5H5` | pbxproj に設定済み |
| プライバシーポリシー URL | 作成済み | `docs/privacy-policy.html` を GitHub Pages で公開する |
| スクリーンショット | 撮影済み | `docs/screenshots/` に3枚 |

---

## ステップ1: App Store Connect でアプリページ作成

### 1-1. App Store Connect にログイン

1. https://appstoreconnect.apple.com にアクセス
2. Apple Developer アカウントでサインイン

### 1-2. 新規アプリを作成

1. 「マイ App」→ 左上の「＋」→「新規 App」をクリック
2. 以下を入力:

| 項目 | 入力値 |
|---|---|
| プラットフォーム | iOS |
| 名前 | `Orbit Budget` |
| プライマリ言語 | 日本語 |
| バンドル ID | `com.arima0903.NoLookBudget`（ドロップダウンから選択） |
| SKU | `orbit-budget-001`（任意の一意な文字列） |
| ユーザーアクセス | フルアクセス |

3. 「作成」をクリック

> バンドル ID がドロップダウンに表示されない場合:
> Apple Developer Portal (https://developer.apple.com/account/resources/identifiers) で
> App ID を先に登録する必要があります。
> 「Identifiers」→「＋」→「App IDs」→ バンドルID を入力して登録。

### 1-3. アプリ情報の入力

「App 情報」タブで以下を設定:

| 項目 | 入力値 |
|---|---|
| カテゴリ | ファイナンス |
| サブカテゴリ | （空欄でOK） |
| コンテンツ配信権 | いいえ |
| Age Rating | 「編集」→ 全項目「なし」で回答 → 自動的に 4+ になる |

> 注意: 金融カテゴリだから 17+ というわけではありません。
> コンテンツ申告の回答内容で自動判定されます。
> Orbit Budget は暴力・ギャンブル等のコンテンツがないため 4+ が適用されます。

### 1-4. プライバシーポリシー URL を設定

「App のプライバシー」タブ:

1. プライバシーポリシー URL を入力
   - GitHub Pages を使う場合: `https://arima0903.github.io/No-Look-Budget/docs/privacy-policy.html`
   - 別のホスティングでも可

2. 「データの収集を開始する」→ 以下を選択:
   - 「データを収集していません」をチェック（MVP時点）

> AdMob 導入時（Phase E）にデータ収集の申告を更新する必要があります。

### 1-5. 価格と配信状況

「価格および配信状況」タブ:

| 項目 | 設定値 |
|---|---|
| 価格 | 無料 |
| 配信状況 | すべての国と地域 |

---

## ステップ2: プライバシーポリシーを公開する

TestFlight / App Store のどちらも、プライバシーポリシー URL が**実際にアクセスできる状態**であることが必須です。

### 2-1. GitHub Pages で公開する場合

1. GitHub リポジトリの **Settings → Pages** を開く
2. Source: 「Deploy from a branch」を選択
3. Branch: `main` / `/ (root)` または `/docs` を選択して **Save**
4. 数分待つと以下の URL でアクセス可能になる:
   - `https://arima0903.github.io/No-Look-Budget/docs/privacy-policy.html`
5. ブラウザで上記 URL を開き、正しく表示されることを確認

> GitHub Pages が有効にならない場合:
> - リポジトリが **Public** であることを確認（Private リポジトリでは GitHub Pro が必要）
> - `docs/privacy-policy.html` がリポジトリの main ブランチに存在することを確認

### 2-2. 別のホスティングサービスを使う場合

Netlify, Vercel, Firebase Hosting 等でも可。URL が HTTPS でアクセス可能であればOK。

---

## ステップ3: App ID の登録（バンドル ID がドロップダウンに出ない場合）

通常、Xcode の「Automatically manage signing」が ON であれば自動的に App ID が登録されますが、手動で登録が必要な場合は以下の手順で行います。

### 3-1. Apple Developer Portal で App ID を登録

1. https://developer.apple.com/account/resources/identifiers にアクセス
2. 左上の「＋」ボタンをクリック
3. 「App IDs」を選択 → 「Continue」
4. Type: **App** を選択 → 「Continue」
5. 以下を入力:

| 項目 | 入力値 |
|---|---|
| Description | `Orbit Budget` |
| Bundle ID | Explicit → `com.arima0903.NoLookBudget` |

6. Capabilities で必要な機能にチェック:
   - **App Groups**（ウィジェット連携に必要）
7. 「Continue」→「Register」

### 3-2. App Group の登録（ウィジェット用）

1. 同じ Identifiers ページで「＋」→「App Groups」を選択
2. Description: `NoLookBudget Shared`
3. Identifier: `group.com.arima0903.NoLookBudget`
4. 「Continue」→「Register」

> Xcode で「Automatically manage signing」が ON なら、ほとんどの場合これらは自動で処理されます。
> ステップ1-2 でバンドル ID がドロップダウンに表示されない場合のみ、手動で登録してください。

---

## ステップ4: Xcode で Archive ビルド → App Store Connect にアップロード

### 4-1. ビルド設定の確認

Xcode でプロジェクトを開き、以下を確認:

1. **スキーム**: `NoLookBudget` を選択
2. **デバイス**: 「Any iOS Device (arm64)」を選択（シミュレーターではなく実機用）
3. **バージョン番号の確認**:
   - Project → General → Version: `1.0`（初回リリース）
   - Project → General → Build: `1`（初回ビルド）

### 4-2. Archive の作成

1. メニューバー → **Product → Archive** をクリック
2. ビルドが完了するまで待つ（3〜10分程度）
3. 成功すると **Organizer** ウィンドウが自動的に開く

> Archive が灰色で選択できない場合:
> デバイスが「Any iOS Device」ではなくシミュレーターになっている可能性があります。
> 画面上部のデバイス選択を確認してください。

### 4-3. App Store Connect にアップロード

1. Organizer で作成した Archive を選択
2. 右側の **「Distribute App」** をクリック
3. 配布方法: **「App Store Connect」** を選択
4. **「Upload」** を選択（Exportではない）
5. オプション:
   - 「Include bitcode」: OFF（Xcode 26 ではデフォルト OFF）
   - 「Upload your app's symbols」: ON（クラッシュレポートに必要）
   - 「Manage Version and Build Number」: ON
6. **「Upload」** をクリック
7. アップロード完了まで待つ（ネットワーク速度による。通常 5〜15分）

> エラーが出た場合のよくある原因:
> - 証明書の問題 → Xcode → Settings → Accounts で証明書を更新
> - プロビジョニングプロファイルの問題 → 「Automatically manage signing」をONにする
> - アイコンが不足 → Assets.xcassets の AppIcon を確認

### 4-4. アップロード後の確認

1. App Store Connect → 「マイ App」→「Orbit Budget」→「TestFlight」タブ
2. アップロードしたビルドが「処理中」として表示される
3. **処理完了まで 5〜30分** かかる場合がある
4. 処理完了後、ステータスが「テスト準備完了」に変わる

> Apple からメールが届く場合があります:
> - 「The following issues were found」→ 警告の場合は無視可能な場合が多い
> - 「Missing Compliance」→ 暗号化に関する質問に回答が必要（下記参照）

### 4-5. 輸出コンプライアンス（暗号化）の回答

初回アップロード時に App Store Connect で聞かれます:

**「このAppは暗号化を使用していますか？」**

→ **「いいえ」** を選択

> Orbit Budget は独自の暗号化を実装していません。
> HTTPS 通信のみ（iOS 標準）の場合は「いいえ」で OK です。
> AdMob SDK 導入後も同様です（SDK の暗号化は Apple の免除対象）。

---

## ステップ5: TestFlight でテスター招待

### 5-1. 内部テスターの追加

App Store Connect → TestFlight タブ:

1. 左サイドバーの「内部テスト」→「＋」をクリックしてグループを作成
2. グループ名: `内部テスト`（任意）
3. 「テスターを追加」→ Apple ID のメールアドレスで招待
4. 「ビルドを追加」→ アップロード済みのビルドを選択
5. テスターにメール通知が届く

> 内部テスター: App Store Connect ユーザーのみ（最大 100名）
> 審査不要でビルドを即配布できる

### 5-2. テスターがアプリをインストールする手順

テスターに以下を案内:

1. App Store から **「TestFlight」** アプリをインストール（無料）
2. 招待メール内のリンクをタップ、または TestFlight アプリを開く
3. 「テスト」をタップしてアプリをインストール
4. ホーム画面にオレンジ色のドットが付いたアプリアイコンが表示される

### 5-3. 外部テスター（任意・Phase B 後半）

外部テスターへの配布は **Apple の審査が必要**（通常 24〜48時間）:

1. TestFlight タブ → 「外部テスト」→ グループ作成
2. テスターのメールアドレスを追加（Apple ID 不要、最大 10,000名）
3. 「テスト情報」を入力:
   - テスト内容の説明: 「家計管理アプリの初期テスト。予算設定、支出入力、ウィジェット表示の動作確認」
   - フィードバック用メールアドレス
4. 「審査に送信」→ 承認後にテスターに配布

---

## トラブルシューティング

### Archive でエラーが出る場合

| エラー | 対処法 |
|---|---|
| `No signing certificate` | Xcode → Settings → Accounts → チームを選択 → 証明書をダウンロード |
| `Provisioning profile` エラー | Signing & Capabilities → 「Automatically manage signing」を ON |
| `Missing AppIcon` | Assets.xcassets → AppIcon に 1024×1024 のアイコンを設定 |
| `Unsupported architecture` | デバイスが「Any iOS Device」になっているか確認 |

### アップロード後にビルドが表示されない

- 処理に最大30分かかることがある。メールを確認する
- 問題があれば Apple からメールが届く
- App Store Connect のアクティビティタブで処理状況を確認

### TestFlight のビルドが期限切れ

- TestFlight のビルドは **90日間** 有効
- 期限切れ前に新しいビルドをアップロードする

---

## チェックリスト（最終確認用）

TestFlight に載せる前の最終チェック:

- [ ] Apple Developer Program に加入済み
- [ ] App Store Connect でアプリページを作成済み
- [ ] プライバシーポリシー URL が公開されアクセス可能
- [ ] アプリアイコン（1024×1024）が設定済み
- [ ] バージョン番号を確認（1.0 / Build 1）
- [ ] 実機でクラッシュしないことを確認
- [ ] Archive ビルドが成功
- [ ] App Store Connect にアップロード完了
- [ ] 輸出コンプライアンスの回答済み
- [ ] テスターを招待済み
