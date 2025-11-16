# 🚀 Complete Migration Guide - Move to SPM Sources

## Current Situation

You have all your source files in the root directory with prefixed names like:
- `CoreCommonErrorCode.swift`
- `DomainModelUser.swift`
- `PresentationScreensUserUserListViewModel.swift`

These need to be moved to the SPM `Sources/` directory structure.

## ⚠️ The Error

```
error: No such module 'Dependencies'
```

This happens because:
1. Files are not in the `Sources/` directory where SPM expects them
2. The swift-dependencies package isn't being linked properly

## ✅ Solution: Complete Migration Steps

### Step 1: Run the Migration Script

```bash
# Make script executable
chmod +x move_to_sources.sh

# Run the migration
./move_to_sources.sh
```

This will:
- Create all necessary directories
- Copy all files to their correct locations
- Preserve original files (uses `cp` not `mv`)

### Step 2: Verify Directory Structure

After running the script, you should have:

```
arcana-ios/
├── Sources/
│   ├── ArcanaCore/
│   ├── ArcanaDomain/
│   ├── ArcanaData/
│   └── ArcanaPresentation/
└── Tests/
    ├── ArcanaCoreTests/
    ├── ArcanaDomainTests/
    ├── ArcanaDataTests/
    └── ArcanaPresentationTests/
```

### Step 3: Clean and Build

```bash
# Clean everything
swift package clean
rm -rf .build

# Resolve dependencies
swift package resolve

# Build
swift build
```

### Step 4: Fix Any Remaining Issues

If you see import errors, check:

1. **File is in correct location**
   ```bash
   # Should exist:
   ls Sources/ArcanaCore/Common/ErrorCode.swift
   ls Sources/ArcanaDomain/Model/User.swift
   ```

2. **Package.swift is correct**
   ```swift
   // Should have this:
   dependencies: [
       .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.1.0"),
   ],
   ```

3. **Module imports are correct**
   ```swift
   // In ArcanaDomain files:
   import ArcanaCore
   
   // In ArcanaData files:
   import ArcanaCore
   import ArcanaDomain
   
   // In ArcanaPresentation files:
   import ArcanaCore
   import ArcanaDomain
   import ArcanaData
   import Dependencies  // For @Dependency
   ```

### Step 5: Update Your App

In `arcana_iosApp.swift`:

```swift
import SwiftUI
import SwiftData
import ArcanaCore        // Add this
import ArcanaPresentation // Add this

@main
struct arcana_iosApp: App {
    let modelContainer: ModelContainer
    
    init() {
        modelContainer = AppDependencies.createModelContainer()
        AppDependencies.setup(modelContainer: modelContainer)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
```

In `ContentView.swift`:

```swift
import SwiftUI
import ArcanaPresentation  // Add this

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}
```

## 📊 File Checklist

Use this to verify all files are moved:

### Core Module (12 files)
- [ ] `Sources/ArcanaCore/Analytics/AnalyticsEvent.swift`
- [ ] `Sources/ArcanaCore/Analytics/AnalyticsTracker.swift`
- [ ] `Sources/ArcanaCore/Analytics/PersistentAnalyticsTracker.swift`
- [ ] `Sources/ArcanaCore/Common/ErrorCode.swift`
- [ ] `Sources/ArcanaCore/Common/AppError.swift`
- [ ] `Sources/ArcanaCore/Common/LRUCache.swift`
- [ ] `Sources/ArcanaCore/Common/Extensions.swift`
- [ ] `Sources/ArcanaCore/DI/DIContainer.swift`
- [ ] `Sources/ArcanaCore/DI/UserServiceDependency.swift`
- [ ] `Sources/ArcanaCore/DI/AnalyticsTrackerDependency.swift`
- [ ] `Sources/ArcanaCore/DI/UserRepositoryDependency.swift`
- [ ] `Sources/ArcanaCore/DI/AppDependencies.swift`

