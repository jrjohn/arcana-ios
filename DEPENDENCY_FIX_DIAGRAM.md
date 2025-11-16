# Before & After: Dependency Initialization Fix

## BEFORE (Broken) 💥

```
┌─────────────────────────────────────────────────────┐
│  @main struct arcana_iosApp: App                    │
│                                                     │
│  @State private var navGraph = NavGraph() ❌       │
│  ↑                                                  │
│  │ NavGraph tries to access dependencies HERE      │
│  │ But dependencies aren't ready yet!              │
│                                                     │
│  init() {                                           │
│      AppDependencies.setup(...) ⚠️  Too late!     │
│  }                                                  │
│                                                     │
│  var body: some Scene {                             │
│      WindowGroup {                                  │
│          MainView(...)                              │
│      }                                              │
│  }                                                  │
└─────────────────────────────────────────────────────┘

❌ CRASH: "AnalyticsTracker not configured"
```

### Execution Timeline (Broken)

```
Time →
─────────────────────────────────────────────────────────

T1: Swift evaluates struct
    │
    ├─> @State var navGraph = NavGraph()
    │   ├─> NavGraph.init()
    │   └─> @Dependency(\.analyticsTracker) accessed ❌
    │       └─> Dependency NOT CONFIGURED! 💥 CRASH!
    │
T2: init() called (never reached)
    │
    └─> AppDependencies.setup() (never executed)
```

## AFTER (Fixed) ✅

```
┌─────────────────────────────────────────────────────┐
│  @main struct arcana_iosApp: App                    │
│                                                     │
│  let sharedModelContainer: ModelContainer           │
│                                                     │
│  init() {                                           │
│      // 1. Create container                         │
│      sharedModelContainer = try! ModelContainer(...)│
│                                                     │
│      // 2. Setup dependencies FIRST ✅             │
│      MainActor.assumeIsolated {                     │
│          AppDependencies.setup(...)                 │
│      }                                              │
│  }                                                  │
│                                                     │
│  var body: some Scene {                             │
│      WindowGroup {                                  │
│          ContentView() ← NavGraph created here      │
│      }                                              │
│  }                                                  │
└─────────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────┐
│  struct ContentView: View                           │
│                                                     │
│  @State private var navGraph = NavGraph() ✅       │
│  ↑                                                  │
│  │ NavGraph created AFTER dependencies are ready!  │
│                                                     │
│  var body: some View {                              │
│      NavigationStack(path: $navGraph.path) {        │
│          MainView(...)                              │
│      }                                              │
│  }                                                  │
└─────────────────────────────────────────────────────┘

✅ SUCCESS: Dependencies ready before NavGraph created
```

### Execution Timeline (Fixed)

```
Time →
─────────────────────────────────────────────────────────

T1: App.init() called
    │
    ├─> Create ModelContainer ✅
    │
    ├─> Call AppDependencies.setup() ✅
    │   └─> All dependencies registered ✅
    │
    └─> init() completes ✅

T2: body evaluated
    │
    └─> ContentView created ✅

T3: ContentView.body evaluated
    │
    └─> @State var navGraph = NavGraph() ✅
        └─> Dependencies available! ✅

T4: View hierarchy built ✅

T5: App displays ✅
```

## Dependency Access: Before & After

### NavGraph Dependency Access (Before - Broken)

```swift
@Observable
final class NavGraph {
    // ❌ Property wrapper evaluated at init time
    @Dependency(\.analyticsTracker) var analyticsTracker
    
    func push(_ route: AppRoute) {
        path.append(route)
        // Uses stored property (accessed at init)
        analyticsTracker.trackScreen(route.analyticsName)
    }
}

// When NavGraph() is called:
// 1. @Dependency(\.analyticsTracker) tries to get dependency
// 2. Dependency not configured yet
// 3. CRASH! 💥
```

### NavGraph Dependency Access (After - Fixed)

```swift
@Observable
final class NavGraph {
    // ✅ No stored dependency property
    
    func push(_ route: AppRoute) {
        path.append(route)
        // Lazy access - only when method is called
        @Dependency(\.analyticsTracker) var analyticsTracker
        analyticsTracker.trackScreen(route.analyticsName)
    }
}

// When NavGraph() is called:
// 1. No dependencies accessed ✅
// 2. Object created successfully ✅
//
// When push() is called later:
// 1. @Dependency accessed
// 2. Dependency IS configured ✅
// 3. Works! ✅
```

## View Hierarchy Comparison

### BEFORE (Broken)

```
arcana_iosApp
│
├─ @State var navGraph (created at struct level) ❌
│  └─ Tries to access dependencies → CRASH
│
├─ init()
│  └─ AppDependencies.setup() (too late)
│
└─ body
   └─ WindowGroup
      └─ UserListView
```

### AFTER (Fixed)

