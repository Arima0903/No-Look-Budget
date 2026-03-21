# No-Look-Budget 機密情報管理ガイド

> 最終更新: 2026-03-19

---

## 基本方針

**ソースコードに機密情報を一切含めない。**

---

## 防御の3層構造

```
Layer 1: .gitignore        → 機密ファイルをGitに入れない
Layer 2: .claude deny 設定  → Claude Code が機密ファイルを読めない
Layer 3: xcconfig + 環境変数 → ビルド時に安全に注入
```

---

## 対象となる機密情報

| 情報 | フェーズ | 管理方法 |
|---|---|---|
| AdMob App ID | Phase E | xcconfig |
| AdMob Ad Unit ID | Phase E | xcconfig |
| App Store Connect API Key | Phase B | GitHub Secrets |
| 将来の外部API キー | 将来 | Keychain |

---

## 方法1: xcconfig による管理（AdMob キー等）

### セットアップ手順

1. プロジェクトルートに `Secrets.xcconfig` を作成（.gitignore で除外済み）:

```
// Secrets.xcconfig — このファイルは Git に含めない
ADMOB_APP_ID = ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
ADMOB_BANNER_ID = ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
```

2. テンプレートファイルを Git で管理:

```
// Secrets.xcconfig.template — これは Git に含める
// コピーして Secrets.xcconfig にリネームし、実際の値を入力してください
ADMOB_APP_ID = YOUR_ADMOB_APP_ID_HERE
ADMOB_BANNER_ID = YOUR_ADMOB_BANNER_ID_HERE
```

3. Xcode プロジェクト設定:
   - Project → Info → Configurations で `Secrets.xcconfig` を追加
   - Info.plist に `$(ADMOB_APP_ID)` で参照

4. Swift コードからの参照:

```swift
// Bundle から xcconfig の値を取得
enum AdUnitID {
    static let banner: String = {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2934735716"  // テスト用
        #else
        return Bundle.main.object(forInfoDictionaryKey: "ADMOB_BANNER_ID") as? String ?? ""
        #endif
    }()
}
```

---

## 方法2: GitHub Secrets（CI/CD 用）

App Store Connect API キー等、CI/CD で必要な機密情報:

1. GitHub リポジトリ → Settings → Secrets and variables → Actions
2. 以下を登録:
   - `APP_STORE_CONNECT_KEY_ID`
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_KEY`（Base64 エンコード）

3. GitHub Actions ワークフローから `${{ secrets.XXX }}` で参照

---

## 方法3: Keychain（将来の認証トークン等）

将来的にユーザー認証やCloudKit連携を導入する際は Keychain を使用:

```swift
import Security

enum KeychainService {
    static func save(key: String, value: String) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    static func load(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    enum KeychainError: Error {
        case saveFailed(OSStatus)
    }
}
```

---

## Claude Code の制限設定

`.claude/settings.json` の `deny` リストで、Claude Code が機密ファイルを読めないように設定済み:

```json
"deny": [
    "Read(.env)",
    "Read(.env.*)",
    "Read(**/.env)",
    "Read(**/.env.*)",
    "Read(**/Secrets.xcconfig)",
    "Read(**/Secrets/**)",
    "Read(**/*.secret)",
    "Read(**/*.secrets)"
]
```

---

## チェックリスト

- [x] `.gitignore` に機密ファイルパターンを追加
- [x] `.claude/settings.json` に deny ルールを設定
- [ ] `Secrets.xcconfig.template` を作成（Phase E 開始時）
- [ ] AdMob 本番キーを xcconfig 方式に移行（Phase E 開始時）
- [ ] GitHub Secrets に App Store Connect キーを登録（Phase B 開始時）
