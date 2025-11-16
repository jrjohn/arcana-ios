# Arcana iOS Project Reorganization Guide

## 📋 Overview

This guide documents the reorganization of the Arcana iOS project into a proper Swift Package Manager (SPM) structure following Clean Architecture principles.

## 🏗 New Structure

```
arcana-ios/
├── Package.swift                          # SPM package definition (at root level)
├── arcana-ios/
│   ├── arcana_iosApp.swift               # App entry point
│   ├── Assets.xcassets/                  # Asset catalog
│   │
│   ├── Sources/                          # All source code (modular)
│   │   ├── ArcanaCore/                   # Core module (no dependencies)
│   │   │   ├── Analytics/
│   │   │   │   ├── AnalyticsEvent.swift
│   │   │   │   ├── AnalyticsTracker.swift
│   │   │   │   └── PersistentAnalyticsTracker.swift
│   │   │   ├── Common/
│   │   │   │   ├── ErrorCode.swift
│   │   │   │   ├── AppError.swift
│   │   │   │   ├── Extensions.swift
│   │   │   │   └── LRUCache.swift
│   │   │   └── DI/
│   │   │       ├── DIContainer.swift
│   │   │       └── AppDependencies.swift
│   │   │
│   │   ├── ArcanaDomain/                 # Domain module (depends on: Core)
│   │   │   ├── Model/
│   │   │   │   └── User.swift
│   │   │   ├── Service/
│   │   │   │   ├── UserService.swift
│   │   │   │   └── UserServiceImpl.swift
│   │   │   └── Validation/
│   │   │       └── UserValidator.swift
│   │   │
│   │   ├── ArcanaData/                   # Data module (depends on: Core, Domain)
│   │   │   ├── Local/
│   │   │   │   ├── Entities/
│   │   │   │   │   ├── UserEntity.swift
│   │   │   │   │   └── AnalyticsEventEntity.swift
│   │   │   │   ├── LocalUserDataSource.swift
│   │   │   │   └── SwiftDataUserDataSource.swift
│   │   │   ├── Remote/
│   │   │   │   ├── RemoteUserDataSource.swift
│   │   │   │   └── MockRemoteUserDataSource.swift
│   │   │   └── Repository/
│   │   │       ├── UserRepository.swift
│   │   │       └── OfflineFirstUserRepository.swift
│   │   │
│   │   └── ArcanaPresentation/           # Presentation module (depends on: Core, Domain, Data)
│   │       ├── Screens/
│   │       │   └── User/
│   │       │       ├── UserListView.swift
│   │       │       ├── UserListViewModel.swift
│   │       │       ├── UserFormView.swift
│   │       │       └── UserFormViewModel.swift
│   │       ├── Components/
│   │       │   └── UserCard.swift
│   │       └── Theme/
│   │           └── ArcanaTheme.swift
│   │
│   ├── Tests/                            # All unit tests
│   │   ├── ArcanaDomainTests/
│   │   │   └── UserValidatorTests.swift
│   │   ├── ArcanaPresentationTests/
│   │   │   └── UserListViewModelTests.swift
│   │   └── ArcanaDataTests/
│   │       └── (future data layer tests)
│   │
│   └── Documentation/                    # Documentation and helper scripts
│       ├── README.md
│       ├── IMPLEMENTATION_GUIDE.md
│       └── (other .md files and scripts)
│
├── arcana-iosTests/                      # Xcode test target
└── arcana-iosUITests/                    # Xcode UI test target
```

## 🔄 What Changed

### Before
- All Swift files were in a flat structure at `arcana-ios/` root
- Difficult to understand dependencies
- No clear separation of concerns
- Hard to test individual modules

### After
- Clean modular structure with 4 main modules
- Clear dependency hierarchy: Core ← Domain ← Data ← Presentation
- Each module is independently buildable and testable
- Follows Swift Package Manager conventions

## 📦 Module Dependencies

```
┌─────────────────────┐
│  ArcanaPresentation │  (UI Layer)
└──────────┬──────────┘
           │ depends on
           ↓
┌─────────────────────┐
│     ArcanaData      │  (Data Layer)
└──────────┬──────────┘
           │ depends on
           ↓
┌─────────────────────┐
│    ArcanaDomain     │  (Business Logic)
└──────────┬──────────┘
           │ depends on
           ↓
┌─────────────────────┐
│     ArcanaCore      │  (Foundation)
└─────────────────────┘
```

### Module Descriptions

#### ArcanaCore
**Purpose**: Foundation layer with zero dependencies
**Contains**:
- Analytics tracking system
- Error handling (ErrorCode, AppError)
- Utilities (LRUCache, Extensions)
- Dependency Injection container

#### ArcanaDomain
**Purpose**: Business logic and domain models
**Contains**:
- Domain models (User, etc.)
- Service protocols and implementations
- Validation logic
**Dependencies**: ArcanaCore

#### ArcanaData
**Purpose**: Data access and persistence
**Contains**:
- Repository implementations (offline-first)
- Local data sources (Core Data/SwiftData)
- Remote data sources (API clients)
- Data entities
**Dependencies**: ArcanaCore, ArcanaDomain

