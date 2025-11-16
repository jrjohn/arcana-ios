#!/bin/bash

# Ultra-Robust Fix Script - Works from anywhere in the project

echo "🔧 Fixing SPM structure..."
echo ""

# Find Package.swift
PACKAGE_FILE=""
SEARCH_DIRS=("." ".." "../.." "../../..")

echo "🔍 Looking for Package.swift..."
for dir in "${SEARCH_DIRS[@]}"; do
    if [ -f "$dir/Package.swift" ]; then
        PACKAGE_FILE="$dir/Package.swift"
        PROJECT_ROOT="$(cd "$dir" && pwd)"
        echo "✅ Found Package.swift at: $PROJECT_ROOT"
        break
    fi
done

if [ -z "$PACKAGE_FILE" ]; then
    echo "❌ Error: Could not find Package.swift"
    echo ""
    echo "Please run this command to find it:"
    echo "  find ~ -name 'Package.swift' -path '*/arcana-ios/*' 2>/dev/null"
    exit 1
fi

# Navigate to project root
cd "$PROJECT_ROOT" || exit 1
echo "📁 Working directory: $(pwd)"
echo ""

# Create directories
echo "📁 Creating SPM directories..."
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

# Function to find and copy file
find_and_copy() {
    local pattern="$1"
    local dest="$2"
    
    # Search in current directory and subdirectories
    local found_file=$(find . -maxdepth 3 -name "$pattern" -type f | head -1)
    
    if [ -n "$found_file" ]; then
        cp "$found_file" "$dest"
        echo "  ✓ Copied: $pattern"
        return 0
    else
        echo "  ⚠ Not found: $pattern"
        return 1
    fi
}

# Core Module
echo "📦 Core Module..."
find_and_copy "CoreAnalyticsAnalyticsEvent.swift" "Sources/ArcanaCore/Analytics/AnalyticsEvent.swift"
find_and_copy "CoreAnalyticsAnalyticsTracker.swift" "Sources/ArcanaCore/Analytics/AnalyticsTracker.swift"
find_and_copy "CoreAnalyticsPersistentAnalyticsTracker.swift" "Sources/ArcanaCore/Analytics/PersistentAnalyticsTracker.swift"
find_and_copy "CoreCommonErrorCode.swift" "Sources/ArcanaCore/Common/ErrorCode.swift"
find_and_copy "CoreCommonAppError.swift" "Sources/ArcanaCore/Common/AppError.swift"
find_and_copy "CoreCommonLRUCache.swift" "Sources/ArcanaCore/Common/LRUCache.swift"
find_and_copy "CoreCommonExtensions.swift" "Sources/ArcanaCore/Common/Extensions.swift"
find_and_copy "CoreDIDIContainer.swift" "Sources/ArcanaCore/DI/DIContainer.swift"
find_and_copy "CoreDIUserServiceDependency.swift" "Sources/ArcanaCore/DI/UserServiceDependency.swift"
find_and_copy "CoreDIAnalyticsTrackerDependency.swift" "Sources/ArcanaCore/DI/AnalyticsTrackerDependency.swift"
find_and_copy "CoreDIUserRepositoryDependency.swift" "Sources/ArcanaCore/DI/UserRepositoryDependency.swift"
find_and_copy "CoreDIAppDependencies.swift" "Sources/ArcanaCore/DI/AppDependencies.swift"

# Domain Module
echo "📦 Domain Module..."
find_and_copy "DomainModelUser.swift" "Sources/ArcanaDomain/Model/User.swift"
find_and_copy "DomainServiceUserService.swift" "Sources/ArcanaDomain/Service/UserService.swift"
find_and_copy "DomainServiceUserServiceImpl.swift" "Sources/ArcanaDomain/Service/UserServiceImpl.swift"
find_and_copy "DomainValidationUserValidator.swift" "Sources/ArcanaDomain/Validation/UserValidator.swift"

# Data Module
echo "📦 Data Module..."
find_and_copy "DataLocalLocalUserDataSource.swift" "Sources/ArcanaData/Local/LocalUserDataSource.swift"
find_and_copy "DataLocalSwiftDataUserDataSource.swift" "Sources/ArcanaData/Local/SwiftDataUserDataSource.swift"
find_and_copy "DataLocalEntitiesUserEntity.swift" "Sources/ArcanaData/Local/Entities/UserEntity.swift"
find_and_copy "DataLocalEntitiesAnalyticsEventEntity.swift" "Sources/ArcanaData/Local/Entities/AnalyticsEventEntity.swift"
find_and_copy "DataRemoteRemoteUserDataSource.swift" "Sources/ArcanaData/Remote/RemoteUserDataSource.swift"
find_and_copy "DataRemoteMockRemoteUserDataSource.swift" "Sources/ArcanaData/Remote/MockRemoteUserDataSource.swift"
find_and_copy "DataRepositoryUserRepository.swift" "Sources/ArcanaData/Repository/UserRepository.swift"
find_and_copy "DataRepositoryOfflineFirstUserRepository.swift" "Sources/ArcanaData/Repository/OfflineFirstUserRepository.swift"

# Presentation Module
echo "📦 Presentation Module..."
find_and_copy "PresentationScreensUserUserListView.swift" "Sources/ArcanaPresentation/Screens/User/UserListView.swift"
find_and_copy "PresentationScreensUserUserListViewModel.swift" "Sources/ArcanaPresentation/Screens/User/UserListViewModel.swift"
find_and_copy "PresentationScreensUserUserFormView.swift" "Sources/ArcanaPresentation/Screens/User/UserFormView.swift"
find_and_copy "PresentationScreensUserUserFormViewModel.swift" "Sources/ArcanaPresentation/Screens/User/UserFormViewModel.swift"
find_and_copy "PresentationComponentsUserCard.swift" "Sources/ArcanaPresentation/Components/UserCard.swift"
find_and_copy "PresentationThemeArcanaTheme.swift" "Sources/ArcanaPresentation/Theme/ArcanaTheme.swift"

# Test files
echo "📦 Test Files..."
find_and_copy "arcana-iosTestsUserValidatorTests.swift" "Tests/ArcanaDomainTests/UserValidatorTests.swift"
find_and_copy "arcana-iosTestsUserListViewModelTests.swift" "Tests/ArcanaPresentationTests/UserListViewModelTests.swift"

echo ""
echo "📊 File Summary:"
CORE_COUNT=$(find Sources/ArcanaCore -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
DOMAIN_COUNT=$(find Sources/ArcanaDomain -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
DATA_COUNT=$(find Sources/ArcanaData -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
PRES_COUNT=$(find Sources/ArcanaPresentation -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
TEST_COUNT=$(find Tests -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')

echo "  ArcanaCore: $CORE_COUNT files"
echo "  ArcanaDomain: $DOMAIN_COUNT files"
echo "  ArcanaData: $DATA_COUNT files"
echo "  ArcanaPresentation: $PRES_COUNT files"
echo "  Tests: $TEST_COUNT files"
echo ""

echo "🔨 Building package..."
if swift package clean && swift package resolve && swift build; then
    echo ""
    echo "=========================================="
    echo "✅ SUCCESS! Build Complete!"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "⚠️  Files Moved, Build Needs Attention"
    echo "=========================================="
fi

echo ""
echo "📁 Files are now in:"
echo "  $PROJECT_ROOT/Sources/"
echo ""
echo "🎯 Next Steps:"
echo "  1. cd $PROJECT_ROOT"
echo "  2. swift build"
echo "  3. open Package.swift"
echo ""