```
arcana_iosApp
│
├─ init()
│  ├─ Create ModelContainer ✅
│  └─ AppDependencies.setup() ✅
│
└─ body
   └─ WindowGroup
      └─ ContentView
         ├─ @State var navGraph (created here) ✅
         └─ NavigationStack
            └─ MainView
               └─ viewModel (uses navGraph) ✅
```

## State Initialization Timing

### The Problem with @State in @main

```
@main
struct App: App {
    @State var navGraph = NavGraph() // ❌
    // ^
    // │
    // └─ @State property wrappers are evaluated
    //    when the struct is initialized
    //    This happens BEFORE init() is called!
    
    init() {
        // Too late - @State already evaluated above
        setupDependencies()
    }
}
```

### The Solution: @State in Child View

```
@main
struct App: App {
    init() {
        // ✅ Runs FIRST
        setupDependencies()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView() // ✅ Created AFTER init()
        }
    }
}

struct ContentView: View {
    @State var navGraph = NavGraph() // ✅ Safe!
    // ^
    // │
    // └─ This is evaluated when ContentView is
    //    created, which happens AFTER App.init()
}
```

## Dependency Resolution Flow

### BEFORE (Broken)

```
NavGraph.init()
    │
    ▼
Access @Dependency(\.analyticsTracker)
    │
    ▼
Check DependencyValues._current
    │
    ▼
analyticsTracker = ???
    │
    ▼
NO VALUE FOUND ❌
    │
    ▼
Return liveValue from DependencyKey
    │
    ▼
fatalError("AnalyticsTracker not configured...") 💥
```

### AFTER (Fixed)

```
App.init()
    │
    ▼
AppDependencies.setup(modelContainer)
    │
    ▼
Register all dependencies
    │
    ├─> userService = UserServiceImpl(...)
    ├─> analyticsTracker = PersistentAnalyticsTracker(...)
    └─> userRepository = OfflineFirstUserRepository(...)
    │
    ▼
Dependencies ready ✅
    │
    ▼
ContentView created
    │
    ▼
NavGraph.init()
    │
    ▼
(No dependency access at init) ✅
    │
    ▼
Later: trackNavigation() called
    │
    ▼
Access @Dependency(\.analyticsTracker)
    │
    ▼
Check DependencyValues._current
    │
    ▼
analyticsTracker = PersistentAnalyticsTracker ✅
    │
    ▼
Use dependency successfully ✅
```

## Code Diff

### arcana_iosApp.swift

```diff
  @main
  struct arcana_iosApp: App {
-     @State private var navGraph = NavGraph()
+     let sharedModelContainer: ModelContainer
      
-     var sharedModelContainer: ModelContainer = {
-         let schema = Schema([...])
-         ...
-         return try! ModelContainer(...)
-     }()
      
      init() {
+         let schema = Schema([...])
+         let modelConfiguration = ModelConfiguration(...)
+         sharedModelContainer = try! ModelContainer(...)
+         
          MainActor.assumeIsolated {
              AppDependencies.setup(modelContainer: sharedModelContainer)
          }
      }
  
      var body: some Scene {
          WindowGroup {
-             UserListView(viewModel: UserListViewModel())
+             ContentView()
+                 .modelContainer(sharedModelContainer)
          }
-         .modelContainer(sharedModelContainer)
      }
  }
+
+ struct ContentView: View {
+     @State private var navGraph = NavGraph()
+     
+     var body: some View {
+         NavigationStack(path: $navGraph.path) {
+             MainView(viewModel: MainViewModel(navGraph: navGraph))
+                 .navigationDestination(for: AppRoute.self) { route in
+                     NavGraphView.view(for: route, navGraph: navGraph)
+                 }
+         }
+         .withNavigation(navGraph)
+     }
+ }
```

### NavGraph.swift

```diff
  @Observable
  final class NavGraph {
      var path: [AppRoute] = []
      var presentedSheet: AppRoute?
-     
-     @ObservationIgnored
-     @Dependency(\.analyticsTracker) var analyticsTracker
      
      func push(_ route: AppRoute) {
          path.append(route)
          trackNavigation(to: route)
      }
      
      // ...
      
      private func trackNavigation(to route: AppRoute) {
+         @Dependency(\.analyticsTracker) var analyticsTracker
          analyticsTracker.trackScreen(route.analyticsName)
      }
  }
```

## Summary

### Problem
```
NavGraph created → Accesses dependency → Dependency not ready → CRASH
```

### Solution
```
Setup dependencies → Create NavGraph → Access dependency → Works! ✅
```

### Key Changes
1. ✅ Dependencies configured in App.init() BEFORE views
2. ✅ NavGraph created in ContentView (AFTER dependencies ready)
3. ✅ NavGraph uses lazy dependency access (when methods called)

---

**Status:** ✅ Fixed  
**Result:** App launches and runs correctly  
**Navigation:** Working as expected
