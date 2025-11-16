#!/bin/bash

# Ultimate Fix - Handles nested arcana-ios directory structure

echo "🔧 Ultimate SPM Structure Fix"
echo "=============================="
echo ""

# Determine where we are and where we need to be
CURRENT_DIR="$(pwd)"
echo "📁 Current: $CURRENT_DIR"

# Find the actual project root
if [ -f "Package.swift" ]; then
    PROJECT_ROOT="$CURRENT_DIR"
    SOURCE_DIR="$CURRENT_DIR"
elif [ -f "../Package.swift" ]; then
    PROJECT_ROOT="$(cd .. && pwd)"
    SOURCE_DIR="$CURRENT_DIR"
else
    echo "❌ Cannot find Package.swift"
    echo ""
    echo "Please navigate to: /Users/jrjohn/Documents/projects/arcana-ios"
    echo "Then run: ./fix_direct.sh"
    exit 1
fi

echo "📦 Project Root: $PROJECT_ROOT"
echo "📂 Source Files: $SOURCE_DIR"
echo ""

cd "$PROJECT_ROOT" || exit 1

# Create directories
echo "📁 Creating SPM directories..."
mkdir -p Sources/ArcanaCore/Analytics Sources/ArcanaCore/Common Sources/ArcanaCore/DI
mkdir -p Sources/ArcanaDomain/Model Sources/ArcanaDomain/Service Sources/ArcanaDomain/Validation
mkdir -p Sources/ArcanaData/Local/Entities Sources/ArcanaData/Remote Sources/ArcanaData/Repository
mkdir -p Sources/ArcanaPresentation/Screens/User Sources/ArcanaPresentation/Components Sources/ArcanaPresentation/Theme
mkdir -p Tests/ArcanaDomainTests Tests/ArcanaPresentationTests
echo "✅ Directories created"
echo ""

# Function to find and copy
find_copy() {
    local file="$1"
    local dest="$2"
    
    # Try current directory
    if [ -f "$file" ]; then
        cp "$file" "$dest" && echo "  ✓ $file" && return 0
    fi
    
    # Try arcana-ios subdirectory
    if [ -f "arcana-ios/$file" ]; then
        cp "arcana-ios/$file" "$dest" && echo "  ✓ arcana-ios/$file" && return 0
    fi
    
    # Try to find it anywhere in project
    local found=$(find . -name "$file" -type f ! -path "*/Sources/*" ! -path "*/.build/*" | head -1)
    if [ -n "$found" ]; then
        cp "$found" "$dest" && echo "  ✓ $(basename $found)" && return 0
    fi
    
    return 1
}

echo "📦 Copying files..."

# Core Module (12 files)
find_copy "CoreAnalyticsAnalyticsEvent.swift" "Sources/ArcanaCore/Analytics/AnalyticsEvent.swift"
find_copy "CoreAnalyticsAnalyticsTracker.swift" "Sources/ArcanaCore/Analytics/AnalyticsTracker.swift"
find_copy "CoreAnalyticsPersistentAnalyticsTracker.swift" "Sources/ArcanaCore/Analytics/PersistentAnalyticsTracker.swift"
find_copy "CoreCommonErrorCode.swift" "Sources/ArcanaCore/Common/ErrorCode.swift"
find_copy "CoreCommonAppError.swift" "Sources/ArcanaCore/Common/AppError.swift"
find_copy "CoreCommonLRUCache.swift" "Sources/ArcanaCore/Common/LRUCache.swift"
find_copy "CoreCommonExtensions.swift" "Sources/ArcanaCore/Common/Extensions.swift"
find_copy "CoreDIDIContainer.swift" "Sources/ArcanaCore/DI/DIContainer.swift"
find_copy "CoreDIUserServiceDependency.swift" "Sources/ArcanaCore/DI/UserServiceDependency.swift"
find_copy "CoreDIAnalyticsTrackerDependency.swift" "Sources/ArcanaCore/DI/AnalyticsTrackerDependency.swift"
find_copy "CoreDIUserRepositoryDependency.swift" "Sources/ArcanaCore/DI/UserRepositoryDependency.swift"
find_copy "CoreDIAppDependencies.swift" "Sources/ArcanaCore/DI/AppDependencies.swift"

