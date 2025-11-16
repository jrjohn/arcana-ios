#!/bin/bash

# Arcana iOS - Swift Package Manager Migration Script
# This script helps migrate the existing project structure to SPM

set -e  # Exit on error

echo "🚀 Arcana iOS - SPM Migration Script"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Functions
print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if running in correct directory
if [ ! -f "Package.swift" ]; then
    print_error "Package.swift not found. Please run this script from the project root."
    exit 1
fi

print_step "Step 1: Creating directory structure..."

# Create Sources directories
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

# Create Tests directories
mkdir -p Tests/ArcanaCoreTests
mkdir -p Tests/ArcanaDomainTests
mkdir -p Tests/ArcanaDataTests
mkdir -p Tests/ArcanaPresentationTests

print_success "Directory structure created"

print_step "Step 2: Copying files to new structure..."

# Function to copy if exists
copy_if_exists() {
    if [ -f "$1" ]; then
        cp "$1" "$2"
        print_success "Copied $(basename $1)"
    else
        print_warning "File not found: $1"
    fi
}

# Copy Core files
copy_if_exists "Core/Analytics/AnalyticsEvent.swift" "Sources/ArcanaCore/Analytics/"
copy_if_exists "Core/Analytics/AnalyticsTracker.swift" "Sources/ArcanaCore/Analytics/"
copy_if_exists "Core/Analytics/PersistentAnalyticsTracker.swift" "Sources/ArcanaCore/Analytics/"

copy_if_exists "Core/Common/ErrorCode.swift" "Sources/ArcanaCore/Common/"
copy_if_exists "Core/Common/AppError.swift" "Sources/ArcanaCore/Common/"
copy_if_exists "Core/Common/LRUCache.swift" "Sources/ArcanaCore/Common/"
copy_if_exists "Core/Common/Extensions.swift" "Sources/ArcanaCore/Common/"

copy_if_exists "Core/DI/DIContainer.swift" "Sources/ArcanaCore/DI/"

# Copy Domain files
copy_if_exists "Domain/Model/User.swift" "Sources/ArcanaDomain/Model/"

copy_if_exists "Domain/Service/UserService.swift" "Sources/ArcanaDomain/Service/"
copy_if_exists "Domain/Service/UserServiceImpl.swift" "Sources/ArcanaDomain/Service/"

copy_if_exists "Domain/Validation/UserValidator.swift" "Sources/ArcanaDomain/Validation/"

# Copy Data files
copy_if_exists "Data/Local/Entities/UserEntity.swift" "Sources/ArcanaData/Local/Entities/"
copy_if_exists "Data/Local/Entities/AnalyticsEventEntity.swift" "Sources/ArcanaData/Local/Entities/"
copy_if_exists "Data/Local/LocalUserDataSource.swift" "Sources/ArcanaData/Local/"
copy_if_exists "Data/Local/SwiftDataUserDataSource.swift" "Sources/ArcanaData/Local/"

copy_if_exists "Data/Remote/RemoteUserDataSource.swift" "Sources/ArcanaData/Remote/"
copy_if_exists "Data/Remote/MockRemoteUserDataSource.swift" "Sources/ArcanaData/Remote/"

copy_if_exists "Data/Repository/UserRepository.swift" "Sources/ArcanaData/Repository/"
copy_if_exists "Data/Repository/OfflineFirstUserRepository.swift" "Sources/ArcanaData/Repository/"

# Copy Presentation files
copy_if_exists "Presentation/Screens/User/UserListView.swift" "Sources/ArcanaPresentation/Screens/User/"
copy_if_exists "Presentation/Screens/User/UserListViewModel.swift" "Sources/ArcanaPresentation/Screens/User/"
copy_if_exists "Presentation/Screens/User/UserFormView.swift" "Sources/ArcanaPresentation/Screens/User/"
copy_if_exists "Presentation/Screens/User/UserFormViewModel.swift" "Sources/ArcanaPresentation/Screens/User/"

copy_if_exists "Presentation/Components/UserCard.swift" "Sources/ArcanaPresentation/Components/"

copy_if_exists "Presentation/Theme/ArcanaTheme.swift" "Sources/ArcanaPresentation/Theme/"

# Copy Test files
copy_if_exists "arcana-iosTests/UserValidatorTests.swift" "Tests/ArcanaDomainTests/"
copy_if_exists "arcana-iosTests/UserListViewModelTests.swift" "Tests/ArcanaPresentationTests/"

print_success "Files copied to new structure"

print_step "Step 3: Resolving package dependencies..."

swift package resolve

print_success "Dependencies resolved"

print_step "Step 4: Building package..."

swift build

print_success "Package built successfully"

print_step "Step 5: Running tests..."

swift test

print_success "Tests passed"

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Migration Complete!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Open Package.swift in Xcode"
echo "2. Update your app target to import the modules:"
echo "   - import ArcanaCore"
echo "   - import ArcanaDomain"
echo "   - import ArcanaData"
echo "   - import ArcanaPresentation"
echo "3. Build and run your app (⌘R)"
echo ""
echo "Useful commands:"
echo "  make build       - Build all modules"
echo "  make test        - Run all tests"
echo "  make clean       - Clean build artifacts"
echo "  make ci          - Run full CI pipeline"
echo ""
echo "Documentation:"
echo "  SPM_SETUP_GUIDE.md  - Detailed setup guide"
echo "  SPM_README.md       - Quick reference"
echo ""
print_success "Happy coding! 🚀"
