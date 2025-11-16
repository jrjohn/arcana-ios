#!/bin/bash

# Simple Direct Fix - No fancy checks, just do it!

echo "🔧 Direct SPM Structure Fix"
echo "=========================="
echo ""
echo "📁 Current directory: $(pwd)"
echo ""

# Create directories (will succeed even if they exist)
echo "📁 Creating directories..."
mkdir -p Sources/ArcanaCore/Analytics Sources/ArcanaCore/Common Sources/ArcanaCore/DI
mkdir -p Sources/ArcanaDomain/Model Sources/ArcanaDomain/Service Sources/ArcanaDomain/Validation
mkdir -p Sources/ArcanaData/Local/Entities Sources/ArcanaData/Remote Sources/ArcanaData/Repository
mkdir -p Sources/ArcanaPresentation/Screens/User Sources/ArcanaPresentation/Components Sources/ArcanaPresentation/Theme
mkdir -p Tests/ArcanaDomainTests Tests/ArcanaPresentationTests
echo "✅ Done"
echo ""

# Copy function
copy_if_exists() {
    if [ -f "$1" ]; then
        cp "$1" "$2" && echo "  ✓ $1"
    fi
}

echo "📦 Copying files..."

# Core
copy_if_exists "CoreAnalyticsAnalyticsEvent.swift" "Sources/ArcanaCore/Analytics/AnalyticsEvent.swift"
copy_if_exists "CoreAnalyticsAnalyticsTracker.swift" "Sources/ArcanaCore/Analytics/AnalyticsTracker.swift"
copy_if_exists "CoreAnalyticsPersistentAnalyticsTracker.swift" "Sources/ArcanaCore/Analytics/PersistentAnalyticsTracker.swift"
copy_if_exists "CoreCommonErrorCode.swift" "Sources/ArcanaCore/Common/ErrorCode.swift"
copy_if_exists "CoreCommonAppError.swift" "Sources/ArcanaCore/Common/AppError.swift"
copy_if_exists "CoreCommonLRUCache.swift" "Sources/ArcanaCore/Common/LRUCache.swift"
copy_if_exists "CoreCommonExtensions.swift" "Sources/ArcanaCore/Common/Extensions.swift"
copy_if_exists "CoreDIDIContainer.swift" "Sources/ArcanaCore/DI/DIContainer.swift"
copy_if_exists "CoreDIUserServiceDependency.swift" "Sources/ArcanaCore/DI/UserServiceDependency.swift"
copy_if_exists "CoreDIAnalyticsTrackerDependency.swift" "Sources/ArcanaCore/DI/AnalyticsTrackerDependency.swift"
copy_if_exists "CoreDIUserRepositoryDependency.swift" "Sources/ArcanaCore/DI/UserRepositoryDependency.swift"
copy_if_exists "CoreDIAppDependencies.swift" "Sources/ArcanaCore/DI/AppDependencies.swift"

# Domain
copy_if_exists "DomainModelUser.swift" "Sources/ArcanaDomain/Model/User.swift"
copy_if_exists "DomainServiceUserService.swift" "Sources/ArcanaDomain/Service/UserService.swift"
copy_if_exists "DomainServiceUserServiceImpl.swift" "Sources/ArcanaDomain/Service/UserServiceImpl.swift"
copy_if_exists "DomainValidationUserValidator.swift" "Sources/ArcanaDomain/Validation/UserValidator.swift"

# Data
copy_if_exists "DataLocalLocalUserDataSource.swift" "Sources/ArcanaData/Local/LocalUserDataSource.swift"
copy_if_exists "DataLocalSwiftDataUserDataSource.swift" "Sources/ArcanaData/Local/SwiftDataUserDataSource.swift"
copy_if_exists "DataLocalEntitiesUserEntity.swift" "Sources/ArcanaData/Local/Entities/UserEntity.swift"
copy_if_exists "DataLocalEntitiesAnalyticsEventEntity.swift" "Sources/ArcanaData/Local/Entities/AnalyticsEventEntity.swift"
copy_if_exists "DataRemoteRemoteUserDataSource.swift" "Sources/ArcanaData/Remote/RemoteUserDataSource.swift"
copy_if_exists "DataRemoteMockRemoteUserDataSource.swift" "Sources/ArcanaData/Remote/MockRemoteUserDataSource.swift"
copy_if_exists "DataRepositoryUserRepository.swift" "Sources/ArcanaData/Repository/UserRepository.swift"
copy_if_exists "DataRepositoryOfflineFirstUserRepository.swift" "Sources/ArcanaData/Repository/OfflineFirstUserRepository.swift"

# Presentation
copy_if_exists "PresentationScreensUserUserListView.swift" "Sources/ArcanaPresentation/Screens/User/UserListView.swift"
copy_if_exists "PresentationScreensUserUserListViewModel.swift" "Sources/ArcanaPresentation/Screens/User/UserListViewModel.swift"
copy_if_exists "PresentationScreensUserUserFormView.swift" "Sources/ArcanaPresentation/Screens/User/UserFormView.swift"
copy_if_exists "PresentationScreensUserUserFormViewModel.swift" "Sources/ArcanaPresentation/Screens/User/UserFormViewModel.swift"
copy_if_exists "PresentationComponentsUserCard.swift" "Sources/ArcanaPresentation/Components/UserCard.swift"
copy_if_exists "PresentationThemeArcanaTheme.swift" "Sources/ArcanaPresentation/Theme/ArcanaTheme.swift"

# Tests
copy_if_exists "arcana-iosTestsUserValidatorTests.swift" "Tests/ArcanaDomainTests/UserValidatorTests.swift"
copy_if_exists "arcana-iosTestsUserListViewModelTests.swift" "Tests/ArcanaPresentationTests/UserListViewModelTests.swift"

echo ""
echo "📊 Counting files..."
find Sources -name "*.swift" 2>/dev/null | wc -l | xargs echo "  Total in Sources:"
echo ""

echo "🔨 Building..."
swift build 2>&1 | head -40

echo ""
echo "========================================"
echo "✅ Done!"
echo "========================================"
echo ""
echo "Run: swift build"
echo ""
