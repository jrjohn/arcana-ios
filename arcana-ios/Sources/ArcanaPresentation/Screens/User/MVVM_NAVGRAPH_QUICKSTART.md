# Quick Start: MVVM + NavGraph

## 🚀 What You Got

### New Features
1. **MainViewModel** - Business logic separated from MainView
2. **NavGraph** - Centralized navigation system for entire app
3. **AppRoute** - Type-safe route definitions
4. **Updated ViewModels** - All support NavGraph navigation

## ⚡ Quick Setup (3 Steps)

### Step 1: Update Your App Entry Point

Find your `@main` struct and replace it with:

```swift
import SwiftUI
import SwiftData

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

### Step 2: Build & Run

That's it! Your app now uses:
- ✅ MVVM architecture
- ✅ Centralized navigation
- ✅ Type-safe routing

### Step 3: Test Navigation

Tap buttons in MainView:
- "Manage Users" → navigates to UserListView
- Settings icon → navigates to SettingsView

## 📱 How It Works

### Before
```swift
// Old way - state-based navigation
@State private var showUserList = false

Button("Manage Users") {
    showUserList = true
}
.navigationDestination(isPresented: $showUserList) {
    UserListView()
}
```

### After
```swift
// New way - NavGraph navigation
Button("Manage Users") {
    viewModel.send(.navigateToUserList)
}

// In ViewModel
func send(_ input: Input) {
    case .navigateToUserList:
        navGraph.navigateToUserList()
}
```

## 🎯 Navigation Patterns

### Push Navigation (Back Button)
```swift
navGraph.push(.userList)
navGraph.push(.userDetail(user))
// Result: MainView → UserList → UserDetail
```

### Sheet Presentation (Modal)
```swift
navGraph.presentSheet(.userForm(mode: .create))
navGraph.dismissSheet()
```

### Pop Navigation
```swift
navGraph.pop() // Go back one screen
navGraph.popToRoot() // Go back to main
```

### Alert
```swift
navGraph.showAlert(AlertConfig(
    title: "Error",
    message: "Something went wrong",
    primaryButton: .init(title: "OK")
))
```

## 📂 New Files Created

```
1. AppRoute.swift          - Route definitions
2. NavGraph.swift          - Navigation coordinator
3. MainViewModel.swift     - Main screen ViewModel
4. ArcanaAppWithNavigation.swift - App entry example
5. NAVIGATION_GUIDE.md     - Full documentation
6. MVVM_NAVGRAPH_SUMMARY.md - Detailed summary
7. MVVM_NAVGRAPH_QUICKSTART.md - This file
```

## 🔧 Files Modified

```
1. MainView.swift          - Uses MainViewModel
2. UserListViewModel.swift - Accepts NavGraph
3. UserFormViewModel.swift - Accepts NavGraph
```

## 💡 Common Tasks

### Navigate to User List
```swift
// In MainViewModel
viewModel.send(.navigateToUserList)
```

### Navigate to User Detail
```swift
// In UserListViewModel
viewModel.send(.selectUser(user))
```

### Present Create Form
```swift
// In UserListView (button action)
viewModel.send(.createUser)

// Or directly:
navGraph.presentCreateUserForm()
```

### Go Back
```swift
navGraph.pop()
```

### Go to Home
```swift
navGraph.popToRoot()
```

## 🧪 Testing

### Test ViewModel
```swift
import Testing

@Test
func testNavigateToUserList() {
    let navGraph = NavGraph()
    let viewModel = MainViewModel(navGraph: navGraph)
    
    viewModel.send(.navigateToUserList)
    
    #expect(navGraph.path.contains(.userList))
}
```

### Test in Preview
```swift
#Preview {
    let navGraph = NavGraph()
    NavigationStack {
        MainView(viewModel: MainViewModel(navGraph: navGraph))
    }
}
```

## 🎨 Preview Examples

### Basic Preview
```swift
#Preview {
    let navGraph = NavGraph()
    NavigationStack(path: .constant([])) {
        MainView(viewModel: MainViewModel(navGraph: navGraph))
            .navigationDestination(for: AppRoute.self) { route in
                NavGraphView.view(for: route, navGraph: navGraph)
            }
    }
}
```

### Preview with Navigation
```swift
#Preview("At User List") {
    let navGraph = NavGraph()
    navGraph.path = [.userList]
    
    return NavigationStack(path: .constant(navGraph.path)) {
        MainView(viewModel: MainViewModel(navGraph: navGraph))
            .navigationDestination(for: AppRoute.self) { route in
                NavGraphView.view(for: route, navGraph: navGraph)
            }
    }
}
```

## 🐛 Troubleshooting

### Issue: Navigation doesn't work
**Solution:** Make sure you have:
```swift
.navigationDestination(for: AppRoute.self) { route in
    NavGraphView.view(for: route, navGraph: navGraph)
}
```

### Issue: Back button doesn't appear
**Solution:** Use `push` instead of `presentSheet`:
```swift
navGraph.push(.userList) // ✅ Shows back button
navGraph.presentSheet(.userList) // ❌ Modal, no back
```

### Issue: ViewModel errors
**Solution:** Always pass NavGraph:
```swift
// ✅ Correct
MainViewModel(navGraph: navGraph)

