# 📁 File Organization for Swift Package Manager

## 🎯 Current Issue

The files are currently in the root directory with flattened names (e.g., `PresentationScreensUserUserListViewModel.swift`). They need to be moved to the proper `Sources/` directory structure for Swift Package Manager to work.

## 🏗 Required Directory Structure

```
arcana-ios/
├── Package.swift                         # ✅ Already exists
│
├── Sources/                              # ⚠️ Need to create
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
│   │   │   ├── Entities/
│   │   │   │   ├── UserEntity.swift
│   │   │   │   └── AnalyticsEventEntity.swift
│   │   │   ├── LocalUserDataSource.swift
│   │   │   └── SwiftDataUserDataSource.swift
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
├── Tests/                                # ⚠️ Need to create
│   ├── ArcanaCoreTests/
│   ├── ArcanaDomainTests/
│   │   └── UserValidatorTests.swift
│   ├── ArcanaDataTests/
│   └── ArcanaPresentationTests/
│       └── UserListViewModelTests.swift
│
└── App/                                  # Your iOS app target
    ├── arcana_iosApp.swift
    └── ContentView.swift
```

## 🔄 File Mapping

### Current → New Location

#### Core Module
```
CoreAnalyticsAnalyticsEvent.swift           → Sources/ArcanaCore/Analytics/AnalyticsEvent.swift
CoreAnalyticsAnalyticsTracker.swift         → Sources/ArcanaCore/Analytics/AnalyticsTracker.swift
CoreAnalyticsPersistentAnalyticsTracker.swift → Sources/ArcanaCore/Analytics/PersistentAnalyticsTracker.swift
CoreCommonErrorCode.swift                   → Sources/ArcanaCore/Common/ErrorCode.swift
CoreCommonAppError.swift                    → Sources/ArcanaCore/Common/AppError.swift
CoreCommonLRUCache.swift                    → Sources/ArcanaCore/Common/LRUCache.swift
CoreCommonExtensions.swift                  → Sources/ArcanaCore/Common/Extensions.swift
CoreDIUserServiceDependency.swift           → Sources/ArcanaCore/DI/UserServiceDependency.swift
CoreDIAnalyticsTrackerDependency.swift      → Sources/ArcanaCore/DI/AnalyticsTrackerDependency.swift
CoreDIUserRepositoryDependency.swift        → Sources/ArcanaCore/DI/UserRepositoryDependency.swift
CoreDIAppDependencies.swift                 → Sources/ArcanaCore/DI/AppDependencies.swift
```

#### Domain Module
```
DomainModelUser.swift                       → Sources/ArcanaDomain/Model/User.swift
DomainServiceUserService.swift              → Sources/ArcanaDomain/Service/UserService.swift
DomainServiceUserServiceImpl.swift          → Sources/ArcanaDomain/Service/UserServiceImpl.swift
DomainValidationUserValidator.swift         → Sources/ArcanaDomain/Validation/UserValidator.swift
```

#### Data Module
```
DataLocalEntitiesUserEntity.swift           → Sources/ArcanaData/Local/Entities/UserEntity.swift
DataLocalEntitiesAnalyticsEventEntity.swift → Sources/ArcanaData/Local/Entities/AnalyticsEventEntity.swift
DataLocalLocalUserDataSource.swift          → Sources/ArcanaData/Local/LocalUserDataSource.swift
DataLocalSwiftDataUserDataSource.swift      → Sources/ArcanaData/Local/SwiftDataUserDataSource.swift
DataRemoteRemoteUserDataSource.swift        → Sources/ArcanaData/Remote/RemoteUserDataSource.swift
DataRemoteMockRemoteUserDataSource.swift    → Sources/ArcanaData/Remote/MockRemoteUserDataSource.swift
DataRepositoryUserRepository.swift          → Sources/ArcanaData/Repository/UserRepository.swift
DataRepositoryOfflineFirstUserRepository.swift → Sources/ArcanaData/Repository/OfflineFirstUserRepository.swift
```

#### Presentation Module
```
PresentationScreensUserUserListView.swift      → Sources/ArcanaPresentation/Screens/User/UserListView.swift
PresentationScreensUserUserListViewModel.swift → Sources/ArcanaPresentation/Screens/User/UserListViewModel.swift
PresentationScreensUserUserFormView.swift      → Sources/ArcanaPresentation/Screens/User/UserFormView.swift
PresentationScreensUserUserFormViewModel.swift → Sources/ArcanaPresentation/Screens/User/UserFormViewModel.swift
PresentationComponentsUserCard.swift           → Sources/ArcanaPresentation/Components/UserCard.swift
PresentationThemeArcanaTheme.swift             → Sources/ArcanaPresentation/Theme/ArcanaTheme.swift
```

