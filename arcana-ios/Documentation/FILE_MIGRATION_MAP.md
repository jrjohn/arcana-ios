# File Migration Map - Old Structure to SPM Sources

## Overview
This document shows the exact mapping from the current file structure to the new SPM `Sources/` structure.

## Core Module (ArcanaCore)

### Analytics
```
CoreAnalyticsAnalyticsEvent.swift 
  → Sources/ArcanaCore/Analytics/AnalyticsEvent.swift

CoreAnalyticsAnalyticsTracker.swift
  → Sources/ArcanaCore/Analytics/AnalyticsTracker.swift

CoreAnalyticsPersistentAnalyticsTracker.swift
  → Sources/ArcanaCore/Analytics/PersistentAnalyticsTracker.swift
```

### Common
```
CoreCommonErrorCode.swift
  → Sources/ArcanaCore/Common/ErrorCode.swift

CoreCommonAppError.swift
  → Sources/ArcanaCore/Common/AppError.swift

CoreCommonLRUCache.swift
  → Sources/ArcanaCore/Common/LRUCache.swift

CoreCommonExtensions.swift
  → Sources/ArcanaCore/Common/Extensions.swift
```

### DI (Dependency Injection)
```
CoreDIDIContainer.swift
  → Sources/ArcanaCore/DI/DIContainer.swift

CoreDIUserServiceDependency.swift
  → Sources/ArcanaCore/DI/UserServiceDependency.swift

CoreDIAnalyticsTrackerDependency.swift
  → Sources/ArcanaCore/DI/AnalyticsTrackerDependency.swift

CoreDIUserRepositoryDependency.swift
  → Sources/ArcanaCore/DI/UserRepositoryDependency.swift

CoreDIAppDependencies.swift
  → Sources/ArcanaCore/DI/AppDependencies.swift
```

## Domain Module (ArcanaDomain)

### Model
```
DomainModelUser.swift
  → Sources/ArcanaDomain/Model/User.swift
```

### Service
```
DomainServiceUserService.swift
  → Sources/ArcanaDomain/Service/UserService.swift

DomainServiceUserServiceImpl.swift
  → Sources/ArcanaDomain/Service/UserServiceImpl.swift
```

### Validation
```
DomainValidationUserValidator.swift
  → Sources/ArcanaDomain/Validation/UserValidator.swift
```

## Data Module (ArcanaData)

### Local
```
DataLocalLocalUserDataSource.swift
  → Sources/ArcanaData/Local/LocalUserDataSource.swift

DataLocalSwiftDataUserDataSource.swift
  → Sources/ArcanaData/Local/SwiftDataUserDataSource.swift
```

### Entities
```
DataLocalEntitiesUserEntity.swift
  → Sources/ArcanaData/Local/Entities/UserEntity.swift

DataLocalEntitiesAnalyticsEventEntity.swift
  → Sources/ArcanaData/Local/Entities/AnalyticsEventEntity.swift
```

### Remote
```
DataRemoteRemoteUserDataSource.swift
  → Sources/ArcanaData/Remote/RemoteUserDataSource.swift

DataRemoteMockRemoteUserDataSource.swift
  → Sources/ArcanaData/Remote/MockRemoteUserDataSource.swift
```

### Repository
```
DataRepositoryUserRepository.swift
  → Sources/ArcanaData/Repository/UserRepository.swift

DataRepositoryOfflineFirstUserRepository.swift
  → Sources/ArcanaData/Repository/OfflineFirstUserRepository.swift
```

## Presentation Module (ArcanaPresentation)

### Screens - User
```
PresentationScreensUserUserListView.swift
  → Sources/ArcanaPresentation/Screens/User/UserListView.swift

PresentationScreensUserUserListViewModel.swift
  → Sources/ArcanaPresentation/Screens/User/UserListViewModel.swift

PresentationScreensUserUserFormView.swift
  → Sources/ArcanaPresentation/Screens/User/UserFormView.swift

PresentationScreensUserUserFormViewModel.swift
  → Sources/ArcanaPresentation/Screens/User/UserFormViewModel.swift
```

### Components
```
PresentationComponentsUserCard.swift
  → Sources/ArcanaPresentation/Components/UserCard.swift
```

### Theme
```
PresentationThemeArcanaTheme.swift
  → Sources/ArcanaPresentation/Theme/ArcanaTheme.swift
```

## Tests

### Domain Tests
```
arcana-iosTestsUserValidatorTests.swift
  → Tests/ArcanaDomainTests/UserValidatorTests.swift
```

### Presentation Tests
```
arcana-iosTestsUserListViewModelTests.swift
  → Tests/ArcanaPresentationTests/UserListViewModelTests.swift
```

## App Files (Stay in Root)

These files remain in the app target, not in the package:
```
arcana_iosApp.swift           → App/arcana_iosApp.swift (or keep in root)
ContentView.swift             → App/ContentView.swift (or keep in root)
Item.swift                    → Can be deleted (not needed)
```

## Directory Structure After Migration

