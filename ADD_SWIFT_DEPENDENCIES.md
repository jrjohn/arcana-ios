# Adding swift-dependencies Package to Xcode Project

## Quick Steps

1. **Open the project in Xcode**:
   ```bash
   open arcana-ios.xcodeproj
   ```

2. **Add Package Dependency**:
   - In Xcode, select the `arcana-ios` project in the Project Navigator
   - Select the `arcana-ios` target
   - Go to the "General" tab, scroll down to "Frameworks, Libraries, and Embedded Content"
   - Click the "+" button
   - OR: Go to "Package Dependencies" tab and click "+"

3. **Add swift-dependencies**:
   - In the search field, enter: `https://github.com/pointfreeco/swift-dependencies`
   - Click "Add Package"
   - Select version: **1.1.0 or later**
   - Click "Add Package" again

4. **Add to Target**:
   - Ensure "Dependencies" library is added to the `arcana-ios` target
   - Click "Add Package"

5. **Build**:
   - Press `Cmd+B` to build
   - Should build successfully!

## What This Enables

With swift-dependencies, the project now uses:

- ✅ `@Dependency` property wrappers in ViewModels (no manual dependency injection needed)
- ✅ Automatic dependency injection across the app
- ✅ Easy testing with `withDependencies`
- ✅ SwiftUI previews with mock data via `AppDependencies.withPreviewDependencies`

## Current Status

The code is ready for swift-dependencies:
- ✅ AppDependencies configured with dependency registration
- ✅ ViewModels use @Dependency property wrappers
- ✅ Preview helpers ready in AppDependencies
- ⏳ Just need to add the package in Xcode

## Verification

After adding the package, verify it works:

1. Build the project (`Cmd+B`) - should succeed
2. Run the app (`Cmd+R`)
3. Check SwiftUI previews work (`Cmd+Option+P`)

## Package Details

- **Name**: swift-dependencies
- **URL**: https://github.com/pointfreeco/swift-dependencies
- **Version**: 1.1.0+
- **Author**: Point-Free
- **License**: MIT

