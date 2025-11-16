#!/bin/bash

# Quick Fix Script - Moves all files to proper SPM structure
# Run this with: bash fix_spm_structure.sh

echo "🔧 Fixing SPM structure..."
echo ""

# Check if Package.swift exists
if [ ! -f "Package.swift" ]; then
    echo "❌ Error: Package.swift not found in current directory"
    echo "Please run this script from the arcana-ios project root directory"
    echo "Current directory: $(pwd)"
    exit 1
fi

echo "✅ Found Package.swift"
echo ""

# Create all necessary directories
echo "📁 Creating directories..."
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

echo "✅ Directories created"
echo ""

# Function to copy and rename file
copy_file() {
    local src="$1"
    local dest="$2"
    
    if [ -f "$src" ]; then
        cp "$src" "$dest"
        echo "  ✓ Copied: $(basename $src)"
        return 0
    else
        echo "  ⚠ Not found: $src"
        return 1
    fi
}

# Core Module
echo "📦 Moving Core module files..."
copy_file "CoreAnalyticsAnalyticsEvent.swift" "Sources/ArcanaCore/Analytics/AnalyticsEvent.swift"
copy_file "CoreAnalyticsAnalyticsTracker.swift" "Sources/ArcanaCore/Analytics/AnalyticsTracker.swift"
copy_file "CoreAnalyticsPersistentAnalyticsTracker.swift" "Sources/ArcanaCore/Analytics/PersistentAnalyticsTracker.swift"

copy_file "CoreCommonErrorCode.swift" "Sources/ArcanaCore/Common/ErrorCode.swift"
copy_file "CoreCommonAppError.swift" "Sources/ArcanaCore/Common/AppError.swift"
copy_file "CoreCommonLRUCache.swift" "Sources/ArcanaCore/Common/LRUCache.swift"
copy_file "CoreCommonExtensions.swift" "Sources/ArcanaCore/Common/Extensions.swift"

copy_file "CoreDIDIContainer.swift" "Sources/ArcanaCore/DI/DIContainer.swift"
copy_file "CoreDIUserServiceDependency.swift" "Sources/ArcanaCore/DI/UserServiceDependency.swift"
copy_file "CoreDIAnalyticsTrackerDependency.swift" "Sources/ArcanaCore/DI/AnalyticsTrackerDependency.swift"
copy_file "CoreDIUserRepositoryDependency.swift" "Sources/ArcanaCore/DI/UserRepositoryDependency.swift"
copy_file "CoreDIAppDependencies.swift" "Sources/ArcanaCore/DI/AppDependencies.swift"

echo "✅ Core module done (12 files)"
echo ""

# Domain Module
echo "📦 Moving Domain module files..."
copy_file "DomainModelUser.swift" "Sources/ArcanaDomain/Model/User.swift"
copy_file "DomainServiceUserService.swift" "Sources/ArcanaDomain/Service/UserService.swift"
copy_file "DomainServiceUserServiceImpl.swift" "Sources/ArcanaDomain/Service/UserServiceImpl.swift"
copy_file "DomainValidationUserValidator.swift" "Sources/ArcanaDomain/Validation/UserValidator.swift"

echo "✅ Domain module done (4 files)"
echo ""

# Data Module
echo "📦 Moving Data module files..."
copy_file "DataLocalLocalUserDataSource.swift" "Sources/ArcanaData/Local/LocalUserDataSource.swift"
copy_file "DataLocalSwiftDataUserDataSource.swift" "Sources/ArcanaData/Local/SwiftDataUserDataSource.swift"
copy_file "DataLocalEntitiesUserEntity.swift" "Sources/ArcanaData/Local/Entities/UserEntity.swift"
copy_file "DataLocalEntitiesAnalyticsEventEntity.swift" "Sources/ArcanaData/Local/Entities/AnalyticsEventEntity.swift"
copy_file "DataRemoteRemoteUserDataSource.swift" "Sources/ArcanaData/Remote/RemoteUserDataSource.swift"
copy_file "DataRemoteMockRemoteUserDataSource.swift" "Sources/ArcanaData/Remote/MockRemoteUserDataSource.swift"
copy_file "DataRepositoryUserRepository.swift" "Sources/ArcanaData/Repository/UserRepository.swift"
copy_file "DataRepositoryOfflineFirstUserRepository.swift" "Sources/ArcanaData/Repository/OfflineFirstUserRepository.swift"