# Domain Module (4 files)
find_copy "DomainModelUser.swift" "Sources/ArcanaDomain/Model/User.swift"
find_copy "DomainServiceUserService.swift" "Sources/ArcanaDomain/Service/UserService.swift"
find_copy "DomainServiceUserServiceImpl.swift" "Sources/ArcanaDomain/Service/UserServiceImpl.swift"
find_copy "DomainValidationUserValidator.swift" "Sources/ArcanaDomain/Validation/UserValidator.swift"

# Data Module (8 files)
find_copy "DataLocalLocalUserDataSource.swift" "Sources/ArcanaData/Local/LocalUserDataSource.swift"
find_copy "DataLocalSwiftDataUserDataSource.swift" "Sources/ArcanaData/Local/SwiftDataUserDataSource.swift"
find_copy "DataLocalEntitiesUserEntity.swift" "Sources/ArcanaData/Local/Entities/UserEntity.swift"
find_copy "DataLocalEntitiesAnalyticsEventEntity.swift" "Sources/ArcanaData/Local/Entities/AnalyticsEventEntity.swift"
find_copy "DataRemoteRemoteUserDataSource.swift" "Sources/ArcanaData/Remote/RemoteUserDataSource.swift"
find_copy "DataRemoteMockRemoteUserDataSource.swift" "Sources/ArcanaData/Remote/MockRemoteUserDataSource.swift"
find_copy "DataRepositoryUserRepository.swift" "Sources/ArcanaData/Repository/UserRepository.swift"
find_copy "DataRepositoryOfflineFirstUserRepository.swift" "Sources/ArcanaData/Repository/OfflineFirstUserRepository.swift"

# Presentation Module (6 files)
find_copy "PresentationScreensUserUserListView.swift" "Sources/ArcanaPresentation/Screens/User/UserListView.swift"
find_copy "PresentationScreensUserUserListViewModel.swift" "Sources/ArcanaPresentation/Screens/User/UserListViewModel.swift"
find_copy "PresentationScreensUserUserFormView.swift" "Sources/ArcanaPresentation/Screens/User/UserFormView.swift"
find_copy "PresentationScreensUserUserFormViewModel.swift" "Sources/ArcanaPresentation/Screens/User/UserFormViewModel.swift"
find_copy "PresentationComponentsUserCard.swift" "Sources/ArcanaPresentation/Components/UserCard.swift"
find_copy "PresentationThemeArcanaTheme.swift" "Sources/ArcanaPresentation/Theme/ArcanaTheme.swift"

# Tests (2 files)
find_copy "arcana-iosTestsUserValidatorTests.swift" "Tests/ArcanaDomainTests/UserValidatorTests.swift"
find_copy "arcana-iosTestsUserListViewModelTests.swift" "Tests/ArcanaPresentationTests/UserListViewModelTests.swift"

echo ""
echo "📊 File Count:"
find Sources -name "*.swift" 2>/dev/null | wc -l | xargs echo "  Sources:"
find Tests -name "*.swift" 2>/dev/null | wc -l | xargs echo "  Tests:"
echo ""

echo "🔨 Building package..."
echo ""
if swift package clean && swift package resolve && swift build 2>&1 | tail -20; then
    echo ""
    echo "========================================"
    echo "✅ SUCCESS! Build Complete!"
    echo "========================================"
    BUILD_OK=true
else
    echo ""
    echo "========================================"
    echo "⚠️  Check build output above"
    echo "========================================"
    BUILD_OK=false
fi

echo ""
echo "📁 Your SPM structure is now at:"
echo "   $PROJECT_ROOT/Sources/"
echo ""
echo "🎯 Next steps:"
echo "   cd $PROJECT_ROOT"
if [ "$BUILD_OK" = false ]; then
    echo "   swift package clean"
    echo "   swift package resolve"
fi
echo "   swift build"
echo "   open Package.swift"
echo ""