### Domain Module (4 files)
- [ ] `Sources/ArcanaDomain/Model/User.swift`
- [ ] `Sources/ArcanaDomain/Service/UserService.swift`
- [ ] `Sources/ArcanaDomain/Service/UserServiceImpl.swift`
- [ ] `Sources/ArcanaDomain/Validation/UserValidator.swift`

### Data Module (8 files)
- [ ] `Sources/ArcanaData/Local/LocalUserDataSource.swift`
- [ ] `Sources/ArcanaData/Local/SwiftDataUserDataSource.swift`
- [ ] `Sources/ArcanaData/Local/Entities/UserEntity.swift`
- [ ] `Sources/ArcanaData/Local/Entities/AnalyticsEventEntity.swift`
- [ ] `Sources/ArcanaData/Remote/RemoteUserDataSource.swift`
- [ ] `Sources/ArcanaData/Remote/MockRemoteUserDataSource.swift`
- [ ] `Sources/ArcanaData/Repository/UserRepository.swift`
- [ ] `Sources/ArcanaData/Repository/OfflineFirstUserRepository.swift`

### Presentation Module (6 files)
- [ ] `Sources/ArcanaPresentation/Screens/User/UserListView.swift`
- [ ] `Sources/ArcanaPresentation/Screens/User/UserListViewModel.swift`
- [ ] `Sources/ArcanaPresentation/Screens/User/UserFormView.swift`
- [ ] `Sources/ArcanaPresentation/Screens/User/UserFormViewModel.swift`
- [ ] `Sources/ArcanaPresentation/Components/UserCard.swift`
- [ ] `Sources/ArcanaPresentation/Theme/ArcanaTheme.swift`

### Tests (2 files)
- [ ] `Tests/ArcanaDomainTests/UserValidatorTests.swift`
- [ ] `Tests/ArcanaPresentationTests/UserListViewModelTests.swift`

## 🔧 Manual Migration (If Script Fails)

If the script doesn't work, do it manually:

