#!/bin/bash
# pre-commit フック: スキルファイルが変更された場合にセキュリティチェックを実行
# インストール: cp scripts/pre-commit-skill-check.sh .git/hooks/pre-commit

# スキル関連ファイルがステージングされているか確認
SKILL_FILES=$(git diff --cached --name-only | grep -E '\.agent/|\.agents/|skills/' || true)

if [ -n "$SKILL_FILES" ]; then
    echo "🔍 スキルファイルの変更を検出しました。セキュリティチェックを実行します..."
    echo ""

    # セキュリティチェッカーを実行
    python3 scripts/skill_security_check.py --ci --quiet

    if [ $? -ne 0 ]; then
        echo ""
        echo "❌ HIGH リスクのセキュリティ問題が検出されました。"
        echo "   詳細: python3 scripts/skill_security_check.py"
        echo "   コミットを中止します。"
        exit 1
    fi

    echo "✅ セキュリティチェック通過"
fi
