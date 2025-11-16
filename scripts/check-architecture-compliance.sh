#!/usr/bin/env bash

#
# Architecture Compliance Checker
# Validates codebase against defined architecture rules
# Generates HTML report at docs/architecture-compliance.html
#

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCES_DIR="$PROJECT_ROOT/arcana-ios/Sources"
RULES_DIR="$PROJECT_ROOT/docs/rules"
OUTPUT_DIR="$PROJECT_ROOT/docs"
OUTPUT_FILE="$OUTPUT_DIR/architecture-compliance.html"
JSON_OUTPUT="$OUTPUT_DIR/compliance-data.json"

echo -e "${BLUE}🏗️  Architecture Compliance Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "📁 Project: $PROJECT_ROOT"
echo "📂 Sources: $SOURCES_DIR"
echo "📋 Rules:   $RULES_DIR"
echo "📊 Output:  $OUTPUT_FILE"
echo ""

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq is not installed. Installing via brew...${NC}"
    if command -v brew &> /dev/null; then
        brew install jq
    else
        echo -e "${RED}❌ Homebrew not found. Please install jq manually.${NC}"
        exit 1
    fi
fi

# Initialize counters
declare -A severity_counts
severity_counts[error]=0
severity_counts[warning]=0
severity_counts[info]=0

# Results array
declare -a violations