// ❌ Wrong - will crash
MainViewModel() // NavGraph is required
```

## 📚 Learn More

- **Full Guide:** `NAVIGATION_GUIDE.md` - 500+ lines of documentation
- **Summary:** `MVVM_NAVGRAPH_SUMMARY.md` - Architecture details
- **Examples:** See preview code in each view file

## ✅ Checklist

Before running:
- [ ] Updated app entry point with NavGraph
- [ ] Clean build (Cmd+Shift+K)
- [ ] Rebuild (Cmd+B)

After running:
- [ ] MainView displays correctly
- [ ] "Manage Users" button navigates
- [ ] Settings button works
- [ ] Back button appears on pushed screens
- [ ] Create user form opens as sheet

## 🎉 Benefits

### Before
❌ Navigation logic scattered across views  
❌ Difficult to test  
❌ @State dependencies everywhere  
❌ Hard to track user flow  
❌ No analytics integration  

### After
✅ Centralized navigation  
✅ Easy to test  
✅ Clean separation of concerns  
✅ Type-safe routing  
✅ Automatic analytics  
✅ MVVM architecture  

## 📊 Architecture

```
App Launch
    ↓
ArcanaApp creates NavGraph
    ↓
NavigationStack with path binding
    ↓
MainView (with MainViewModel)
    ↓
User taps "Manage Users"
    ↓
ViewModel calls navGraph.navigateToUserList()
    ↓
NavGraph pushes .userList to path
    ↓
navigationDestination triggered
    ↓
UserListView displayed
```

## 🚀 Next Steps

### Add a New Screen

1. **Add route:**
```swift
// In AppRoute.swift
case analytics
```

2. **Add view:**
```swift
// In NavGraphView.swift
case .analytics:
    AnalyticsView(navGraph: navGraph)
```

3. **Navigate:**
```swift
navGraph.push(.analytics)
```

Done!

## 💻 Code Examples

### Navigate on Button Tap
```swift
Button("Go to Settings") {
    viewModel.send(.navigateToSettings)
}
```

### Navigate on List Selection
```swift
List(users) { user in
    UserCard(user: user)
        .onTapGesture {
            viewModel.send(.selectUser(user))
        }
}
```

### Present Modal Form
```swift
Button("Create User") {
    navGraph.presentCreateUserForm()
}
```

### Dismiss Modal
```swift
Button("Cancel") {
    navGraph.dismissSheet()
}
```

## 🎯 Key Concepts

### 1. AppRoute
Defines all screens in your app
```swift
enum AppRoute {
    case main
    case userList
    case userDetail(User)
}
```

### 2. NavGraph
Manages navigation state
```swift
@State private var navGraph = NavGraph()
```

### 3. Navigation Stack
Binds to NavGraph path
```swift
NavigationStack(path: $navGraph.path) { ... }
```

### 4. ViewModel
Handles navigation logic
```swift
func send(_ input: Input) {
    case .navigateToUserList:
        navGraph.navigateToUserList()
}
```

## ✨ That's It!

You now have a fully functional MVVM app with centralized navigation!

**Quick Links:**
- Full docs: `NAVIGATION_GUIDE.md`
- Examples: `MVVM_NAVGRAPH_SUMMARY.md`
- Code: See created files

---

**Status:** ✅ Ready to use  
**Setup Time:** 2 minutes  
**Complexity:** Low  
**Benefits:** High  