```
arcana-ios/
├── Package.swift
├── Makefile
│
├── Sources/
│   ├── ArcanaCore/
│   │   ├── Analytics/
│   │   │   ├── AnalyticsEvent.swift
│   │   │   ├── AnalyticsTracker.swift
│   │   │   └── PersistentAnalyticsTracker.swift
│   │   ├── Common/
│   │   │   ├── ErrorCode.swift
│   │   │   ├── AppError.swift
│   │   │   ├── LRUCache.swift
│   │   │   └── Extensions.swift
│   │   └── DI/
│   │       ├── DIContainer.swift
│   │       ├── UserServiceDependency.swift
│   │       ├── AnalyticsTrackerDependency.swift
│   │       ├── UserRepositoryDependency.swift
│   │       └── AppDependencies.swift
│   │
│   ├── ArcanaDomain/
│   │   ├── Model/
│   │   │   └── User.swift
│   │   ├── Service/
│   │   │   ├── UserService.swift
│   │   │   └── UserServiceImpl.swift
│   │   └── Validation/
│   │       └── UserValidator.swift
│   │
│   ├── ArcanaData/
│   │   ├── Local/
│   │   │   ├── LocalUserDataSource.swift
│   │   │   ├── SwiftDataUserDataSource.swift
│   │   │   └── Entities/
│   │   │       ├── UserEntity.swift
│   │   │       └── AnalyticsEventEntity.swift
│   │   ├── Remote/
│   │   │   ├── RemoteUserDataSource.swift
│   │   │   └── MockRemoteUserDataSource.swift
│   │   └── Repository/
│   │       ├── UserRepository.swift
│   │       └── OfflineFirstUserRepository.swift
│   │
│   └── ArcanaPresentation/
│       ├── Screens/
│       │   └── User/
│       │       ├── UserListView.swift
│       │       ├── UserListViewModel.swift
│       │       ├── UserFormView.swift
│       │       └── UserFormViewModel.swift
│       ├── Components/
│       │   └── UserCard.swift
│       └── Theme/
│           └── ArcanaTheme.swift
│
├── Tests/
│   ├── ArcanaCoreTests/
│   ├── ArcanaDomainTests/
│   │   └── UserValidatorTests.swift
│   ├── ArcanaDataTests/
│   └── ArcanaPresentationTests/
│       └── UserListViewModelTests.swift
│
└── App/ (or root for Xcode project)
    ├── arcana_iosApp.swift
    └── ContentView.swift
```

## Migration Steps

1. **Create directory structure:**
   ```bash
   mkdir -p Sources/ArcanaCore/{Analytics,Common,DI}
   mkdir -p Sources/ArcanaDomain/{Model,Service,Validation}
   mkdir -p Sources/ArcanaData/{Local/Entities,Remote,Repository}
   mkdir -p Sources/ArcanaPresentation/{Screens/User,Components,Theme}
   mkdir -p Tests/{ArcanaCoreTests,ArcanaDomainTests,ArcanaDataTests,ArcanaPresentationTests}
   ```

2. **Copy files to new locations:**
   Use the mapping above to copy each file to its new location.

3. **Update imports in app files:**
   ```swift
   import ArcanaCore
   import ArcanaDomain
   import ArcanaData
   import ArcanaPresentation
   ```

4. **Build and test:**
   ```bash
   swift build
   swift test
   ```

## Module Dependencies

```
ArcanaPresentation
    ├─ depends on → ArcanaData
    ├─ depends on → ArcanaDomain
    └─ depends on → ArcanaCore

ArcanaData
    ├─ depends on → ArcanaDomain
    └─ depends on → ArcanaCore

ArcanaDomain
    └─ depends on → ArcanaCore

ArcanaCore
    └─ depends on → Dependencies (swift-dependencies package)
```

## Import Statements

After migration, use these imports:

**In ArcanaCore files:**
```swift
import Foundation
import Dependencies  // For DI files only
```

**In ArcanaDomain files:**
```swift
import Foundation
import ArcanaCore
```

**In ArcanaData files:**
```swift
import Foundation
import SwiftData  // For entities and data sources
import ArcanaCore
import ArcanaDomain
```

**In ArcanaPresentation files:**
```swift
import SwiftUI
import Combine
import Dependencies  // For ViewModels using @Dependency
import ArcanaCore
import ArcanaDomain
import ArcanaData
```

**In App files:**
```swift
import SwiftUI
import SwiftData
import ArcanaCore
import ArcanaPresentation
```

## Verification Checklist

- [ ] All files moved to `Sources/` directory
- [ ] Test files moved to `Tests/` directory
- [ ] Directory structure matches SPM conventions
- [ ] No files remaining in old structure
- [ ] `swift build` completes successfully
- [ ] `swift test` runs successfully
- [ ] App builds in Xcode
- [ ] Imports are correct in all files

## Notes

- The `Dependencies` import is only needed in files using `@Dependency` property wrappers
- SwiftData imports are only needed in data layer files
- Each module can only import its dependencies (see dependency graph above)
- Test files get automatic access to `@testable import`
