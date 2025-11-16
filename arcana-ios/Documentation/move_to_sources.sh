#!/bin/bash

# Arcana iOS - Move files to SPM Sources structure
# This script moves all existing files to the proper SPM directory structure

set -e

echo "🚀 Moving files to SPM Sources structure..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Create directory structure
print_step "Creating SPM directory structure..."

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

mkdir -p Tests/ArcanaCoreTests
mkdir -p Tests/ArcanaDomainTests
mkdir -p Tests/ArcanaDataTests
mkdir -p Tests/ArcanaPresentationTests

print_success "Directory structure created"

# Function to move file if exists
move_file() {
    local src="$1"
    local dest="$2"
    
    if [ -f "$src" ]; then
        cp "$src" "$dest"
        print_success "Moved: $(basename $src)"
    else
        print_warning "Not found: $src"
    fi
}

print_step "Moving Core files..."

# Analytics
move_file "CoreAnalyticsAnalyticsEvent.swift" "Sources/ArcanaCore/Analytics/AnalyticsEvent.swift"
move_file "CoreAnalyticsAnalyticsTracker.swift" "Sources/ArcanaCore/Analytics/AnalyticsTracker.swift"
move_file "CoreAnalyticsPersistentAnalyticsTracker.swift" "Sources/ArcanaCore/Analytics/PersistentAnalyticsTracker.swift"

# Common
move_file "CoreCommonErrorCode.swift" "Sources/ArcanaCore/Common/ErrorCode.swift"
move_file "CoreCommonAppError.swift" "Sources/ArcanaCore/Common/AppError.swift"
move_file "CoreCommonLRUCache.swift" "Sources/ArcanaCore/Common/LRUCache.swift"
move_file "CoreCommonExtensions.swift" "Sources/ArcanaCore/Common/Extensions.swift"

# DI
move_file "CoreDIDIContainer.swift" "Sources/ArcanaCore/DI/DIContainer.swift"
move_file "CoreDIUserServiceDependency.swift" "Sources/ArcanaCore/DI/UserServiceDependency.swift"
move_file "CoreDIAnalyticsTrackerDependency.swift" "Sources/ArcanaCore/DI/AnalyticsTrackerDependency.swift"
move_file "CoreDIUserRepositoryDependency.swift" "Sources/ArcanaCore/DI/UserRepositoryDependency.swift"
move_file "CoreDIAppDependencies.swift" "Sources/ArcanaCore/DI/AppDependencies.swift"

print_step "Moving Domain files..."

# Models
move_file "DomainModelUser.swift" "Sources/ArcanaDomain/Model/User.swift"

# Services
move_file "DomainServiceUserService.swift" "Sources/ArcanaDomain/Service/UserService.swift"
move_file "DomainServiceUserServiceImpl.swift" "Sources/ArcanaDomain/Service/UserServiceImpl.swift"

# Validation
move_file "DomainValidationUserValidator.swift" "Sources/ArcanaDomain/Validation/UserValidator.swift"

print_step "Moving Data files..."

# Local
move_file "DataLocalLocalUserDataSource.swift" "Sources/ArcanaData/Local/LocalUserDataSource.swift"
move_file "DataLocalSwiftDataUserDataSource.swift" "Sources/ArcanaData/Local/SwiftDataUserDataSource.swift"

# Entities
move_file "DataLocalEntitiesUserEntity.swift" "Sources/ArcanaData/Local/Entities/UserEntity.swift"
move_file "DataLocalEntitiesAnalyticsEventEntity.swift" "Sources/ArcanaData/Local/Entities/AnalyticsEventEntity.swift"

# Remote
move_file "DataRemoteRemoteUserDataSource.swift" "Sources/ArcanaData/Remote/RemoteUserDataSource.swift"
move_file "DataRemoteMockRemoteUserDataSource.swift" "Sources/ArcanaData/Remote/MockRemoteUserDataSource.swift"

# Repository
move_file "DataRepositoryUserRepository.swift" "Sources/ArcanaData/Repository/UserRepository.swift"
move_file "DataRepositoryOfflineFirstUserRepository.swift" "Sources/ArcanaData/Repository/OfflineFirstUserRepository.swift"

print_step "Moving Presentation files..."

# Screens
move_file "PresentationScreensUserUserListView.swift" "Sources/ArcanaPresentation/Screens/User/UserListView.swift"
move_file "PresentationScreensUserUserListViewModel.swift" "Sources/ArcanaPresentation/Screens/User/UserListViewModel.swift"
move_file "PresentationScreensUserUserFormView.swift" "Sources/ArcanaPresentation/Screens/User/UserFormView.swift"
move_file "PresentationScreensUserUserFormViewModel.swift" "Sources/ArcanaPresentation/Screens/User/UserFormViewModel.swift"

# Components
move_file "PresentationComponentsUserCard.swift" "Sources/ArcanaPresentation/Components/UserCard.swift"

# Theme
move_file "PresentationThemeArcanaTheme.swift" "Sources/ArcanaPresentation/Theme/ArcanaTheme.swift"

print_step "Moving Test files..."

move_file "arcana-iosTestsUserValidatorTests.swift" "Tests/ArcanaDomainTests/UserValidatorTests.swift"
move_file "arcana-iosTestsUserListViewModelTests.swift" "Tests/ArcanaPresentationTests/UserListViewModelTests.swift"

print_success "All files moved to SPM structure"

print_step "Building package..."
swift build 2>&1 | head -20

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Migration Complete!${NC}"
echo "=========================================="
echo ""
echo "Files are now in:"
echo "  Sources/ArcanaCore/"
echo "  Sources/ArcanaDomain/"
echo "  Sources/ArcanaData/"
echo "  Sources/ArcanaPresentation/"
echo "  Tests/*Tests/"
echo ""
echo "Next steps:"
echo "  1. Run: swift build"
echo "  2. Run: swift test"
echo "  3. Update app imports to use modules"
echo ""
