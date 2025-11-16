#!/bin/bash

# Diagnostic script to find Package.swift and show current state

echo "🔍 Diagnostic Information"
echo "=========================="
echo ""

echo "📁 Current Directory:"
pwd
echo ""

echo "📄 Looking for Package.swift..."
if [ -f "Package.swift" ]; then
    echo "✅ Found Package.swift in current directory"
elif [ -f "../Package.swift" ]; then
    echo "⚠️  Found Package.swift in parent directory"
    echo "   Please cd .. and run the script again"
elif [ -f "../../Package.swift" ]; then
    echo "⚠️  Found Package.swift two directories up"
    echo "   Please cd ../.. and run the script again"
else
    echo "❌ Package.swift not found"
fi
echo ""

echo "📂 Files in current directory:"
ls -la | grep -E "\.swift$|Package" | head -20
echo ""

echo "📊 Swift files with prefixes:"
ls -1 | grep -E "^(Core|Domain|Data|Presentation)" | wc -l | xargs echo "  Found files:"
echo ""

echo "🗂  Directory structure:"
find . -maxdepth 2 -type d | grep -v "\.git\|\.build\|\.swiftpm" | head -20
echo ""

echo "💡 Suggestions:"
if [ -f "Package.swift" ]; then
    echo "  ✅ You're in the right place!"
    echo "  Run: ./fix_spm_structure.sh"
elif [ -f "../Package.swift" ]; then
    echo "  cd .."
    echo "  ./fix_spm_structure.sh"
else
    echo "  Find your Package.swift and navigate there"
fi
