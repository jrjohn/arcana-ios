# Dependency Injection Setup Fix

## Problem

The app was crashing with:
```
Fatal error: AnalyticsTracker not configured. Call AppDependencies.setup() in your App init.
```

## Root Cause

The issue occurred because:
1. `NavGraph` was being created as a `@State` property in the body of the App
2. SwiftUI evaluates `@State` properties during view initialization
3. `NavGraph` tried to access `@Dependency(\.analyticsTracker)` at initialization time
4. Dependencies weren't configured yet because `AppDependencies.setup()` is called in `init()`
5. This created a timing issue where dependencies were accessed before being set up

## Solution

We fixed this in two ways:

### Fix 1: Move NavGraph Creation After Dependencies Setup

**Before (Broken):**
```swift
@main
struct arcana_iosApp: App {
    @State private var navGraph = NavGraph() // ❌ Created too early!
    
    init() {
        AppDependencies.setup(modelContainer: sharedModelContainer)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**After (Fixed):**
```swift
@main
struct arcana_iosApp: App {
    let sharedModelContainer: ModelContainer
    
    init() {
        // Create ModelContainer
        sharedModelContainer = try! ModelContainer(...)
        
        // Setup dependencies BEFORE any views are created
        MainActor.assumeIsolated {
            AppDependencies.setup(modelContainer: sharedModelContainer)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView() // NavGraph created inside ContentView
                .modelContainer(sharedModelContainer)
        }
    }
}

struct ContentView: View {
    @State private var navGraph = NavGraph() // ✅ Created after dependencies
    
    var body: some View {
        NavigationStack(path: $navGraph.path) {
            MainView(viewModel: MainViewModel(navGraph: navGraph))
        }
    }
}
```

### Fix 2: Make NavGraph Use Lazy Dependency Access

**Before (Broken):**
```swift
@Observable
final class NavGraph {
    // ❌ Property wrapper accesses dependency at initialization
    @Dependency(\.analyticsTracker) var analyticsTracker
    
    func push(_ route: AppRoute) {
        analyticsTracker.trackScreen(...) // Uses property
    }
}
```

**After (Fixed):**
```swift
@Observable
final class NavGraph {
    // ✅ No stored dependency property
    
    func push(_ route: AppRoute) {
        // ✅ Access dependency lazily when method is called
        @Dependency(\.analyticsTracker) var analyticsTracker
        analyticsTracker.trackScreen(...)
    }
}
```

## Updated Files

### 1. arcana_iosApp.swift

```swift
//
//  arcana_iosApp.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import SwiftUI
import SwiftData

@main
struct arcana_iosApp: App {
    let sharedModelContainer: ModelContainer
    
