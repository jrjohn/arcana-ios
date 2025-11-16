#!/bin/bash

# Arcana iOS - Reorganize Files for SPM Structure
# This script moves all files to the correct Sources/ directory

set -e

echo "🔄 Reorganizing files for Swift Package Manager structure..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Create the Sources directory structure
print_step "Creating Sources directory structure..."

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

# Create Tests directory structure
mkdir -p Tests/ArcanaCoreTests
mkdir -p Tests/ArcanaDomainTests
mkdir -p Tests/ArcanaDataTests
mkdir -p Tests/ArcanaPresentationTests

print_success "Directory structure created"

# Function to move file if it exists
move_if_exists() {
    local src=$1
    local dst=$2
    
    if [ -f "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        mv "$src" "$dst"
        print_success "Moved $(basename $src)"
    fi
}

print_step "Moving Core files..."

# Core - Analytics
move_if_exists "CoreAnalyticsAnalyticsEvent.swift" "Sources/ArcanaCore/Analytics/AnalyticsEvent.swift"
move_if_exists "CoreAnalyticsAnalyticsTracker.swift" "Sources/ArcanaCore/Analytics/AnalyticsTracker.swift"
move_if_exists "CoreAnalyticsPersistentAnalyticsTracker.swift" "Sources/ArcanaCore/Analytics/PersistentAnalyticsTracker.swift"

# Core - Common
move_if_exists "CoreCommonErrorCode.swift" "Sources/ArcanaCore/Common/ErrorCode.swift"
move_if_exists "CoreCommonAppError.swift" "Sources/ArcanaCore/Common/AppError.swift"
move_if_exists "CoreCommonLRUCache.swift" "Sources/ArcanaCore/Common/LRUCache.swift"
move_if_exists "CoreCommonExtensions.swift" "Sources/ArcanaCore/Common/Extensions.swift"

# Core - DI
move_if_exists "CoreDIDIContainer.swift" "Sources/ArcanaCore/DI/DIContainer.swift"
move_if_exists "CoreDIUserServiceDependency.swift" "Sources/ArcanaCore/DI/UserServiceDependency.swift"
move_if_exists "CoreDIAnalyticsTrackerDependency.swift" "Sources/ArcanaCore/DI/AnalyticsTrackerDependency.swift"
move_if_exists "CoreDIUserRepositoryDependency.swift" "Sources/ArcanaCore/DI/UserRepositoryDependency.swift"
move_if_exists "CoreDIAppDependencies.swift" "Sources/ArcanaCore/DI/AppDependencies.swift"

print_step "Moving Domain files..."

# Domain - Model
move_if_exists "DomainModelUser.swift" "Sources/ArcanaDomain/Model/User.swift"

# Domain - Service
move_if_exists "DomainServiceUserService.swift" "Sources/ArcanaDomain/Service/UserService.swift"
move_if_exists "DomainServiceUserServiceImpl.swift" "Sources/ArcanaDomain/Service/UserServiceImpl.swift"

# Domain - Validation
move_if_exists "DomainValidationUserValidator.swift" "Sources/ArcanaDomain/Validation/UserValidator.swift"

print_step "Moving Data files..."

# Data - Local Entities
move_if_exists "DataLocalEntitiesUserEntity.swift" "Sources/ArcanaData/Local/Entities/UserEntity.swift"
move_if_exists "DataLocalEntitiesAnalyticsEventEntity.swift" "Sources/ArcanaData/Local/Entities/AnalyticsEventEntity.swift"

# Data - Local
move_if_exists "DataLocalLocalUserDataSource.swift" "Sources/ArcanaData/Local/LocalUserDataSource.swift"
move_if_exists "DataLocalSwiftDataUserDataSource.swift" "Sources/ArcanaData/Local/SwiftDataUserDataSource.swift"

# Data - Remote
move_if_exists "DataRemoteRemoteUserDataSource.swift" "Sources/ArcanaData/Remote/RemoteUserDataSource.swift"
move_if_exists "DataRemoteMockRemoteUserDataSource.swift" "Sources/ArcanaData/Remote/MockRemoteUserDataSource.swift"

# Data - Repository
move_if_exists "DataRepositoryUserRepository.swift" "Sources/ArcanaData/Repository/UserRepository.swift"
move_if_exists "DataRepositoryOfflineFirstUserRepository.swift" "Sources/ArcanaData/Repository/OfflineFirstUserRepository.swift"

print_step "Moving Presentation files..."

# Presentation - Screens
move_if_exists "PresentationScreensUserUserListView.swift" "Sources/ArcanaPresentation/Screens/User/UserListView.swift"
move_if_exists "PresentationScreensUserUserListViewModel.swift" "Sources/ArcanaPresentation/Screens/User/UserListViewModel.swift"
move_if_exists "PresentationScreensUserUserFormView.swift" "Sources/ArcanaPresentation/Screens/User/UserFormView.swift"
move_if_exists "PresentationScreensUserUserFormViewModel.swift" "Sources/ArcanaPresentation/Screens/User/UserFormViewModel.swift"

# Presentation - Components
move_if_exists "PresentationComponentsUserCard.swift" "Sources/ArcanaPresentation/Components/UserCard.swift"

# Presentation - Theme
move_if_exists "PresentationThemeArcanaTheme.swift" "Sources/ArcanaPresentation/Theme/ArcanaTheme.swift"

print_step "Moving Test files..."

# Tests
move_if_exists "arcana-iosTestsUserValidatorTests.swift" "Tests/ArcanaDomainTests/UserValidatorTests.swift"
move_if_exists "arcana-iosTestsUserListViewModelTests.swift" "Tests/ArcanaPresentationTests/UserListViewModelTests.swift"

print_success "All files moved to Sources/ structure!"

echo ""
echo "📦 Files are now organized for Swift Package Manager"
echo ""
echo "Next steps:"
echo "1. Run: swift build"
echo "2. Run: swift test"
echo "3. Open Package.swift in Xcode"
echo ""

print_success "Reorganization complete! 🎉"
