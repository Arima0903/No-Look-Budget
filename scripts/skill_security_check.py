#!/usr/bin/env python3
"""
スキル セキュリティチェッカー
=============================
.agent/skills/ および .agents/skills/ 配下のスキルファイルを自動スキャンし、
セキュリティリスクを検出するスクリプト。

使い方:
  python scripts/skill_security_check.py              # 全スキルをスキャン
  python scripts/skill_security_check.py --ci         # CI モード（非ゼロ終了コード）
  python scripts/skill_security_check.py --path <dir> # 特定ディレクトリをスキャン
"""

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Optional

# =============================================================================
# セキュリティルール定義
# =============================================================================

SECURITY_RULES = [
    # --- HIGH リスク: コード実行・データ送信 ---
    {
        "id": "SEC-001",
        "name": "外部コマンド実行",
        "level": "HIGH",
        "pattern": r"(subprocess|os\.system|os\.popen|exec\(|eval\(|__import__|compile\()",
        "description": "外部コマンドの実行やコード動的評価の試み",
        "file_types": [".py", ".sh", ".bash"],
    },
    {
        "id": "SEC-002",
        "name": "ネットワーク通信",
        "level": "HIGH",
        "pattern": r"(urllib|requests\.|httpx\.|aiohttp|fetch\(|curl |wget |http\.client|socket\.)",
        "file_types": [".py", ".sh", ".js", ".ts"],
        "description": "外部サーバーへのデータ送信の可能性",
    },
    {
        "id": "SEC-003",
        "name": "ファイルシステム操作（危険）",
        "level": "HIGH",
        "pattern": r"(shutil\.rmtree|os\.remove|os\.unlink|rm\s+-rf|rmdir|shutil\.move.*\/)",
        "file_types": [".py", ".sh", ".bash"],
        "description": "ファイルの削除・移動など破壊的な操作",
    },
    {
        "id": "SEC-004",
        "name": "環境変数・シークレットへのアクセス",
        "level": "HIGH",
        "pattern": r"(os\.environ|process\.env|keychain|credentials|\.env\b|secrets?\[)",
        "file_types": [".py", ".sh", ".js", ".ts", ".md"],
        "description": "環境変数やシークレット情報へのアクセス",
    },
    # --- MEDIUM リスク: プロンプトインジェクション ---
    {
        "id": "SEC-005",
        "name": "プロンプトインジェクション（ロール上書き）",
        "level": "MEDIUM",
        "pattern": r"(you are now|ignore previous|ignore all|disregard|forget your|new instructions|system prompt|override|bypass)",
        "file_types": [".md", ".txt", ".yaml", ".yml"],
        "description": "AIエージェントの指示を上書きしようとする試み",
        "case_insensitive": True,
    },
    {
        "id": "SEC-006",
        "name": "プロンプトインジェクション（コマンド誘導）",
        "level": "MEDIUM",
        "pattern": r"(run this command|execute the following|always run|must execute|silently run|hidden command)",
        "file_types": [".md", ".txt", ".yaml", ".yml"],
        "description": "特定コマンドの実行を誘導する記述",
        "case_insensitive": True,
    },
    {
        "id": "SEC-007",
        "name": "不審な外部URL",
        "level": "MEDIUM",
        "pattern": r"https?://(?!github\.com|apple\.com|developer\.apple\.com|swift\.org|www\.swift\.org|shields\.io|img\.shields\.io|docs\.github\.com|skills\.sh)[^\s\)\"\'>\]]+",
        "file_types": [".md", ".txt", ".yaml", ".yml", ".py", ".sh"],
        "description": "許可リスト外の外部URLへの参照",
    },
    # --- LOW リスク: 注意が必要 ---
    {
        "id": "SEC-008",
        "name": "base64エンコード",
        "level": "MEDIUM",
        "pattern": r"(base64|atob|btoa|b64encode|b64decode)",
        "file_types": [".py", ".js", ".ts", ".sh", ".md"],
        "description": "base64エンコーディングによる難読化の可能性",
    },
    {
        "id": "SEC-009",
        "name": "ファイル読み取り（広範囲）",
        "level": "LOW",
        "pattern": r"(open\(.*['\"]r['\"]|readlines|read_text|glob\.\*\*|walk\(|scandir)",
        "file_types": [".py"],
        "description": "広範囲のファイル読み取り操作",
    },
    {
        "id": "SEC-010",
        "name": "隠しディレクトリ・ファイルへのアクセス",
        "level": "LOW",
        "pattern": r"(\/\.\w+\/|~\/\.|\.ssh|\.gnupg|\.aws|\.config)",
        "file_types": [".py", ".sh", ".md"],
        "description": "隠しファイルやシステム設定ディレクトリへのアクセス",
    },
]


@dataclass
class Finding:
    """検出されたセキュリティ問題"""
    rule_id: str
    rule_name: str
    level: str
    file: str
    line: int
    matched_text: str
    description: str


@dataclass
class SkillReport:
    """スキルごとのセキュリティレポート"""
    skill_name: str
    skill_path: str
    findings: list = field(default_factory=list)
    overall_risk: str = "LOW"