#### Tests
```
arcana-iosTestsUserValidatorTests.swift        → Tests/ArcanaDomainTests/UserValidatorTests.swift
arcana-iosTestsUserListViewModelTests.swift    → Tests/ArcanaPresentationTests/UserListViewModelTests.swift
```

## 🚀 How to Reorganize

### Option 1: Automated Script (Recommended)

```bash
# Make the script executable
chmod +x reorganize_spm_structure.sh

# Run it
./reorganize_spm_structure.sh
```

### Option 2: Manual in Xcode

1. **Create Group Structure** in Xcode:
   - Right-click on project
   - New Group → `Sources`
   - Create subgroups: `ArcanaCore`, `ArcanaDomain`, `ArcanaData`, `ArcanaPresentation`
   - Create nested groups as shown in structure above

2. **Move Files**:
   - Drag files from root into appropriate groups
   - Xcode will update references

3. **Update on Disk**:
   - In Finder, move files to match the structure
   - Update `Package.swift` paths if needed

### Option 3: Manual Command Line

```bash
# Create directories
mkdir -p Sources/ArcanaCore/{Analytics,Common,DI}
mkdir -p Sources/ArcanaDomain/{Model,Service,Validation}
mkdir -p Sources/ArcanaData/{Local/Entities,Remote,Repository}
mkdir -p Sources/ArcanaPresentation/{Screens/User,Components,Theme}
mkdir -p Tests/{ArcanaCoreTests,ArcanaDomainTests,ArcanaDataTests,ArcanaPresentationTests}

# Move files (example for one file)
mv CoreCommonErrorCode.swift Sources/ArcanaCore/Common/ErrorCode.swift

# Repeat for all files...
```

## ✅ Verification

After reorganization, verify:

```bash
# 1. Check directory structure
tree Sources/

# 2. Build the package
swift build

# 3. Run tests
swift test

# 4. Open in Xcode
open Package.swift
```

Expected output:
```
✅ Build Succeeded
✅ All tests passed
```

## 🔧 Package.swift Paths

The `Package.swift` already has the correct paths:

```swift
.target(
    name: "ArcanaCore",
    dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
    ],
    path: "Sources/Core",  // ⚠️ Should be "Sources/ArcanaCore"
    // ...
)
```

**Update needed**: The paths in `Package.swift` should match the directory names:
- `path: "Sources/Core"` → `path: "Sources/ArcanaCore"`
- `path: "Sources/Domain"` → `path: "Sources/ArcanaDomain"`
- `path: "Sources/Data"` → `path: "Sources/ArcanaData"`
- `path: "Sources/Presentation"` → `path: "Sources/ArcanaPresentation"`

## 📊 Before vs After

### Before (Current - Flat Structure)
```
arcana-ios/
├── Package.swift
├── CoreCommonErrorCode.swift
├── CoreCommonAppError.swift
├── DomainModelUser.swift
├── PresentationScreensUserUserListViewModel.swift
└── ... (50+ files in root)
```

### After (SPM Structure)
```
arcana-ios/
├── Package.swift
├── Sources/
│   ├── ArcanaCore/
│   │   ├── Analytics/ (3 files)
│   │   ├── Common/ (4 files)
│   │   └── DI/ (4 files)
│   ├── ArcanaDomain/ (4 files)
│   ├── ArcanaData/ (9 files)
│   └── ArcanaPresentation/ (6 files)
└── Tests/
    └── ... (test files)
```

## 🎯 Why This Structure?

1. **SPM Requirement**: Swift Package Manager expects `Sources/` directory
2. **Module Isolation**: Each module in its own directory
3. **Clean Imports**: Enables `import ArcanaCore`, `import ArcanaDomain`, etc.
4. **Build Performance**: Parallel compilation of modules
5. **Better Organization**: Clear separation of concerns

## 🐛 Troubleshooting

### Issue: "No such module 'Dependencies'"

**Cause**: Files not in `Sources/` directory

**Solution**: Run reorganization script

### Issue: "Cannot find 'User' in scope"

**Cause**: Missing imports

**Solution**: Add proper imports:
```swift
import ArcanaDomain  // For User model
import ArcanaCore    // For analytics, errors
```

### Issue: Build fails after moving files

**Solution**: 
```bash
# Clean everything
swift package clean
rm -rf .build
rm -rf .swiftpm

# Rebuild
swift build
```

## 📚 Next Steps

After reorganization:

1. ✅ Verify build: `swift build`
2. ✅ Run tests: `swift test`
3. ✅ Update imports in app files
4. ✅ Commit changes
5. ✅ Open in Xcode: `open Package.swift`

## 💡 Pro Tip

Use the provided script for quick reorganization:

```bash
./reorganize_spm_structure.sh
```

It will:
- ✅ Create proper directory structure
- ✅ Move all files to correct locations
- ✅ Preserve file contents
- ✅ Verify the setup

---

**After reorganization, your project will be properly structured for Swift Package Manager! 🚀**