```bash
# 1. Create directories
mkdir -p Sources/ArcanaCore/{Analytics,Common,DI}
mkdir -p Sources/ArcanaDomain/{Model,Service,Validation}
mkdir -p Sources/ArcanaData/{Local/Entities,Remote,Repository}
mkdir -p Sources/ArcanaPresentation/{Screens/User,Components,Theme}
mkdir -p Tests/{ArcanaCoreTests,ArcanaDomainTests,ArcanaDataTests,ArcanaPresentationTests}

# 2. Copy Core files
cp CoreAnalyticsAnalyticsEvent.swift Sources/ArcanaCore/Analytics/AnalyticsEvent.swift
cp CoreAnalyticsAnalyticsTracker.swift Sources/ArcanaCore/Analytics/AnalyticsTracker.swift
cp CoreAnalyticsPersistentAnalyticsTracker.swift Sources/ArcanaCore/Analytics/PersistentAnalyticsTracker.swift

cp CoreCommonErrorCode.swift Sources/ArcanaCore/Common/ErrorCode.swift
cp CoreCommonAppError.swift Sources/ArcanaCore/Common/AppError.swift
cp CoreCommonLRUCache.swift Sources/ArcanaCore/Common/LRUCache.swift
cp CoreCommonExtensions.swift Sources/ArcanaCore/Common/Extensions.swift

cp CoreDIDIContainer.swift Sources/ArcanaCore/DI/DIContainer.swift
cp CoreDIUserServiceDependency.swift Sources/ArcanaCore/DI/UserServiceDependency.swift
cp CoreDIAnalyticsTrackerDependency.swift Sources/ArcanaCore/DI/AnalyticsTrackerDependency.swift
cp CoreDIUserRepositoryDependency.swift Sources/ArcanaCore/DI/UserRepositoryDependency.swift
cp CoreDIAppDependencies.swift Sources/ArcanaCore/DI/AppDependencies.swift

# 3. Copy Domain files
cp DomainModelUser.swift Sources/ArcanaDomain/Model/User.swift
cp DomainServiceUserService.swift Sources/ArcanaDomain/Service/UserService.swift
cp DomainServiceUserServiceImpl.swift Sources/ArcanaDomain/Service/UserServiceImpl.swift
cp DomainValidationUserValidator.swift Sources/ArcanaDomain/Validation/UserValidator.swift

# 4. Copy Data files
cp DataLocalLocalUserDataSource.swift Sources/ArcanaData/Local/LocalUserDataSource.swift
cp DataLocalSwiftDataUserDataSource.swift Sources/ArcanaData/Local/SwiftDataUserDataSource.swift
cp DataLocalEntitiesUserEntity.swift Sources/ArcanaData/Local/Entities/UserEntity.swift
cp DataLocalEntitiesAnalyticsEventEntity.swift Sources/ArcanaData/Local/Entities/AnalyticsEventEntity.swift
cp DataRemoteRemoteUserDataSource.swift Sources/ArcanaData/Remote/RemoteUserDataSource.swift
cp DataRemoteMockRemoteUserDataSource.swift Sources/ArcanaData/Remote/MockRemoteUserDataSource.swift
cp DataRepositoryUserRepository.swift Sources/ArcanaData/Repository/UserRepository.swift
cp DataRepositoryOfflineFirstUserRepository.swift Sources/ArcanaData/Repository/OfflineFirstUserRepository.swift

# 5. Copy Presentation files
cp PresentationScreensUserUserListView.swift Sources/ArcanaPresentation/Screens/User/UserListView.swift
cp PresentationScreensUserUserListViewModel.swift Sources/ArcanaPresentation/Screens/User/UserListViewModel.swift
cp PresentationScreensUserUserFormView.swift Sources/ArcanaPresentation/Screens/User/UserFormView.swift
cp PresentationScreensUserUserFormViewModel.swift Sources/ArcanaPresentation/Screens/User/UserFormViewModel.swift
cp PresentationComponentsUserCard.swift Sources/ArcanaPresentation/Components/UserCard.swift
cp PresentationThemeArcanaTheme.swift Sources/ArcanaPresentation/Theme/ArcanaTheme.swift

# 6. Copy Test files
cp arcana-iosTestsUserValidatorTests.swift Tests/ArcanaDomainTests/UserValidatorTests.swift
cp arcana-iosTestsUserListViewModelTests.swift Tests/ArcanaPresentationTests/UserListViewModelTests.swift

# 7. Build
swift build
```

## 🎯 Expected Results

After successful migration:

```bash
# This should work:
swift build
# ✅ Build complete!

# This should work:
swift test
# ✅ Test Suite 'All tests' passed

# In Xcode:
open Package.swift
# ✅ Should open and build successfully
```

## 🐛 Troubleshooting

### Error: "No such module 'Dependencies'"

**Solution**: Make sure swift-dependencies is in Package.swift:
```swift
dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.1.0"),
],
```

### Error: "No such module 'ArcanaCore'"

**Solution**: Files aren't in `Sources/` directory. Run migration script.

### Error: "Cannot find type 'User' in scope"

**Solution**: Add import statement:
```swift
import ArcanaDomain  // For User model
```

### Error: Build fails with path issues

**Solution**: Clean and rebuild:
```bash
swift package clean
rm -rf .build .swiftpm
swift package resolve
swift build
```

## 📚 Documentation

After migration, update your README imports:

```swift
// Old way (won't work):
import UserService  // ❌

// New way:
import ArcanaDomain  // ✅
```

## ✅ Final Verification

Run these commands to verify everything works:

```bash
# 1. Clean build
make clean
make build

# 2. Run tests
make test

# 3. Check structure
tree Sources/ -L 3

# 4. Verify imports
grep -r "^import" Sources/ | head -20
```

You should see:
- ✅ Clean build
- ✅ All tests pass
- ✅ Proper directory structure
- ✅ Correct module imports

---

**Ready to migrate! Run `./move_to_sources.sh` to begin! 🚀**
