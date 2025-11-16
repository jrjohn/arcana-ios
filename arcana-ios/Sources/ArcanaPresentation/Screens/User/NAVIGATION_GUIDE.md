# Navigation System Documentation

## Overview

The app now uses a centralized navigation system built on **NavGraph**, which manages all routing throughout the application. This provides a single source of truth for navigation state and makes it easy to navigate programmatically from anywhere in the app.

## Architecture

### Core Components

1. **AppRoute** - Defines all possible destinations/screens
2. **NavGraph** - Central navigation coordinator/router
3. **NavGraphView** - View builder that creates views for routes
4. **ViewModels** - Now receive NavGraph for programmatic navigation

## File Structure

```
Navigation System/
├── AppRoute.swift          - Route definitions
├── NavGraph.swift          - Navigation coordinator
├── MainViewModel.swift     - Main screen ViewModel
├── MainView.swift          - Updated to use ViewModel
├── UserListViewModel.swift - Updated with NavGraph
├── UserFormViewModel.swift - Updated with NavGraph
└── ArcanaAppWithNavigation.swift - App entry point
```

## Key Features

### 1. Type-Safe Navigation

All routes are defined in `AppRoute` enum:

```swift
enum AppRoute: Hashable, Identifiable {
    case main
    case userList
    case userDetail(User)
    case userForm(mode: UserFormMode)
    case settings
}
```

### 2. Centralized Navigation Logic

NavGraph provides clean API for navigation:

```swift
// Push navigation
navGraph.push(.userList)
navGraph.navigateToUserDetail(user)

// Sheet presentation
navGraph.presentSheet(.userForm(mode: .create))
navGraph.presentEditUserForm(user)

// Full screen covers
navGraph.presentFullScreenCover(.settings)

// Navigation stack management
navGraph.pop()
navGraph.popToRoot()
navGraph.popTo(.userList)

// Dismiss
navGraph.dismissSheet()
navGraph.dismissFullScreenCover()

// Alerts
navGraph.showAlert(AlertConfig(...))
```

### 3. ViewModel-Driven Navigation

ViewModels now handle navigation through NavGraph:

```swift
@MainActor
@Observable
final class MainViewModel {
    private let navGraph: NavGraph
    
    init(navGraph: NavGraph) {
        self.navGraph = navGraph
    }
    
    func send(_ input: Input) {
        switch input {
        case .navigateToUserList:
            navGraph.navigateToUserList()
        case .navigateToSettings:
            navGraph.navigateToSettings()
        }
    }
}
```

### 4. Analytics Integration

Navigation automatically tracks screen views:

```swift
private func trackNavigation(to route: AppRoute) {
    analyticsTracker.trackScreen(route.analyticsName)
}
```

## Usage Examples

### Example 1: Navigate from MainView to UserList

```swift
// In MainViewModel
func navigateToUserList() {
    navGraph.navigateToUserList()
}

// In MainView
Button("Manage Users") {
    viewModel.send(.navigateToUserList)
}
```

### Example 2: Present Create User Form

```swift
// In UserListViewModel
navGraph.presentSheet(.userForm(mode: .create))

// Or use convenience method
navGraph.presentCreateUserForm()
```

### Example 3: Navigate to User Detail

```swift
// In UserListViewModel
private func selectUser(_ user: User) {
    navGraph.navigateToUserDetail(user)
}
```

### Example 4: Show Alert

```swift
navGraph.showAlert(AlertConfig(
    title: "Delete User",
    message: "Are you sure?",
    primaryButton: .init(title: "Delete", role: .destructive) {
        deleteUser()
    },
    secondaryButton: .init(title: "Cancel", role: .cancel)
))
```

## App Setup

### Basic Setup (MainView as Root)

