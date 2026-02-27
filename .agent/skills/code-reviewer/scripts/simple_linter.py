import sys
import re

def analyze_code(file_path):
    """
    コード内の怪しいパターンを簡易検出するスクリプト
    """
    patterns = {
        "FIXME/TODO": r"(TODO|FIXME)",
        "Print Statement": r"(print\(|console\.log\()",
        "Hardcoded Token": r"(token|password|secret)\s*=",
        "Generic Exception": r"except Exception:",
    }

    print(f"--- Analyzing {file_path} ---")

    issues_found = False
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        for i, line in enumerate(lines):
            for issue_name, pattern in patterns.items():
                if re.search(pattern, line):
                    # print文などは意図的な場合もあるのでWARNレベル
                    level = "WARN" if "Print" in issue_name else "review-required"
                    print(f"Line {i+1} [{level}]: found {issue_name} -> {line.strip()}")
                    issues_found = True

        if not issues_found:
            print("No obvious issues found by simple_linter.")

    except FileNotFoundError:
        print("Error: File not found.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python simple_linter.py <file_path>")
    else:
        analyze_code(sys.argv[1])