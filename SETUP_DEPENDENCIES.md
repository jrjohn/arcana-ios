# Swift Dependencies Setup Guide

## Current Status

✅ Package is **resolved** (Package.resolved exists with swift-dependencies v1.10.0)
⏳ Package needs to be **linked to target** in Xcode project

## Option 1: Add via Xcode GUI (Recommended - 2 minutes)

### Steps:

1. **Open the project**:
   ```bash
   cd /Users/jrjohn/Documents/projects/arcana-ios
   open arcana-ios.xcodeproj
   ```

2. **Select the project** in the Navigator (click on `arcana-ios` at the top)

3. **Select the `arcana-ios` target** (under TARGETS)

4. **Go to "Frameworks, Libraries, and Embedded Content"** section

5. **Click the "+" button**

6. **Click "Add Other..." → "Add Package Dependency..."**

7. **Enter package URL**:
   ```
   https://github.com/pointfreeco/swift-dependencies
   ```

8. **Select Dependency Rule**: "Up to Next Major Version" with **1.1.0**

9. **Click "Add Package"**

10. **Select "Dependencies" library** and click "Add Package"

11. **Build**: Press `Cmd+B`

✅ Done! Should build successfully.

---

## Option 2: Use Existing Package Resolution (Faster!)

Since Package.resolved already exists, you can:

1. **Open Xcode**:
   ```bash
   open arcana-ios.xcodeproj
   ```

2. **Go to File → Add Package Dependencies...**

3. **In the search field**, paste:
   ```
   https://github.com/pointfreeco/swift-dependencies
   ```

4. **Xcode should show "Already Added"** or show version 1.10.0

5. **If not added to target**:
   - Select project → arcana-ios target
   - General tab → "Frameworks, Libraries, and Embedded Content"
   - Click "+" → find "Dependencies" → Add

6. **Build**: `Cmd+B`

---

## Option 3: Command Line (Advanced)

If you prefer command line, you need to:

1. **Ensure Package.resolved is in the right place**:
   ```bash
   # It's already here:
   # arcana-ios.xcodeproj/Package.resolved
   ```

2. **The package needs to be added to project.pbxproj**

   This requires manual editing of the Xcode project file, which is not recommended as it's error-prone.

---

## Verification

After adding the package, verify it works:

### 1. Check Package is Linked
In Xcode Project Navigator:
- Select project
- Select target
- Go to "Build Phases" → "Link Binary with Libraries"
- Should see "Dependencies" listed

### 2. Build Successfully
```bash
cd /Users/jrjohn/Documents/projects/arcana-ios
xcodebuild -project arcana-ios.xcodeproj -scheme arcana-ios -destination 'generic/platform=iOS Simulator' build
```

Should output: `** BUILD SUCCEEDED **`

### 3. Check Imports Work
Open any ViewModel file and verify:
```swift
import Dependencies  // Should not show error
@Dependency(\.userService) var userService  // Should work
```

---

## What swift-dependencies Provides

Once added, the project uses:

✅ **@Dependency Property Wrappers**
```swift
@MainActor
final class UserListViewModel: ObservableObject {
    @Dependency(\.userService) var userService
    @Dependency(\.analyticsTracker) var analyticsTracker

    init() {  // No parameters needed!
        setupBindings()
    }
}
```

✅ **Automatic Dependency Injection**
- No manual factory methods
- No boilerplate container code
- Dependencies resolved at compile-time

✅ **Easy Testing**
```swift
func testExample() {
    withDependencies {
        $0.userService = MockUserService()
    } operation: {
        let viewModel = UserListViewModel()
        // viewModel.userService is now MockUserService
    }
}
```

✅ **SwiftUI Previews**
```swift
#Preview {
    AppDependencies.withPreviewDependencies(mockUsers: User.mockUsers) {
        UserListView(viewModel: UserListViewModel())
    }
}
```

---

## Troubleshooting

### Error: "Unable to find module dependency: 'Dependencies'"

**Solution**: The package is resolved but not linked to the target.
- Follow Option 1 or Option 2 above to link it

### Error: "Could not resolve package dependencies"

**Solution**: Delete derived data and package caches:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/arcana-ios-*
rm -rf ~/Library/Caches/org.swift.swiftpm
```

Then follow Option 1 to re-add the package.

### Build succeeds but @Dependency doesn't work

**Solution**: Make sure you're importing Dependencies:
```swift
import Dependencies  // Add this at the top of the file
```

---

## Package Information

- **Name**: swift-dependencies
- **Author**: Point-Free (pointfreeco)
- **GitHub**: https://github.com/pointfreeco/swift-dependencies
- **Version**: 1.10.0 (resolved)
- **License**: MIT
- **Dependencies**:
  - combine-schedulers (1.1.0)
  - swift-clocks (1.0.6)
  - swift-concurrency-extras (1.3.2)
  - swift-syntax (602.0.0)
  - xctest-dynamic-overlay (1.7.0)

All dependencies are already resolved in `Package.resolved`.

---

## Quick Start (TL;DR)

```bash
# 1. Open Xcode
open arcana-ios.xcodeproj

# 2. In Xcode: File → Add Package Dependencies
# 3. Paste: https://github.com/pointfreeco/swift-dependencies
# 4. Click Add Package
# 5. Build: Cmd+B
```

Done! 🎉