echo "✅ Data module done (8 files)"
echo ""

# Presentation Module  
echo "📦 Moving Presentation module files..."
copy_file "PresentationScreensUserUserListView.swift" "Sources/ArcanaPresentation/Screens/User/UserListView.swift"
copy_file "PresentationScreensUserUserListViewModel.swift" "Sources/ArcanaPresentation/Screens/User/UserListViewModel.swift"
copy_file "PresentationScreensUserUserFormView.swift" "Sources/ArcanaPresentation/Screens/User/UserFormView.swift"
copy_file "PresentationScreensUserUserFormViewModel.swift" "Sources/ArcanaPresentation/Screens/User/UserFormViewModel.swift"
copy_file "PresentationComponentsUserCard.swift" "Sources/ArcanaPresentation/Components/UserCard.swift"
copy_file "PresentationThemeArcanaTheme.swift" "Sources/ArcanaPresentation/Theme/ArcanaTheme.swift"

echo "✅ Presentation module done (6 files)"
echo ""

# Test files
echo "📦 Moving test files..."
copy_file "arcana-iosTestsUserValidatorTests.swift" "Tests/ArcanaDomainTests/UserValidatorTests.swift"
copy_file "arcana-iosTestsUserListViewModelTests.swift" "Tests/ArcanaPresentationTests/UserListViewModelTests.swift"

echo "✅ Test files done (2 files)"
echo ""

# Count files
CORE_COUNT=$(find Sources/ArcanaCore -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
DOMAIN_COUNT=$(find Sources/ArcanaDomain -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
DATA_COUNT=$(find Sources/ArcanaData -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
PRES_COUNT=$(find Sources/ArcanaPresentation -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
TEST_COUNT=$(find Tests -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')

echo "📊 File Summary:"
echo "  ArcanaCore: $CORE_COUNT files"
echo "  ArcanaDomain: $DOMAIN_COUNT files"
echo "  ArcanaData: $DATA_COUNT files"
echo "  ArcanaPresentation: $PRES_COUNT files"
echo "  Tests: $TEST_COUNT files"
echo ""

# Verify structure
echo "🔍 Verifying structure..."
if [ -d "Sources/ArcanaCore" ] && [ -d "Sources/ArcanaDomain" ] && [ -d "Sources/ArcanaData" ] && [ -d "Sources/ArcanaPresentation" ]; then
    echo "✅ All module directories created"
else
    echo "❌ Some directories missing"
    exit 1
fi

echo ""
echo "🔨 Building package..."
echo "(This may take a moment...)"
echo ""

# Try to build
if swift package clean && swift package resolve && swift build 2>&1 | head -30; then
    BUILD_STATUS=$?
else
    BUILD_STATUS=$?
fi

echo ""
echo "=========================================="
if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ SUCCESS! SPM Structure Fixed!"
else
    echo "⚠️  Files Moved (Build needs attention)"
fi
echo "=========================================="
echo ""
echo "📁 Your files are now in:"
echo "  Sources/ArcanaCore/       ($CORE_COUNT files)"
echo "  Sources/ArcanaDomain/     ($DOMAIN_COUNT files)"
echo "  Sources/ArcanaData/       ($DATA_COUNT files)"
echo "  Sources/ArcanaPresentation/ ($PRES_COUNT files)"
echo "  Tests/                    ($TEST_COUNT files)"
echo ""
echo "🎯 Next steps:"
echo "  1. Run: swift build"
echo "  2. If successful, open in Xcode: open Package.swift"
echo "  3. Build with ⌘B"
echo ""

if [ $BUILD_STATUS -ne 0 ]; then
    echo "💡 If build failed, try:"
    echo "  swift package clean"
    echo "  rm -rf .build .swiftpm"
    echo "  swift package resolve"
    echo "  swift build"
    echo ""
fi
