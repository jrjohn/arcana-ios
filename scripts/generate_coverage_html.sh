#!/bin/bash

# Script to automatically generate HTML coverage report after tests
# This script finds the latest xcresult bundle and generates coverage reports

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔍 Finding latest test results..."

# Find the most recent xcresult bundle
LATEST_XCRESULT=$(find DerivedData/Logs/Test -name "*.xcresult" -type d 2>/dev/null | head -1)

if [ -z "$LATEST_XCRESULT" ]; then
    echo "❌ No test results found. Please run tests first."
    exit 1
fi

echo "📊 Using test results from: $LATEST_XCRESULT"

# Create docs directory if it doesn't exist
mkdir -p docs

# Generate JSON coverage report
echo "📝 Generating JSON coverage data..."
xcrun xccov view --report --json "$LATEST_XCRESULT" > coverage_report.json 2>&1 || {
    echo "⚠️  Warning: Failed to generate JSON coverage report"
    echo "   The xcresult bundle may be incomplete or from a failed test run"
    exit 1
}

# Generate text coverage report
echo "📝 Generating text coverage report..."
xcrun xccov view --report "$LATEST_XCRESULT" > coverage_report.txt 2>&1 || {
    echo "⚠️  Warning: Failed to generate text coverage report"
}

# Generate HTML coverage report
echo "🎨 Generating HTML coverage report..."
python3 generate_html_coverage.py coverage_report.json docs/test-coverage.html

# Also copy to root for backward compatibility
cp docs/test-coverage.html coverage_report.html

echo ""
echo "✅ Coverage reports generated successfully!"
echo ""
echo "📄 Reports available at:"
echo "   - docs/test-coverage.html (HTML - open in browser)"
echo "   - coverage_report.json (JSON data)"
echo "   - coverage_report.txt (Text summary)"
echo ""
echo "🌐 To view the HTML report, run:"
echo "   open docs/test-coverage.html"
echo ""
