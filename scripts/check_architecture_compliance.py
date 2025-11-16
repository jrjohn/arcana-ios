#!/usr/bin/env python3

"""
Architecture Compliance Checker
Validates codebase against defined architecture rules
Generates HTML report at docs/architecture-compliance.html
"""

import json
import re
import sys
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Any
import glob

class ComplianceChecker:
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.sources_dir = project_root / "arcana-ios" / "Sources"
        self.rules_dir = project_root / "docs" / "rules"
        self.output_dir = project_root / "docs"
        self.violations = []
        self.severity_counts = {"error": 0, "warning": 0, "info": 0}

    def load_rules(self) -> List[Dict[str, Any]]:
        """Load all rule files from the rules directory"""
        rule_files = list(self.rules_dir.glob("*.json"))
        if not rule_files:
            print(f"⚠️  No rule files found in {self.rules_dir}")
            return []

        all_rules = []
        for rule_file in rule_files:
            try:
                with open(rule_file, 'r') as f:
                    rule_set = json.load(f)
                    if rule_set.get("enabled", True):
                        all_rules.append(rule_set)
                        print(f"✓ Loaded: {rule_file.name}")
                    else:
                        print(f"⏭️  Skipped (disabled): {rule_file.name}")
            except Exception as e:
                print(f"❌ Error loading {rule_file.name}: {e}")

        return all_rules

    def match_file_pattern(self, file_path: Path, pattern: str) -> bool:
        """Check if file matches the glob pattern"""
        rel_path = str(file_path.relative_to(self.sources_dir))

        # Convert glob pattern to regex
        pattern_regex = pattern.replace("**", ".*").replace("*", "[^/]*")
        return bool(re.search(pattern_regex, rel_path))

    def scan_file(self, file_path: Path, rule: Dict[str, Any]) -> None:
        """Scan a single file for rule violations"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()

            pattern = rule.get("pattern", "")
            exclude_pattern = rule.get("exclude_pattern", "")
            severity = rule.get("severity", "warning")
            message = rule.get("message", "")
            rule_id = rule.get("id", "")

            # Skip if file matches exclude pattern
            if exclude_pattern and re.search(exclude_pattern, str(file_path)):
                return

            for line_num, line in enumerate(lines, 1):
                # Skip comment lines
                if line.strip().startswith("//"):
                    continue

                if re.search(pattern, line):
                    self.violations.append({
                        "ruleId": rule_id,
                        "severity": severity,
                        "file": str(file_path),
                        "line": line_num,
                        "message": message,
                        "code": line.rstrip()
                    })
                    self.severity_counts[severity] += 1

        except Exception as e:
            print(f"Warning: Error scanning {file_path}: {e}")

    def scan_rules(self, rule_sets: List[Dict[str, Any]]) -> None:
        """Scan all files against all rules"""
        for rule_set in rule_sets:
            rule_name = rule_set.get("name", "Unknown")
            rules = rule_set.get("rules", [])

            print(f"\n🔍 Checking: {rule_name}")

            for rule in rules:
                file_pattern = rule.get("file_pattern", "**/*.swift")

                # Find all Swift files
                swift_files = list(self.sources_dir.rglob("*.swift"))

                for file_path in swift_files:
                    if self.match_file_pattern(file_path, file_pattern):
                        self.scan_file(file_path, rule)

    def generate_json_report(self) -> None:
        """Generate JSON data file"""
        data = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "project": "arcana-ios",
            "summary": {
                "total": len(self.violations),
                "errors": self.severity_counts["error"],
                "warnings": self.severity_counts["warning"],
                "info": self.severity_counts["info"]
            },
            "violations": self.violations
        }

        json_file = self.output_dir / "compliance-data.json"
        with open(json_file, 'w') as f:
            json.dump(data, f, indent=2)

        print(f"✅ JSON data generated: {json_file}")

    def generate_html_report(self) -> None:
        """Generate HTML report"""
        html_content = '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Architecture Compliance Report - Arcana iOS</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 2rem;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            overflow: hidden;
        }

        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 3rem;
            text-align: center;
        }

        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 0.5rem;
            font-weight: 700;
        }

        .header p {
            font-size: 1.1rem;
            opacity: 0.9;
        }

        .timestamp {
            margin-top: 1rem;
            font-size: 0.9rem;
            opacity: 0.8;
        }

        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1.5rem;
            padding: 2rem 3rem;
            background: #f8f9fa;
            border-bottom: 1px solid #e9ecef;
        }

        .summary-card {
            background: white;
            padding: 1.5rem;
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
            text-align: center;
        }

        .summary-card .number {
            font-size: 3rem;
            font-weight: bold;
            margin-bottom: 0.5rem;
        }

        .summary-card .label {
            font-size: 0.9rem;
            color: #6c757d;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .summary-card.total .number { color: #667eea; }
        .summary-card.errors .number { color: #dc3545; }
        .summary-card.warnings .number { color: #ffc107; }
        .summary-card.info .number { color: #17a2b8; }

        .filters {
            padding: 1.5rem 3rem;
            background: white;
            border-bottom: 1px solid #e9ecef;
            display: flex;
            gap: 1rem;
            flex-wrap: wrap;
            align-items: center;
        }

        .filter-group {
            display: flex;
            gap: 0.5rem;
            align-items: center;
        }

        .filter-group label {
            font-weight: 500;
            color: #495057;
        }

        .filter-btn {
            padding: 0.5rem 1rem;
            border: 2px solid #dee2e6;
            background: white;
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.2s;
            font-size: 0.9rem;
        }

        .filter-btn:hover {
            border-color: #667eea;
            background: #f8f9fa;
        }

        .filter-btn.active {
            border-color: #667eea;
            background: #667eea;
            color: white;
        }

        .search-box {
            flex: 1;
            min-width: 250px;
        }

        .search-box input {
            width: 100%;
            padding: 0.6rem 1rem;
            border: 2px solid #dee2e6;
            border-radius: 6px;
            font-size: 0.9rem;
        }

        .search-box input:focus {
            outline: none;
            border-color: #667eea;
        }

        .violations {
            padding: 2rem 3rem;
            max-height: 800px;
            overflow-y: auto;
        }

        .violation-item {
            background: white;
            border: 1px solid #e9ecef;
            border-left: 4px solid #667eea;
            border-radius: 8px;
            padding: 1.5rem;
            margin-bottom: 1rem;
            transition: all 0.2s;
        }

        .violation-item:hover {
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
            transform: translateY(-2px);
        }

        .violation-item.error { border-left-color: #dc3545; }
        .violation-item.warning { border-left-color: #ffc107; }
        .violation-item.info { border-left-color: #17a2b8; }

        .violation-header {
            display: flex;
            justify-content: space-between;
            align-items: start;
            margin-bottom: 1rem;
        }

        .violation-title h3 {
            font-size: 1.1rem;
            margin-bottom: 0.5rem;
            color: #212529;
        }

        .violation-meta {
            display: flex;
            gap: 1rem;
            font-size: 0.85rem;
            color: #6c757d;
        }

        .severity-badge {
            padding: 0.25rem 0.75rem;
            border-radius: 4px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
        }

        .severity-badge.error { background: #dc3545; color: white; }
        .severity-badge.warning { background: #ffc107; color: #212529; }
        .severity-badge.info { background: #17a2b8; color: white; }

        .violation-code {
            background: #f8f9fa;
            border: 1px solid #e9ecef;
            border-radius: 6px;
            padding: 1rem;
            font-family: 'Monaco', 'Menlo', monospace;
            font-size: 0.85rem;
            overflow-x: auto;
        }

        .violation-code pre {
            margin: 0;
            white-space: pre-wrap;
            word-wrap: break-word;
        }

        .empty-state {
            text-align: center;
            padding: 4rem 2rem;
            color: #6c757d;
        }

        .empty-state h3 {
            font-size: 1.5rem;
            margin-bottom: 0.5rem;
            color: #495057;
        }

        .footer {
            background: #f8f9fa;
            padding: 2rem 3rem;
            text-align: center;
            color: #6c757d;
            font-size: 0.9rem;
            border-top: 1px solid #e9ecef;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🏗️ Architecture Compliance Report</h1>
            <p>Arcana iOS - Clean Architecture Validation</p>
            <div class="timestamp" id="timestamp"></div>
        </div>

        <div class="summary">
            <div class="summary-card total">
                <div class="number" id="total-count">0</div>
                <div class="label">Total Issues</div>
            </div>
            <div class="summary-card errors">
                <div class="number" id="error-count">0</div>
                <div class="label">Errors</div>
            </div>
            <div class="summary-card warnings">
                <div class="number" id="warning-count">0</div>
                <div class="label">Warnings</div>
            </div>
            <div class="summary-card info">
                <div class="number" id="info-count">0</div>
                <div class="label">Info</div>
            </div>
        </div>

        <div class="filters">
            <div class="filter-group">
                <label>Severity:</label>
                <button class="filter-btn active" data-filter="all">All</button>
                <button class="filter-btn" data-filter="error">Errors</button>
                <button class="filter-btn" data-filter="warning">Warnings</button>
                <button class="filter-btn" data-filter="info">Info</button>
            </div>
            <div class="search-box">
                <input type="text" id="search" placeholder="🔍 Search by file, rule, or message...">
            </div>
        </div>

        <div class="violations" id="violations-container"></div>

        <div class="footer">
            <p>Generated by Architecture Compliance Checker</p>
            <p>📖 Add custom rules in <code>docs/rules/*.json</code></p>
        </div>
    </div>

    <script>
        let allViolations = [];
        let currentFilter = 'all';
        let searchQuery = '';

        async function loadData() {
            try {
                const response = await fetch('compliance-data.json');
                const data = await response.json();

                document.getElementById('total-count').textContent = data.summary.total;
                document.getElementById('error-count').textContent = data.summary.errors;
                document.getElementById('warning-count').textContent = data.summary.warnings;
                document.getElementById('info-count').textContent = data.summary.info;
                document.getElementById('timestamp').textContent = `Generated: ${new Date(data.timestamp).toLocaleString()}`;

                allViolations = data.violations;
                renderViolations();
            } catch (error) {
                console.error('Failed to load data:', error);
            }
        }

        function renderViolations() {
            const container = document.getElementById('violations-container');

            let filtered = allViolations.filter(v => {
                const matchesFilter = currentFilter === 'all' || v.severity === currentFilter;
                const matchesSearch = !searchQuery ||
                    v.file.toLowerCase().includes(searchQuery) ||
                    v.message.toLowerCase().includes(searchQuery) ||
                    v.ruleId.toLowerCase().includes(searchQuery);
                return matchesFilter && matchesSearch;
            });

            if (filtered.length === 0) {
                container.innerHTML = `
                    <div class="empty-state">
                        <h3>✨ No violations found!</h3>
                        <p>Your code is compliant with the architecture rules.</p>
                    </div>
                `;
                return;
            }

            container.innerHTML = filtered.map(v => {
                const fileName = v.file.split('/').pop();
                const filePath = v.file.replace(/^.*\\/Sources\\//, 'Sources/');

                return `
                    <div class="violation-item ${v.severity}">
                        <div class="violation-header">
                            <div class="violation-title">
                                <h3>${escapeHtml(v.message)}</h3>
                                <div class="violation-meta">
                                    <span>📄 ${fileName}</span>
                                    <span>📍 Line ${v.line}</span>
                                    <span>🔖 ${v.ruleId}</span>
                                </div>
                            </div>
                            <span class="severity-badge ${v.severity}">${v.severity}</span>
                        </div>
                        <div class="violation-code">
                            <pre><code>${escapeHtml(v.code)}</code></pre>
                        </div>
                        <div style="margin-top: 0.5rem; font-size: 0.85rem; color: #6c757d;">
                            ${filePath}
                        </div>
                    </div>
                `;
            }).join('');
        }

        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                currentFilter = btn.dataset.filter;
                renderViolations();
            });
        });

        document.getElementById('search').addEventListener('input', (e) => {
            searchQuery = e.target.value.toLowerCase();
            renderViolations();
        });

        loadData();
    </script>
</body>
</html>'''

        html_file = self.output_dir / "architecture-compliance.html"
        with open(html_file, 'w') as f:
            f.write(html_content)

        print(f"✅ HTML report generated: {html_file}")

    def print_summary(self) -> None:
        """Print summary to console"""
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 Results Summary")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(f"\nTotal Violations: {len(self.violations)}")
        print(f"  Errors:   {self.severity_counts['error']}")
        print(f"  Warnings: {self.severity_counts['warning']}")
        print(f"  Info:     {self.severity_counts['info']}")

        if self.violations:
            print("\n📋 Sample Violations:\n")
            for violation in self.violations[:5]:
                rel_file = violation['file'].replace(str(self.sources_dir) + "/", "")
                print(f"[{violation['severity']}] {violation['ruleId']}")
                print(f"  📄 {rel_file}:{violation['line']}")
                print(f"  💬 {violation['message']}\n")

            if len(self.violations) > 5:
                print(f"... and {len(self.violations) - 5} more violations\n")

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✅ Compliance check complete!")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    def run(self) -> int:
        """Run the compliance check"""
        print("🏗️  Architecture Compliance Check")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(f"\n📁 Project: {self.project_root}")
        print(f"📂 Sources: {self.sources_dir}")
        print(f"📋 Rules:   {self.rules_dir}")
        print(f"📊 Output:  {self.output_dir}/architecture-compliance.html\n")

        # Load and process rules
        print("📋 Loading Rules...\n")
        rule_sets = self.load_rules()

        if not rule_sets:
            return 0

        # Scan codebase
        self.scan_rules(rule_sets)

        # Generate reports
        print("\n📝 Generating Reports...")
        self.generate_json_report()
        self.generate_html_report()

        # Print summary
        self.print_summary()

        print(f"\n📊 View report: open {self.output_dir}/architecture-compliance.html\n")

        # Return exit code based on errors
        return 1 if self.severity_counts['error'] > 0 else 0


def main():
    project_root = Path(__file__).parent.parent
    checker = ComplianceChecker(project_root)
    exit_code = checker.run()
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