def scan_file(file_path: Path, rules: list) -> list[Finding]:
    """ファイルをスキャンしてセキュリティルールに違反する箇所を検出"""
    findings = []
    suffix = file_path.suffix.lower()

    try:
        content = file_path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return findings

    lines = content.split("\n")

    for rule in rules:
        # ファイルタイプのフィルタリング
        if "file_types" in rule and suffix not in rule["file_types"]:
            continue

        flags = re.IGNORECASE if rule.get("case_insensitive") else 0

        for i, line in enumerate(lines, 1):
            matches = re.finditer(rule["pattern"], line, flags)
            for match in matches:
                findings.append(Finding(
                    rule_id=rule["id"],
                    rule_name=rule["name"],
                    level=rule["level"],
                    file=str(file_path),
                    line=i,
                    matched_text=match.group(0)[:80],
                    description=rule["description"],
                ))

    return findings


def scan_skill_directory(skill_dir: Path) -> SkillReport:
    """スキルディレクトリを再帰的にスキャン"""
    skill_name = skill_dir.name
    report = SkillReport(skill_name=skill_name, skill_path=str(skill_dir))

    for file_path in skill_dir.rglob("*"):
        if file_path.is_file() and not file_path.name.startswith("."):
            findings = scan_file(file_path, SECURITY_RULES)
            report.findings.extend(findings)

    # 全体リスクレベルの判定
    if any(f.level == "HIGH" for f in report.findings):
        report.overall_risk = "HIGH"
    elif any(f.level == "MEDIUM" for f in report.findings):
        report.overall_risk = "MEDIUM"
    else:
        report.overall_risk = "LOW"

    return report


def find_skill_directories(base_path: Path) -> list[Path]:
    """スキルディレクトリを検出"""
    skill_dirs = []

    for skills_root in [".agent/skills", ".agents/skills"]:
        root = base_path / skills_root
        if root.exists():
            for entry in root.iterdir():
                if entry.is_dir():
                    skill_dirs.append(entry)

    return skill_dirs


def print_report(reports: list[SkillReport], verbose: bool = True):
    """セキュリティレポートをコンソールに出力"""
    print("=" * 70)
    print("  スキル セキュリティチェック レポート")
    print("=" * 70)
    print()

    total_high = 0
    total_medium = 0
    total_low = 0

    for report in reports:
        high = sum(1 for f in report.findings if f.level == "HIGH")
        medium = sum(1 for f in report.findings if f.level == "MEDIUM")
        low = sum(1 for f in report.findings if f.level == "LOW")
        total_high += high
        total_medium += medium
        total_low += low

        risk_icon = {"HIGH": "🔴", "MEDIUM": "🟡", "LOW": "🟢"}.get(report.overall_risk, "⚪")

        print(f"{risk_icon} {report.skill_name} (リスク: {report.overall_risk})")
        print(f"   パス: {report.skill_path}")
        print(f"   検出: HIGH={high}, MEDIUM={medium}, LOW={low}")

        if verbose and report.findings:
            for f in report.findings:
                level_icon = {"HIGH": "🔴", "MEDIUM": "🟡", "LOW": "🟢"}[f.level]
                print(f"   {level_icon} [{f.rule_id}] {f.rule_name}")
                print(f"      ファイル: {f.file}:{f.line}")
                print(f"      マッチ: {f.matched_text}")
                print(f"      説明: {f.description}")
        print()

    print("-" * 70)
    print(f"合計: HIGH={total_high}, MEDIUM={total_medium}, LOW={total_low}")
    print("-" * 70)

    if total_high > 0:
        print("\n⚠️  HIGH リスクの検出があります。スキルの使用前に手動レビューを行ってください。")
    elif total_medium > 0:
        print("\n⚠️  MEDIUM リスクの検出があります。内容を確認してください。")
    else:
        print("\n✅ 重大なセキュリティリスクは検出されませんでした。")

    return total_high


def save_report_json(reports: list[SkillReport], output_path: str):
    """レポートをJSON形式で保存"""
    data = {
        "scan_date": __import__("datetime").datetime.now().isoformat(),
        "total_skills": len(reports),
        "reports": [
            {
                "skill_name": r.skill_name,
                "skill_path": r.skill_path,
                "overall_risk": r.overall_risk,
                "findings_count": len(r.findings),
                "findings": [asdict(f) for f in r.findings],
            }
            for r in reports
        ],
    }
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"\nレポートを保存しました: {output_path}")


def main():
    parser = argparse.ArgumentParser(description="スキル セキュリティチェッカー")
    parser.add_argument("--path", type=str, help="スキャン対象のベースディレクトリ")
    parser.add_argument("--ci", action="store_true", help="CIモード（HIGHリスク検出時に非ゼロ終了）")
    parser.add_argument("--json", type=str, default="skill_security_report.json", help="JSON レポートの出力先")
    parser.add_argument("--quiet", action="store_true", help="詳細出力を抑制")
    args = parser.parse_args()

    # ベースパスの決定
    if args.path:
        base_path = Path(args.path)
    else:
        # スクリプトの2つ上のディレクトリ（プロジェクトルート）
        base_path = Path(__file__).resolve().parent.parent

    print(f"スキャン対象: {base_path}")
    print()

    # スキルディレクトリの検出
    skill_dirs = find_skill_directories(base_path)

    if not skill_dirs:
        print("スキルディレクトリが見つかりませんでした。")
        sys.exit(0)

    # 各スキルをスキャン
    reports = []
    for skill_dir in skill_dirs:
        report = scan_skill_directory(skill_dir)
        reports.append(report)

    # レポート出力
    high_count = print_report(reports, verbose=not args.quiet)

    # JSON レポート保存
    save_report_json(reports, args.json)

    # CIモードではHIGHリスク検出時に非ゼロ終了
    if args.ci and high_count > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
