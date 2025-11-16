#!/bin/bash

#
# find_hardcoded_values.sh
# Script to find hardcoded URLs and constants that should be moved to configuration
#

echo "🔍 Scanning for hardcoded values in arcana-ios project..."
echo ""

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCES_DIR="$PROJECT_ROOT/arcana-ios/Sources"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "📁 Project root: $PROJECT_ROOT"
echo "📂 Sources directory: $SOURCES_DIR"
echo ""

# Counter
total_issues=0

# Function to print section header
print_section() {
    echo ""
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${BLUE}$1${NC}"
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 1. Find hardcoded URLs
print_section "1. Hardcoded URLs (http/https)"
echo "${YELLOW}Looking for: http:// or https://${NC}"

url_count=$(grep -r "https\?://" "$SOURCES_DIR" --include="*.swift" -n | grep -v "//.*https://" | grep -v "comment" | wc -l | tr -d ' ')
if [ "$url_count" -gt 0 ]; then
    grep -r "https\?://" "$SOURCES_DIR" --include="*.swift" -n --color=always | grep -v "//.*https://" | grep -v "comment"
    echo ""
    echo "${RED}Found $url_count hardcoded URL(s)${NC}"
    total_issues=$((total_issues + url_count))
else
    echo "${GREEN}✓ No hardcoded URLs found${NC}"
fi

# 2. Find hardcoded timeouts
print_section "2. Hardcoded Timeout Values"
echo "${YELLOW}Looking for: timeoutInterval, timeout ==${NC}"

timeout_count=$(grep -r "timeoutInterval\|timeout\s*=" "$SOURCES_DIR" --include="*.swift" -n | grep -v "AppConfiguration" | grep -v "config\." | wc -l | tr -d ' ')
if [ "$timeout_count" -gt 0 ]; then
    grep -r "timeoutInterval\|timeout\s*=" "$SOURCES_DIR" --include="*.swift" -n --color=always | grep -v "AppConfiguration" | grep -v "config\."
    echo ""
    echo "${RED}Found $timeout_count hardcoded timeout value(s)${NC}"
    total_issues=$((total_issues + timeout_count))
else
    echo "${GREEN}✓ No hardcoded timeouts found${NC}"
fi

# 3. Find hardcoded page sizes
print_section "3. Hardcoded Page Sizes"
echo "${YELLOW}Looking for: perPage, pageSize, per_page${NC}"

pagesize_count=$(grep -r "perPage\|pageSize\|per_page" "$SOURCES_DIR" --include="*.swift" -n | grep -v "AppConfiguration" | grep -v "config\." | grep "=" | wc -l | tr -d ' ')
if [ "$pagesize_count" -gt 0 ]; then
    grep -r "perPage\|pageSize\|per_page" "$SOURCES_DIR" --include="*.swift" -n --color=always | grep -v "AppConfiguration" | grep -v "config\." | grep "="
    echo ""
    echo "${RED}Found $pagesize_count hardcoded page size value(s)${NC}"
    total_issues=$((total_issues + pagesize_count))
else
    echo "${GREEN}✓ No hardcoded page sizes found${NC}"
fi

# 4. Find hardcoded retry counts
print_section "4. Hardcoded Retry Counts"
echo "${YELLOW}Looking for: retryCount, maxRetries${NC}"

retry_count=$(grep -r "retryCount\|maxRetries" "$SOURCES_DIR" --include="*.swift" -n | grep -v "AppConfiguration" | grep -v "config\." | grep "<\|>" | wc -l | tr -d ' ')
if [ "$retry_count" -gt 0 ]; then
    grep -r "retryCount\|maxRetries" "$SOURCES_DIR" --include="*.swift" -n --color=always | grep -v "AppConfiguration" | grep -v "config\." | grep "<\|>"
    echo ""
    echo "${RED}Found $retry_count hardcoded retry count value(s)${NC}"
    total_issues=$((total_issues + retry_count))
else
    echo "${GREEN}✓ No hardcoded retry counts found${NC}"
fi

# 5. Find hardcoded animation durations
print_section "5. Hardcoded Animation Durations"
echo "${YELLOW}Looking for: .animation, withAnimation, duration:${NC}"

animation_count=$(grep -r "duration:\s*[0-9]" "$SOURCES_DIR" --include="*.swift" -n | grep -v "AppConfiguration" | grep -v "config\." | wc -l | tr -d ' ')
if [ "$animation_count" -gt 0 ]; then
    grep -r "duration:\s*[0-9]" "$SOURCES_DIR" --include="*.swift" -n --color=always | grep -v "AppConfiguration" | grep -v "config\."
    echo ""
    echo "${RED}Found $animation_count hardcoded animation duration(s)${NC}"
    total_issues=$((total_issues + animation_count))
else
    echo "${GREEN}✓ No hardcoded animation durations found${NC}"
fi

# 6. Find hardcoded debounce delays
print_section "6. Hardcoded Debounce Delays"
echo "${YELLOW}Looking for: .debounce, Task.sleep${NC}"

debounce_count=$(grep -r "\.debounce\|Task\.sleep" "$SOURCES_DIR" --include="*.swift" -n | grep -v "AppConfiguration" | wc -l | tr -d ' ')
if [ "$debounce_count" -gt 0 ]; then
    grep -r "\.debounce\|Task\.sleep" "$SOURCES_DIR" --include="*.swift" -n --color=always | grep -v "AppConfiguration"
    echo ""
    echo "${RED}Found $debounce_count hardcoded debounce/sleep value(s)${NC}"
    total_issues=$((total_issues + debounce_count))
else
    echo "${GREEN}✓ No hardcoded debounce delays found${NC}"
fi

# 7. Find hardcoded cache sizes
print_section "7. Hardcoded Cache Sizes"
echo "${YELLOW}Looking for: cacheSize, maxSize, LRUCache${NC}"

cache_count=$(grep -r "cacheSize\|maxSize.*=\|LRUCache(" "$SOURCES_DIR" --include="*.swift" -n | grep -v "AppConfiguration" | grep -v "config\." | wc -l | tr -d ' ')
if [ "$cache_count" -gt 0 ]; then
    grep -r "cacheSize\|maxSize.*=\|LRUCache(" "$SOURCES_DIR" --include="*.swift" -n --color=always | grep -v "AppConfiguration" | grep -v "config\."
    echo ""
    echo "${RED}Found $cache_count hardcoded cache size value(s)${NC}"
    total_issues=$((total_issues + cache_count))
else
    echo "${GREEN}✓ No hardcoded cache sizes found${NC}"
fi

# Summary
print_section "📊 Summary"
echo ""
if [ "$total_issues" -gt 0 ]; then
    echo "${RED}Total hardcoded values found: $total_issues${NC}"
    echo ""
    echo "${YELLOW}Recommendation:${NC}"
    echo "1. Move these values to appropriate configuration files"
    echo "2. Use AppConstants or AppConfiguration to access them"
    echo "3. Consider environment-specific values in Config-{Environment}.plist"
    echo ""
    echo "${BLUE}Example migration:${NC}"
    echo "  ${RED}Before:${NC} let url = \"https://api.example.com\""
    echo "  ${GREEN}After:${NC}  let url = AppConstants.API.baseURL"
    echo ""
else
    echo "${GREEN}✓ Excellent! No hardcoded values found.${NC}"
    echo "${GREEN}Your code is using configuration properly.${NC}"
fi

echo ""
echo "🏁 Scan complete!"
echo ""