```swift
@main
struct ArcanaApp: App {
    let modelContainer: ModelContainer
    @State private var navGraph = NavGraph()
    
    init() {
        modelContainer = AppDependencies.createModelContainer()
        AppDependencies.setup(modelContainer: modelContainer)
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navGraph.path) {
                MainView(viewModel: MainViewModel(navGraph: navGraph))
                    .navigationDestination(for: AppRoute.self) { route in
                        NavGraphView.view(for: route, navGraph: navGraph)
                    }
            }
            .withNavigation(navGraph)
            .modelContainer(modelContainer)
        }
    }
}
```

### Alternative: UserList as Root

```swift
NavigationStack(path: $navGraph.path) {
    UserListView(viewModel: UserListViewModel(navGraph: navGraph))
        .navigationDestination(for: AppRoute.self) { route in
            NavGraphView.view(for: route, navGraph: navGraph)
        }
}
.withNavigation(navGraph)
```

## Navigation Patterns

### Pattern 1: Push Navigation

For hierarchical navigation (with back button):

```swift
navGraph.push(.userList)
navGraph.push(.userDetail(user))
```

**Result:** MainView → UserList → UserDetail

### Pattern 2: Sheet Presentation

For modal content:

```swift
navGraph.presentSheet(.userForm(mode: .create))
```

**Dismissal:**
```swift
navGraph.dismissSheet()
```

### Pattern 3: Full Screen Cover

For full-screen modal content:

```swift
navGraph.presentFullScreenCover(.settings)
```

### Pattern 4: Pop Navigation

```swift
// Pop one level
navGraph.pop()

// Pop to root
navGraph.popToRoot()

// Pop to specific route
navGraph.popTo(.userList)
```

## Adding New Routes

### Step 1: Add to AppRoute

```swift
enum AppRoute: Hashable, Identifiable {
    // Existing routes...
    case profile
    
    var id: String {
        switch self {
        case .profile:
            return "profile"
        }
    }
}
```

### Step 2: Add Title and Analytics

```swift
extension AppRoute {
    var title: String {
        switch self {
        case .profile:
            return "Profile"
        }
    }
    
    var analyticsName: String {
        switch self {
        case .profile:
            return "profile_screen"
        }
    }
}
```

### Step 3: Add View in NavGraphView

```swift
enum NavGraphView {
    static func view(for route: AppRoute, navGraph: NavGraph) -> some View {
        switch route {
        case .profile:
            ProfileView(navGraph: navGraph)
        }
    }
}
```

### Step 4: Add Convenience Method (Optional)

```swift
extension NavGraph {
    func navigateToProfile() {
        push(.profile)
    }
}
```

## Migration Guide

### Migrating from Old Navigation

**Before (Direct NavigationLink):**
```swift
NavigationLink(destination: UserDetailView(user: user)) {
    Text(user.fullName)
}
```

**After (NavGraph):**
```swift
Button(user.fullName) {
    viewModel.send(.selectUser(user))
}

// In ViewModel
func selectUser(_ user: User) {
    navGraph.navigateToUserDetail(user)
}
```

### Migrating from State-Based Navigation

**Before:**
```swift
@State private var showingDetail = false

Button("Show Detail") {
    showingDetail = true
}
.sheet(isPresented: $showingDetail) {
    DetailView()
}
```

**After:**
```swift
Button("Show Detail") {
    navGraph.presentSheet(.detail)
}
```

## Testing

### Testing with Mock NavGraph

```swift
final class MockNavGraph: NavGraph {
    var pushCallsCount = 0
    var lastPushedRoute: AppRoute?
    
    override func push(_ route: AppRoute) {
        pushCallsCount += 1
        lastPushedRoute = route
    }
}

// In tests
func testNavigateToUserList() {
    let mockNavGraph = MockNavGraph()
    let viewModel = MainViewModel(navGraph: mockNavGraph)
    
    viewModel.send(.navigateToUserList)
    
    #expect(mockNavGraph.pushCallsCount == 1)
    #expect(mockNavGraph.lastPushedRoute == .userList)
}
```

### Testing Navigation in SwiftUI Previews

