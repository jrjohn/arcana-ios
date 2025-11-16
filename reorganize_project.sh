#!/bin/bash

# Arcana iOS Project Reorganization Script
# This script moves all files into proper SPM structure

set -e  # Exit on error

PROJECT_ROOT="/Users/jrjohn/Documents/projects/arcana-ios"
APP_DIR="$PROJECT_ROOT/arcana-ios"

cd "$APP_DIR"

echo "🚀 Starting Arcana iOS Project Reorganization"
echo "=============================================="

# Create necessary directories if they don't exist
echo "📁 Creating directory structure..."

mkdir -p Sources/ArcanaCore/Analytics
mkdir -p Sources/ArcanaCore/Common
mkdir -p Sources/ArcanaCore/DI
mkdir -p Sources/ArcanaDomain/Model
mkdir -p Sources/ArcanaDomain/Service
mkdir -p Sources/ArcanaDomain/Validation
mkdir -p Sources/ArcanaData/Local/Entities
mkdir -p Sources/ArcanaData/Remote
mkdir -p Sources/ArcanaData/Repository
mkdir -p Sources/ArcanaPresentation/Screens/User
mkdir -p Sources/ArcanaPresentation/Components
mkdir -p Sources/ArcanaPresentation/Theme
mkdir -p Tests/ArcanaDomainTests
mkdir -p Tests/ArcanaPresentationTests
mkdir -p Tests/ArcanaDataTests
mkdir -p Resources

echo "✅ Directory structure created"

# Remove duplicate root-level Swift files (keeping Sources versions)
echo "🧹 Removing duplicate root-level Swift files..."

# Core files
rm -f CoreAnalyticsAnalyticsEvent.swift
rm -f CoreAnalyticsAnalyticsTracker.swift
rm -f CoreAnalyticsPersistentAnalyticsTracker.swift
rm -f CoreCommonAppError.swift
rm -f CoreCommonErrorCode.swift
rm -f CoreCommonExtensions.swift
rm -f CoreCommonLRUCache.swift
rm -f CoreDIAppDependencies.swift
rm -f CoreDIDIContainer.swift

# Domain files
rm -f DomainModelUser.swift
rm -f DomainServiceUserService.swift
rm -f DomainServiceUserServiceImpl.swift
rm -f DomainValidationUserValidator.swift

# Data files
rm -f DataLocalEntitiesAnalyticsEventEntity.swift
rm -f DataLocalEntitiesUserEntity.swift
rm -f DataLocalLocalUserDataSource.swift
rm -f DataLocalSwiftDataUserDataSource.swift
rm -f DataRemoteMockRemoteUserDataSource.swift
rm -f DataRemoteRemoteUserDataSource.swift
rm -f DataRepositoryOfflineFirstUserRepository.swift
rm -f DataRepositoryUserRepository.swift

# Presentation files
rm -f PresentationComponentsUserCard.swift
rm -f PresentationScreensUserUserFormView.swift
rm -f PresentationScreensUserUserFormViewModel.swift
rm -f PresentationScreensUserUserListView.swift
rm -f PresentationScreensUserUserListViewModel.swift
rm -f PresentationThemeArcanaTheme.swift

echo "✅ Duplicate files removed"

# Move test files to proper location
echo "📝 Organizing test files..."

if [ -f "arcana-iosTestsUserListViewModelTests.swift" ]; then
    mv arcana-iosTestsUserListViewModelTests.swift Tests/ArcanaPresentationTests/UserListViewModelTests.swift
fi

if [ -f "arcana-iosTestsUserValidatorTests.swift" ]; then
    mv arcana-iosTestsUserValidatorTests.swift Tests/ArcanaDomainTests/UserValidatorTests.swift
fi

echo "✅ Test files organized"

# Move documentation and helper files to Resources
echo "📚 Organizing documentation..."

mkdir -p Documentation

mv -f *.md Documentation/ 2>/dev/null || true
mv -f *.sh Documentation/ 2>/dev/null || true

# Keep important docs at root
cp Documentation/README.md . 2>/dev/null || true

echo "✅ Documentation organized"

# Clean up obsolete Item.swift if it exists
if [ -f "Item.swift" ]; then
    echo "🗑️ Removing obsolete Item.swift..."
    rm -f Item.swift
fi

# Remove old ContentView.swift if using proper structure
if [ -f "ContentView.swift" ] && [ -f "Sources/ArcanaPresentation/Screens/User/UserListView.swift" ]; then
    echo "🗑️ Removing old ContentView.swift (replaced by proper views)..."
    rm -f ContentView.swift
fi

echo ""
echo "✅ Reorganization Complete!"
echo "=============================================="
echo ""
echo "📦 Current Structure:"
echo "  • Sources/ArcanaCore       - Core utilities, analytics, DI"
echo "  • Sources/ArcanaDomain     - Business logic & models"
echo "  • Sources/ArcanaData       - Repositories & data sources"
echo "  • Sources/ArcanaPresentation - Views & ViewModels"
echo "  • Tests/                   - Unit tests"
echo "  • Documentation/           - Docs and helper scripts"
echo ""
echo "🎯 Next Steps:"
echo "  1. Open the project in Xcode"
echo "  2. Update file references if needed"
echo "  3. Build and verify (Cmd+B)"
echo "  4. Run tests (Cmd+U)"
echo ""