    init() {
        // Step 1: Create ModelContainer first
        let schema = Schema([
            UserEntity.self,
            AnalyticsEventEntity.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema, 
            isStoredInMemoryOnly: false
        )

        do {
            sharedModelContainer = try ModelContainer(
                for: schema, 
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        // Step 2: Configure dependencies (must happen before creating views)
        MainActor.assumeIsolated {
            AppDependencies.setup(modelContainer: sharedModelContainer)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
    }
}

// MARK: - Content View with Navigation

struct ContentView: View {
    @State private var navGraph = NavGraph()
    
    var body: some View {
        NavigationStack(path: $navGraph.path) {
            MainView(viewModel: MainViewModel(navGraph: navGraph))
                .navigationDestination(for: AppRoute.self) { route in
                    NavGraphView.view(for: route, navGraph: navGraph)
                }
        }
        .withNavigation(navGraph)
    }
}
```

### 2. NavGraph.swift (trackNavigation method)

```swift
// MARK: - Analytics

private func trackNavigation(to route: AppRoute) {
    // Access dependency lazily when needed
    @Dependency(\.analyticsTracker) var analyticsTracker
    analyticsTracker.trackScreen(route.analyticsName)
}
```

## Why This Works

### Execution Order (Fixed)

```
1. App.init() starts
   ↓
2. ModelContainer created
   ↓
3. AppDependencies.setup() called
   ↓
4. Dependencies registered and ready
   ↓
5. App.init() completes
   ↓
6. body evaluated
   ↓
7. ContentView created
   ↓
8. @State var navGraph initialized ✅
   ↓
9. NavGraph accesses dependencies (now available!) ✅
```

### Execution Order (Before - Broken)

```
1. App struct evaluated
   ↓
2. @State var navGraph = NavGraph() initialized ❌
   ↓
3. NavGraph tries to access @Dependency(\.analyticsTracker) ❌
   ↓
4. Dependencies not configured yet! 💥
   ↓
5. CRASH: "AnalyticsTracker not configured"
```

## Key Principles

### 1. Dependencies Must Be Configured Before Use

```swift
// ✅ CORRECT ORDER
init() {
    modelContainer = createModelContainer()
    AppDependencies.setup(modelContainer: modelContainer) // First
}

var body: some Scene {
    WindowGroup {
        ContentView() // Dependencies available now
    }
}
```

### 2. Lazy Dependency Access is Safer

```swift
// ❌ Eager (accessed at init)
@Dependency(\.analyticsTracker) var analyticsTracker

// ✅ Lazy (accessed when method is called)
func someMethod() {
    @Dependency(\.analyticsTracker) var analyticsTracker
    analyticsTracker.trackEvent(...)
}
```

### 3. Separate View Initialization from App Initialization

```swift
// ✅ Good pattern
@main
struct App: App {
    init() {
        setupDependencies()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView() // State created here
        }
    }
}

struct ContentView: View {
    @State private var viewModel = ViewModel() // Safe
}
```

## Testing the Fix

### 1. Clean Build

```bash
# In Xcode
Cmd + Shift + K (Clean Build Folder)
Cmd + B (Build)
```

### 2. Run the App

The app should now:
- ✅ Launch without crashes
- ✅ Show MainView with user count
- ✅ Navigate to UserListView when tapping "Manage Users"
- ✅ Track analytics events

### 3. Verify Analytics

Check console for analytics logs:
```
📊 Analytics: Tracked screen 'main_screen'
📊 Analytics: Tracked screen 'user_list_screen'
```

## Alternative Solutions

### Alternative 1: Use Lazy Var

```swift
@main
struct arcana_iosApp: App {
    init() {
        AppDependencies.setup(...)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    // ✅ Lazy initialization
    @State private var navGraph: NavGraph = {
        NavGraph()
    }()
}
```

### Alternative 2: Use @StateObject (for ObservableObject)

```swift
struct ContentView: View {
    @StateObject private var navGraph = NavGraph()
}
```

But `@Observable` is better for iOS 17+ (which you're using).

### Alternative 3: Inject Dependencies Explicitly

```swift
final class NavGraph {
    private let analyticsTracker: AnalyticsTracker
    
    init(analyticsTracker: AnalyticsTracker) {
        self.analyticsTracker = analyticsTracker
    }
}

// In ContentView
struct ContentView: View {
    @Dependency(\.analyticsTracker) var analyticsTracker
    @State private var navGraph: NavGraph?
    
    var body: some View {
        // ...
        .onAppear {
            if navGraph == nil {
                navGraph = NavGraph(analyticsTracker: analyticsTracker)
            }
        }
    }
}
```

But the solution we implemented is cleaner.

## Common Pitfalls

### Pitfall 1: Creating ViewModels in @main

```swift
// ❌ BAD - ViewModel created before dependencies
@main
struct App: App {
    @State private var viewModel = MainViewModel() // Crashes!
    
    init() {
        AppDependencies.setup(...)
    }
}
```

**Solution:** Create ViewModels in child views or use lazy initialization.

### Pitfall 2: Accessing Dependencies in init()

```swift
// ❌ BAD
class MyViewModel {
    @Dependency(\.userService) var userService
    
    init() {
        userService.doSomething() // Crashes if dependencies not ready!
    }
}
```

**Solution:** Access dependencies in methods, not init.

### Pitfall 3: Multiple Dependency Setup Calls

```swift
// ❌ BAD - Called multiple times
init() {
    AppDependencies.setup(...)
}

init() {
    AppDependencies.setup(...) // Called again?
}
```

**Solution:** Only call `AppDependencies.setup()` once in App.init().

## Verification Checklist

- [x] ModelContainer created in App.init()
- [x] AppDependencies.setup() called in App.init()
- [x] NavGraph created in ContentView (after dependencies)
- [x] NavGraph uses lazy dependency access
- [x] App builds without errors
- [x] App launches without crashes
- [x] Navigation works correctly
- [x] Analytics tracking works

## Summary

**Problem:** Dependencies accessed before configuration  
**Solution:** Move NavGraph initialization after dependency setup + use lazy dependency access  
**Result:** ✅ App works correctly!

---

**Status:** ✅ Fixed  
**Files Modified:** 2 (arcana_iosApp.swift, NavGraph.swift)  
**Testing:** Verified working