#### ArcanaPresentation
**Purpose**: UI and presentation logic
**Contains**:
- SwiftUI views
- ViewModels (MVVM pattern with Input/Output)
- UI components
- Theme and styling
**Dependencies**: ArcanaCore, ArcanaDomain, ArcanaData

## 🚀 Running the Reorganization

### Option 1: Automatic (Recommended)

```bash
cd /Users/jrjohn/Documents/projects/arcana-ios
./reorganize_project.sh
```

This script will:
1. Remove duplicate root-level Swift files
2. Move test files to proper locations
3. Organize documentation
4. Clean up obsolete files

### Option 2: Manual

If you prefer to reorganize manually:

1. **Keep** all files in `Sources/` directories
2. **Delete** all duplicate `*Swift` files from `arcana-ios/` root:
   - `Core*` files → already in `Sources/ArcanaCore`
   - `Domain*` files → already in `Sources/ArcanaDomain`
   - `Data*` files → already in `Sources/ArcanaData`
   - `Presentation*` files → already in `Sources/ArcanaPresentation`

3. **Move** test files:
   - `arcana-iosTestsUserValidatorTests.swift` → `Tests/ArcanaDomainTests/UserValidatorTests.swift`
   - `arcana-iosTestsUserListViewModelTests.swift` → `Tests/ArcanaPresentationTests/UserListViewModelTests.swift`

4. **Move** documentation files to `Documentation/` folder

## ✅ Verification Steps

After reorganization:

### 1. Check Structure
```bash
cd arcana-ios
tree -L 3 Sources/
tree -L 2 Tests/
```

### 2. Build in Xcode
1. Open `arcana-ios.xcodeproj`
2. Press `Cmd+B` to build
3. Fix any file reference issues in Xcode if needed

### 3. Run Tests
```bash
# In Xcode: Cmd+U
# Or via command line:
xcodebuild test -scheme arcana-ios -destination 'platform=iOS Simulator,name=iPhone 15'
```

### 4. Verify Module Boundaries
Each module should only import its declared dependencies:

```swift
// ✅ CORRECT
// In ArcanaData file:
import ArcanaCore
import ArcanaDomain

// ❌ INCORRECT
// In ArcanaDomain file:
import ArcanaData  // Domain shouldn't depend on Data!
```

## 🎯 Benefits of New Structure

### 1. **Clear Dependencies**
- Easy to see what depends on what
- Prevents circular dependencies
- Enforces architectural boundaries

### 2. **Better Testability**
- Test each module independently
- Mock dependencies easily
- Faster test execution

### 3. **Scalability**
- Add new features without touching existing code
- Multiple developers can work on different modules
- Easier code review

### 4. **Reusability**
- Core module can be shared across projects
- Domain logic independent of UI
- Data layer can be swapped (e.g., different API)

### 5. **SPM Ready**
- Can publish modules as separate packages
- Better integration with other SPM packages
- Xcode builds are faster with modular structure

## 🔧 Updating Xcode Project

If Xcode shows missing file errors:

### Method 1: Re-add Source Folders
1. In Xcode, select `arcana-ios` target
2. Right-click → "Add Files to arcana-ios"
3. Select `Sources/` folder
4. Check "Create folder references"
5. Click "Add"

### Method 2: Clean and Rebuild
```bash
# In Xcode:
# Product → Clean Build Folder (Cmd+Shift+K)
# Product → Build (Cmd+B)
```

### Method 3: Update File References
1. In Project Navigator, select files showing in red
2. In File Inspector (right panel), click folder icon
3. Navigate to correct location in `Sources/`
4. Click "Choose"

## 📝 Import Statements

After reorganization, use these import patterns:

```swift
// arcana_iosApp.swift (main app file)
import SwiftUI
import ArcanaCore
import ArcanaDomain
import ArcanaData
import ArcanaPresentation

// In ArcanaPresentation files
import SwiftUI
import ArcanaCore
import ArcanaDomain
import ArcanaData

// In ArcanaData files
import Foundation
import ArcanaCore
import ArcanaDomain

// In ArcanaDomain files
import Foundation
import ArcanaCore

// In ArcanaCore files
import Foundation
// (no other module imports)
```

## 🐛 Common Issues & Solutions

### Issue: "No such module 'ArcanaCore'"
**Solution**: Ensure `Package.swift` is at the project root and build the project

### Issue: Files show in red in Xcode
**Solution**: Update file references (see "Updating Xcode Project" above)

### Issue: Tests not finding classes
**Solution**: Ensure test targets have proper dependencies in `Package.swift`

### Issue: Circular dependency error
**Solution**: Check imports - higher layers shouldn't import lower layers

## 🎓 Clean Architecture Principles

This structure follows Uncle Bob's Clean Architecture:

1. **Independence**: Each layer is independent
2. **Testability**: Business rules can be tested without UI/DB
3. **Flexibility**: UI and databases are details, easily swappable
4. **Dependency Rule**: Dependencies point inward (toward domain)

## 📚 Additional Resources

- [Swift Package Manager Guide](https://swift.org/package-manager/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [iOS Clean Architecture](https://tech.olx.com/clean-architecture-and-mvvm-on-ios-c9d167d9f5b3)

## 🎉 Conclusion

Your project is now organized following industry best practices! The modular structure will make development, testing, and maintenance much easier as the project grows.

Happy coding! 🚀
