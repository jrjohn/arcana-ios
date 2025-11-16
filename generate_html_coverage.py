#!/usr/bin/env python3
"""
Generate HTML coverage report from Xcode coverage JSON
"""
import json
import sys
from datetime import datetime

def get_coverage_class(coverage):
    """Return CSS class based on coverage percentage"""
    if coverage >= 90:
        return 'excellent'
    elif coverage >= 70:
        return 'good'
    elif coverage >= 50:
        return 'moderate'
    else:
        return 'low'

def format_coverage(coverage):
    """Format coverage as percentage"""
    return f"{coverage:.2f}%"

def generate_html_report(json_file, output_file):
    """Generate HTML report from JSON coverage data"""

    with open(json_file, 'r') as f:
        data = json.load(f)

    targets = data.get('targets', [])

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Coverage Report - arcana-ios</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}

        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            color: #333;
        }}

        .container {{
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }}

        header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }}

        h1 {{
            font-size: 2.5em;
            margin-bottom: 10px;
            font-weight: 700;
        }}

        .subtitle {{
            font-size: 1.1em;
            opacity: 0.9;
        }}

        .timestamp {{
            margin-top: 15px;
            font-size: 0.9em;
            opacity: 0.8;
        }}

        .summary {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            padding: 30px 40px;
            background: #f8f9fa;
            border-bottom: 1px solid #dee2e6;
        }}

        .summary-card {{
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}

        .summary-card h3 {{
            color: #6c757d;
            font-size: 0.9em;
            text-transform: uppercase;
            margin-bottom: 10px;
            font-weight: 600;
        }}

        .summary-card .value {{
            font-size: 2em;
            font-weight: bold;
            color: #667eea;
        }}

        .content {{
            padding: 40px;
        }}

        h2 {{
            font-size: 1.8em;
            margin: 30px 0 20px 0;
            color: #495057;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }}

        table {{
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}

        thead {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }}

        th {{
            padding: 15px;
            text-align: left;
            font-weight: 600;
            font-size: 0.95em;
        }}

        td {{
            padding: 12px 15px;
            border-bottom: 1px solid #dee2e6;
        }}

        tbody tr:hover {{
            background-color: #f8f9fa;
        }}

        .file-path {{
            font-family: 'Monaco', 'Menlo', monospace;
            font-size: 0.9em;
            color: #495057;
        }}

        .coverage-bar {{
            height: 20px;
            background: #e9ecef;
            border-radius: 10px;
            overflow: hidden;
            position: relative;
        }}

        .coverage-fill {{
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.75em;
            font-weight: bold;
            color: white;
            transition: width 0.3s ease;
        }}

        .excellent {{ background: linear-gradient(90deg, #10b981 0%, #059669 100%); }}
        .good {{ background: linear-gradient(90deg, #3b82f6 0%, #2563eb 100%); }}
        .moderate {{ background: linear-gradient(90deg, #f59e0b 0%, #d97706 100%); }}
        .low {{ background: linear-gradient(90deg, #ef4444 0%, #dc2626 100%); }}

        .stats {{
            display: inline-block;
            margin-right: 20px;
            padding: 5px 12px;
            background: #f8f9fa;
            border-radius: 20px;
            font-size: 0.9em;
        }}

        .legend {{
            display: flex;
            gap: 20px;
            margin: 20px 0;
            flex-wrap: wrap;
        }}

        .legend-item {{
            display: flex;
            align-items: center;
            gap: 8px;
        }}

        .legend-color {{
            width: 30px;
            height: 20px;
            border-radius: 4px;
        }}

        footer {{
            background: #f8f9fa;
            padding: 20px 40px;
            text-align: center;
            color: #6c757d;
            font-size: 0.9em;
            border-top: 1px solid #dee2e6;
        }}

        .target-header {{
            background: #e9ecef;
            padding: 15px;
            margin: 20px 0 10px 0;
            border-radius: 8px;
            font-weight: 600;
        }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>📊 Test Coverage Report</h1>
            <div class="subtitle">arcana-ios Project</div>
            <div class="timestamp">Generated on {datetime.now().strftime("%B %d, %Y at %I:%M %p")}</div>
        </header>
"""

    # Calculate overall statistics from top-level data
    overall_coverage = data.get('lineCoverage', 0) * 100
    total_lines = data.get('executableLines', 0)
    covered_lines = data.get('coveredLines', 0)
    target_count = len(targets)

    html += f"""
        <div class="summary">
            <div class="summary-card">
                <h3>Overall Coverage</h3>
                <div class="value">{format_coverage(overall_coverage)}</div>
            </div>
            <div class="summary-card">
                <h3>Targets</h3>
                <div class="value">{target_count}</div>
            </div>
            <div class="summary-card">
                <h3>Total Lines</h3>
                <div class="value">{int(total_lines):,}</div>
            </div>
            <div class="summary-card">
                <h3>Covered Lines</h3>
                <div class="value">{int(covered_lines):,}</div>
            </div>
        </div>

        <div class="content">
            <div class="legend">
                <div class="legend-item">
                    <div class="legend-color excellent"></div>
                    <span>Excellent (≥90%)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color good"></div>
                    <span>Good (70-90%)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color moderate"></div>
                    <span>Moderate (50-70%)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color low"></div>
                    <span>Low (<50%)</span>
                </div>
            </div>
"""

    # Group targets and files
    for target in targets:
        target_name = target.get('name', 'Unknown')
        target_coverage = target.get('lineCoverage', 0)
        target_lines = target.get('executableLines', 0)
        target_covered = target.get('coveredLines', 0)

        html += f"""
            <h2>{target_name}</h2>
            <div class="target-header">
                <span class="stats">Coverage: {format_coverage(target_coverage)}</span>
                <span class="stats">Lines: {target_covered:,} / {target_lines:,}</span>
            </div>

            <table>
                <thead>
                    <tr>
                        <th>File</th>
                        <th style="width: 300px;">Coverage</th>
                        <th style="width: 120px; text-align: right;">Lines</th>
                        <th style="width: 120px; text-align: right;">Covered</th>
                        <th style="width: 100px; text-align: right;">%</th>
                    </tr>
                </thead>
                <tbody>
"""

        files = target.get('files', [])
        # Sort files by coverage (lowest first to highlight issues)
        files_sorted = sorted(files, key=lambda x: x.get('lineCoverage', 0))

        for file in files_sorted:
            file_path = file.get('path', 'Unknown')
            file_name = file_path.split('/')[-1]
            coverage = file.get('lineCoverage', 0)
            lines = file.get('executableLines', 0)
            covered = file.get('coveredLines', 0)
            css_class = get_coverage_class(coverage)

            html += f"""
                    <tr>
                        <td class="file-path" title="{file_path}">{file_name}</td>
                        <td>
                            <div class="coverage-bar">
                                <div class="coverage-fill {css_class}" style="width: {coverage}%;">
                                    {format_coverage(coverage) if coverage > 15 else ''}
                                </div>
                            </div>
                        </td>
                        <td style="text-align: right;">{lines:,}</td>
                        <td style="text-align: right;">{covered:,}</td>
                        <td style="text-align: right; font-weight: bold;">{format_coverage(coverage)}</td>
                    </tr>
"""

        html += """
                </tbody>
            </table>
"""

    html += """
        </div>

        <footer>
            Generated with ❤️ by arcana-ios coverage tool
        </footer>
    </div>
</body>
</html>
"""

    with open(output_file, 'w') as f:
        f.write(html)

    print(f"✅ HTML coverage report generated: {output_file}")
    print(f"📊 Overall Coverage: {format_coverage(overall_coverage)}")
    print(f"📁 Open the file in your browser to view the report")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 generate_html_coverage.py <input.json> [output.html]")
        print("Example: python3 generate_html_coverage.py coverage_report.json docs/test-coverage.html")
        sys.exit(1)

    json_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else 'coverage_report.html'

    generate_html_report(json_file, output_file)