# Function to scan files with a rule
scan_rule() {
    local rule_file=$1
    local rule_name=$(jq -r '.name' "$rule_file")
    local rules=$(jq -c '.rules[]' "$rule_file")

    echo -e "${CYAN}🔍 Checking: $rule_name${NC}"

    while IFS= read -r rule; do
        local rule_id=$(echo "$rule" | jq -r '.id')
        local rule_desc=$(echo "$rule" | jq -r '.description')
        local pattern=$(echo "$rule" | jq -r '.pattern')
        local file_pattern=$(echo "$rule" | jq -r '.file_pattern')
        local severity=$(echo "$rule" | jq -r '.severity // "warning"')
        local message=$(echo "$rule" | jq -r '.message')
        local exclude=$(echo "$rule" | jq -r '.exclude_pattern // ""')

        # Find files matching the pattern
        local files=()
        if [[ "$file_pattern" == *"*"* ]]; then
            # Use find for glob patterns
            while IFS= read -r -d '' file; do
                files+=("$file")
            done < <(find "$SOURCES_DIR" -type f -name "*.swift" -print0 2>/dev/null)
        else
            # Direct path
            if [[ -f "$SOURCES_DIR/$file_pattern" ]]; then
                files=("$SOURCES_DIR/$file_pattern")
            fi
        fi

        # Scan each file
        for file in "${files[@]}"; do
            # Skip if matches exclude pattern
            if [[ -n "$exclude" ]] && [[ "$file" =~ $exclude ]]; then
                continue
            fi

            # Check if file matches the file_pattern
            local rel_path="${file#$SOURCES_DIR/}"
            if [[ "$file_pattern" == *"*"* ]]; then
                # Convert glob to regex
                local pattern_regex="${file_pattern//\*\*/.*}"
                pattern_regex="${pattern_regex//\*/[^/]*}"
                if [[ ! "$rel_path" =~ $pattern_regex ]]; then
                    continue
                fi
            fi

            # Search for pattern violations
            local line_num=0
            while IFS= read -r line; do
                ((line_num++))
                if echo "$line" | grep -qE "$pattern"; then
                    # Skip comments if it's a comment line
                    if [[ "$line" =~ ^[[:space:]]*// ]]; then
                        continue
                    fi

                    # Record violation
                    violations+=("$rule_id|$severity|$file|$line_num|$message|$line")
                    ((severity_counts[$severity]++))
                fi
            done < "$file"
        done
    done <<< "$rules"
}

# Load and process all rule files
echo -e "${PURPLE}📋 Loading Rules...${NC}"
echo ""

if [[ ! -d "$RULES_DIR" ]]; then
    echo -e "${RED}❌ Rules directory not found: $RULES_DIR${NC}"
    exit 1
fi

rule_files=("$RULES_DIR"/*.json)
if [[ ${#rule_files[@]} -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  No rule files found in $RULES_DIR${NC}"
    exit 0
fi

for rule_file in "${rule_files[@]}"; do
    if [[ -f "$rule_file" ]]; then
        local enabled=$(jq -r '.enabled // true' "$rule_file")
        if [[ "$enabled" == "true" ]]; then
            scan_rule "$rule_file"
        else
            echo -e "${YELLOW}⏭️  Skipped (disabled): $(basename "$rule_file")${NC}"
        fi
    fi
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Results Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

total_violations=${#violations[@]}
echo -e "Total Violations: ${YELLOW}$total_violations${NC}"
echo -e "  ${RED}Errors:   ${severity_counts[error]}${NC}"
echo -e "  ${YELLOW}Warnings: ${severity_counts[warning]}${NC}"
echo -e "  ${CYAN}Info:     ${severity_counts[info]}${NC}"
echo ""

# Generate JSON data for HTML report
echo -e "${PURPLE}📝 Generating JSON data...${NC}"

cat > "$JSON_OUTPUT" << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "project": "arcana-ios",
  "summary": {
    "total": $total_violations,
    "errors": ${severity_counts[error]},
    "warnings": ${severity_counts[warning]},
    "info": ${severity_counts[info]}
  },
  "violations": [
EOF

first=true
for violation in "${violations[@]}"; do
    IFS='|' read -r rule_id severity file line_num message line_content <<< "$violation"

    if [[ "$first" == "false" ]]; then
        echo "," >> "$JSON_OUTPUT"
    fi
    first=false

    # Escape JSON strings
    file_escaped=$(echo "$file" | sed 's/\\/\\\\/g; s/"/\\"/g')
    message_escaped=$(echo "$message" | sed 's/\\/\\\\/g; s/"/\\"/g')
    line_escaped=$(echo "$line_content" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g')

    cat >> "$JSON_OUTPUT" << EOF
    {
      "ruleId": "$rule_id",
      "severity": "$severity",
      "file": "$file_escaped",
      "line": $line_num,
      "message": "$message_escaped",
      "code": "$line_escaped"
    }
EOF
done

cat >> "$JSON_OUTPUT" << EOF

  ]
}
EOF

# Generate HTML report
echo -e "${PURPLE}📄 Generating HTML report...${NC}"

cat > "$OUTPUT_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Architecture Compliance Report - Arcana iOS</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
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

        .violation-title {
            flex: 1;
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

        .violation-meta span {
            display: flex;
            align-items: center;
            gap: 0.3rem;
        }

        .severity-badge {
            padding: 0.25rem 0.75rem;
            border-radius: 4px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .severity-badge.error {
            background: #dc3545;
            color: white;
        }

        .severity-badge.warning {
            background: #ffc107;
            color: #212529;
        }

        .severity-badge.info {
            background: #17a2b8;
            color: white;
        }

        .violation-code {
            background: #f8f9fa;
            border: 1px solid #e9ecef;
            border-radius: 6px;
            padding: 1rem;
            margin-top: 1rem;
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

        .empty-state svg {
            width: 80px;
            height: 80px;
            margin-bottom: 1rem;
            opacity: 0.5;
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

        @media (max-width: 768px) {
            body {
                padding: 1rem;
            }

            .header {
                padding: 2rem 1.5rem;
            }

            .header h1 {
                font-size: 1.8rem;
            }

            .summary {
                grid-template-columns: repeat(2, 1fr);
                padding: 1.5rem;
            }

            .filters {
                padding: 1rem;
            }

            .violations {
                padding: 1rem;
            }
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
                <input type="text" id="search" placeholder="🔍 Search violations by file, rule, or message...">
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

                // Update summary
                document.getElementById('total-count').textContent = data.summary.total;
                document.getElementById('error-count').textContent = data.summary.errors;
                document.getElementById('warning-count').textContent = data.summary.warnings;
                document.getElementById('info-count').textContent = data.summary.info;
                document.getElementById('timestamp').textContent = `Generated: ${new Date(data.timestamp).toLocaleString()}`;

                allViolations = data.violations;
                renderViolations();
            } catch (error) {
                console.error('Failed to load compliance data:', error);
                document.getElementById('violations-container').innerHTML = `
                    <div class="empty-state">
                        <h3>Error loading data</h3>
                        <p>Failed to load compliance-data.json</p>
                    </div>
                `;
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
                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                        </svg>
                        <h3>No violations found!</h3>
                        <p>Your code is compliant with the architecture rules.</p>
                    </div>
                `;
                return;
            }

            container.innerHTML = filtered.map(v => {
                const fileName = v.file.split('/').pop();
                const filePath = v.file.replace(/^.*\/Sources\//, 'Sources/');

                return `
                    <div class="violation-item ${v.severity}">
                        <div class="violation-header">
                            <div class="violation-title">
                                <h3>${v.message}</h3>
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

        // Event listeners
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

        // Load data on page load
        loadData();
    </script>
</body>
</html>
HTMLEOF

echo -e "${GREEN}✅ HTML report generated: $OUTPUT_FILE${NC}"
echo ""

# Print some sample violations if any
if [[ $total_violations -gt 0 ]]; then
    echo -e "${YELLOW}📋 Sample Violations:${NC}"
    echo ""

    count=0
    for violation in "${violations[@]}"; do
        if [[ $count -ge 5 ]]; then
            break
        fi

        IFS='|' read -r rule_id severity file line_num message line_content <<< "$violation"
        rel_file="${file#$SOURCES_DIR/}"

        case $severity in
            error)   color=$RED ;;
            warning) color=$YELLOW ;;
            info)    color=$CYAN ;;
            *)       color=$NC ;;
        esac

        echo -e "${color}[$severity] $rule_id${NC}"
        echo -e "  📄 $rel_file:$line_num"
        echo -e "  💬 $message"
        echo ""

        ((count++))
    done

    if [[ $total_violations -gt 5 ]]; then
        echo -e "${CYAN}... and $((total_violations - 5)) more violations${NC}"
        echo ""
    fi
fi

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Compliance check complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "📊 View detailed report: open $OUTPUT_FILE"
echo ""

# Exit code based on errors
if [[ ${severity_counts[error]} -gt 0 ]]; then
    exit 1
else
    exit 0
fi