```swift
#Preview {
    let navGraph = NavGraph()
    NavigationStack(path: .constant([AppRoute.userList])) {
        MainView(viewModel: MainViewModel(navGraph: navGraph))
            .navigationDestination(for: AppRoute.self) { route in
                NavGraphView.view(for: route, navGraph: navGraph)
            }
    }
}
```

## Best Practices

### 1. Always Pass NavGraph to ViewModels

```swift
// ✅ Good
let viewModel = MainViewModel(navGraph: navGraph)

// ❌ Bad - ViewModel can't navigate
let viewModel = MainViewModel()
```

### 2. Use Convenience Methods

```swift
// ✅ Good - Clear intent
navGraph.navigateToUserList()

// ✅ Also good - Type-safe
navGraph.push(.userList)

// ❌ Avoid - String-based
navGraph.navigate(to: "userList")
```

### 3. Handle Dismissal Properly

```swift
// ✅ Good - Through NavGraph
navGraph.dismissSheet()

// ❌ Bad - Direct @Environment
@Environment(\.dismiss) var dismiss
dismiss()
```

### 4. Track Navigation in Analytics

```swift
// NavGraph automatically tracks, but you can also track custom events
navGraph.push(.userList) // Automatically tracks
analyticsTracker.trackEvent(.custom(name: "user_list_opened", category: "navigation"))
```

## Advanced Features

### Deep Linking

```swift
func handleDeepLink(_ url: URL) {
    if url.path == "/users" {
        navGraph.popToRoot()
        navGraph.navigateToUserList()
    } else if url.path.starts(with: "/user/") {
        let userId = url.lastPathComponent
        // Fetch user and navigate
    }
}
```

### State Restoration

```swift
// Save navigation state
let pathData = try? JSONEncoder().encode(navGraph.path)
UserDefaults.standard.set(pathData, forKey: "navigationPath")

// Restore navigation state
if let pathData = UserDefaults.standard.data(forKey: "navigationPath"),
   let path = try? JSONDecoder().decode([AppRoute].self, from: pathData) {
    navGraph.path = path
}
```

### Conditional Navigation

```swift
func navigateToSettings() {
    guard userIsAuthenticated else {
        navGraph.showAlert(AlertConfig(
            title: "Authentication Required",
            message: "Please log in first"
        ))
        return
    }
    navGraph.navigateToSettings()
}
```

## Troubleshooting

### Issue: Navigation Doesn't Work

**Solution:** Make sure you're using `.navigationDestination(for: AppRoute.self)`:

```swift
NavigationStack(path: $navGraph.path) {
    RootView()
        .navigationDestination(for: AppRoute.self) { route in
            NavGraphView.view(for: route, navGraph: navGraph)
        }
}
```

### Issue: Sheet Doesn't Dismiss

**Solution:** Use `navGraph.dismissSheet()` instead of `@Environment(\.dismiss)`:

```swift
// In view or viewModel
navGraph.dismissSheet()
```

### Issue: Back Button Doesn't Appear

**Solution:** Make sure you're using `push` navigation, not sheets:

```swift
navGraph.push(.userDetail(user)) // ✅ Shows back button
navGraph.presentSheet(.userDetail(user)) // ❌ Modal, no back button
```

## Performance Considerations

- NavGraph is lightweight and uses `@Observable` for efficient updates
- Navigation path is stored as an array, not recreated on each navigation
- Sheet and cover presentation is handled through optional bindings
- Analytics tracking is async and doesn't block navigation

## Summary

The NavGraph system provides:

✅ **Type-safe navigation** - Compile-time checking of routes  
✅ **Centralized control** - Single source of truth  
✅ **Testable** - Easy to mock and test  
✅ **Analytics integration** - Automatic tracking  
✅ **Clean API** - Intuitive methods  
✅ **Flexible** - Supports push, sheet, cover, alerts  
✅ **MVVM friendly** - ViewModels handle navigation logic  

---

**Created:** 2025/11/15  
**Status:** ✅ Production Ready
