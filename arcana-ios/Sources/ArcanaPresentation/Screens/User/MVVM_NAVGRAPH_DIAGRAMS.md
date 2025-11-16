# MVVM + NavGraph Architecture Diagrams

## System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        ArcanaApp (@main)                          │
│                                                                    │
│  • Creates ModelContainer                                         │
│  • Configures AppDependencies                                     │
│  • Creates NavGraph instance                                      │
│  • Sets up NavigationStack with path binding                      │
└────────────────────────┬───────────────────────────────────────────┘
                         │
                         │ Creates & owns
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│                          NavGraph                                 │
│                   (Navigation Coordinator)                        │
│                                                                   │
│  State:                                                           │
│  • path: [AppRoute]              ← Navigation stack              │
│  • presentedSheet: AppRoute?     ← Current sheet                 │
│  • presentedFullScreenCover: AppRoute?                           │
│  • alertToShow: AlertConfig?                                     │
│                                                                   │
│  Methods:                                                         │
│  • push(_ route: AppRoute)                                       │
│  • pop(), popToRoot(), popTo(_ route)                           │
│  • presentSheet(_ route), dismissSheet()                         │
│  • presentFullScreenCover(_ route), dismissFullScreenCover()    │
│  • showAlert(_ config), dismissAlert()                           │
│  • navigateToUserList(), navigateToUserDetail(_ user), etc.     │
└────────────────────────┬───────────────────────────────────────────┘
                         │
                         │ Passed to
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌───────────────┐ ┌──────────────┐ ┌──────────────┐
│ MainViewModel │ │UserListModel │ │UserFormModel │
│               │ │              │ │              │
│ Owns NavGraph │ │Owns NavGraph │ │Owns NavGraph │
└───────┬───────┘ └──────┬───────┘ └──────┬───────┘
        │                │                │
        │ Used by        │ Used by        │ Used by
        ▼                ▼                ▼
┌───────────────┐ ┌──────────────┐ ┌──────────────┐
│   MainView    │ │ UserListView │ │ UserFormView │
│   (SwiftUI)   │ │  (SwiftUI)   │ │  (SwiftUI)   │
└───────────────┘ └──────────────┘ └──────────────┘
```

## Navigation Flow

```
App Launch
    │
    ▼
┌─────────────────────────────────────────┐
│           MainView                      │
│  ┌─────────────────────────────────┐   │
│  │  ✨ Arcana ✨                  │   │
│  │  Mystical User Management       │   │
│  │                                 │   │
│  │  ┌───────────────────────────┐ │   │
│  │  │    Total Users: 12        │ │   │
│  │  └───────────────────────────┘ │   │
│  │                                 │   │
│  │  [Manage Users Button]          │   │
│  └─────────────────────────────────┘   │
└───────────┬─────────────────────────────┘
            │
            │ navGraph.push(.userList)
            ▼
┌─────────────────────────────────────────┐
│         UserListView                    │
│  ┌─────────────────────────────────┐   │
│  │  🔍 Search...                   │   │
│  ├─────────────────────────────────┤   │
│  │  👤 Alice Smith                 │───┼──┐
│  │  👤 Bob Johnson                 │   │  │ Tap user
│  │  👤 Carol Williams              │   │  │
│  ├─────────────────────────────────┤   │  │
│  │  [➕] [🔄] [✏️] [🗑️]           │   │  │
│  └─────────────────────────────────┘   │  │
└───────────┬─────────────────────────────┘  │
            │                                 │
            │ Tap Create                      │ navGraph.push(
            │ navGraph.presentSheet(...)      │   .userDetail(user))
            ▼                                 ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│   UserFormView (Sheet)  │     │    UserDetailView       │
│  ┌───────────────────┐  │     │  ┌───────────────────┐  │
│  │  Create User      │  │     │  │  Alice Smith      │  │
│  │                   │  │     │  │  alice@...        │  │
│  │  First Name: __   │  │     │  │                   │  │
│  │  Last Name:  __   │  │     │  │  [Edit] [Delete]  │  │
│  │  Email:      __   │  │     │  └───────────────────┘  │
│  │                   │  │     └─────────────────────────┘
│  │  [Cancel] [Save]  │  │
│  └───────────────────┘  │
└─────────────────────────┘
```

## MVVM Pattern Flow

```
User Action (Button Tap)
         │
         ▼
┌────────────────────────┐
│       View             │
│                        │
│  Button("Manage") {    │
│    viewModel.send(     │
│      .navigateToList   │
│    )                   │
│  }                     │
└───────────┬────────────┘
            │
            │ Input
            ▼
┌────────────────────────┐
│     ViewModel          │
│                        │
│  func send(_ input) {  │
│    switch input {      │
│    case .navigate:     │
│      navGraph.push()   │
│      analytics.track() │
│      loadData()        │
│    }                   │
│  }                     │
└───────────┬────────────┘
            │
            ├──────────────┐
            │              │
            ▼              ▼
┌──────────────┐  ┌───────────────┐
│  NavGraph    │  │  Service      │
│              │  │               │
│  push(.list) │  │  getUsers()   │
└──────┬───────┘  └───────┬───────┘
       │                  │
       │                  │ Result
       ▼                  ▼
┌────────────────────────────┐
│     ViewModel State        │
│                            │
│  @Published state          │
│  • users: [User]           │
│  • isLoading: Bool         │
│  • error: String?          │
└──────────┬─────────────────┘
           │
           │ State change
           │ (Auto-updates)
           ▼
┌────────────────────────┐
│       View             │
│                        │
│  if viewModel.isLoading│
│    ProgressView()      │
│  else                  │
│    List(users)         │
└────────────────────────┘
```

## Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    Swift Dependencies                         │
│                                                               │
│  DependencyValues:                                            │
│  • userService: UserService                                   │
│  • analyticsTracker: AnalyticsTracker                         │
│  • userRepository: UserRepository                             │
└────────────────────────┬──────────────────────────────────────┘
                         │
                         │ Injected into
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                     ViewModels                                │
│                                                               │
│  @Dependency(\.userService) var userService                   │
│  @Dependency(\.analyticsTracker) var analyticsTracker         │
└────────────────────────┬──────────────────────────────────────┘
                         │
                         │ Uses services
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                    Data Layer                                 │
│                                                               │
│  ┌─────────────────┐  ┌──────────────────┐  ┌──────────────┐│
│  │  UserService    │  │  AnalyticsTracker │  │ Repository   ││
│  ├─────────────────┤  ├──────────────────┤  ├──────────────┤│
│  │ • getUsers()    │  │ • trackEvent()   │  │ • fetch()    ││
│  │ • createUser()  │  │ • trackScreen()  │  │ • save()     ││
│  │ • updateUser()  │  │ • trackError()   │  │ • delete()   ││
│  │ • deleteUser()  │  └──────────────────┘  └──────────────┘│
│  └─────────────────┘                                          │
└────────────────────────┬──────────────────────────────────────┘
                         │
                         │ Persists to
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                   SwiftData / CoreData                        │
│                                                               │
│  ModelContainer                                               │
│  • UserEntity                                                 │
│  • AnalyticsEventEntity                                       │
└──────────────────────────────────────────────────────────────┘
```

## Navigation Types

### Push Navigation (Stack-based)

```
Start: MainView
         │
         │ navGraph.push(.userList)
         ▼
      UserListView
         │
         │ navGraph.push(.userDetail(user))
         ▼
     UserDetailView
         │
         │ navGraph.pop()
         ▼
      UserListView
         │
         │ navGraph.popToRoot()
         ▼
      MainView
```

### Sheet Presentation (Modal)

```
      UserListView
         │
         │ navGraph.presentSheet(.userForm(mode: .create))
         ▼
┌────────────────────────┐
│   UserFormView         │ ← Sheet
│   (Modal overlay)      │
│                        │
│   [Cancel]    [Save]   │
└────────────────────────┘
         │
         │ navGraph.dismissSheet()
         ▼
      UserListView
```

### Full Screen Cover

```
      MainView
         │
         │ navGraph.presentFullScreenCover(.onboarding)
         ▼
╔════════════════════════╗
║   OnboardingView       ║ ← Full screen
║   (Covers everything)  ║
║                        ║
║   [Get Started]        ║
╚════════════════════════╝
         │
         │ navGraph.dismissFullScreenCover()
         ▼
      MainView
```

## State Management Flow

```
┌──────────────────────────────────────────────────────────────┐
│                  ViewModel (@Observable)                      │
│                                                               │
│  @Observable                                                  │
│  final class MainViewModel {                                  │
│                                                               │
│    // State (automatically published)                         │
│    private(set) var userCount: Int = 0                        │
│    private(set) var isLoading: Bool = false                   │
│    private(set) var errorMessage: String?                     │
│                                                               │
│    // Input handler                                           │
│    func send(_ input: Input) {                                │
│      Task {                                                   │
│        await handle(input)                                    │
│      }                                                        │
│    }                                                          │
│                                                               │
│    // Private logic                                           │
│    private func handle(_ input: Input) async {                │
│      switch input {                                           │
│      case .loadData:                                          │
│        isLoading = true  ─────────────────┐                  │
│        // Fetch data                      │                  │
│        isLoading = false ─────────────────┤                  │
│      }                                     │                  │
│    }                                       │                  │
│  }                                         │                  │
└────────────────────────────────────────────┼──────────────────┘
                                             │
                                             │ State change
                                             │ triggers view update
                                             ▼
┌──────────────────────────────────────────────────────────────┐
│                     View (SwiftUI)                            │
│                                                               │
│  struct MainView: View {                                      │
│    @State private var viewModel: MainViewModel               │
│                                                               │
│    var body: some View {                                      │
│      // Automatically re-renders when state changes           │
│      if viewModel.isLoading {                                 │
│        ProgressView()                                         │
│      } else {                                                 │
│        Text("\(viewModel.userCount)")                         │
│      }                                                        │
│    }                                                          │
│  }                                                            │
└──────────────────────────────────────────────────────────────┘
```

## Error Handling Flow

```
User Action
    │
    ▼
ViewModel.send(.loadData)
    │
    ▼
try await userService.getUsers()
    │
    ├─ Success ───────────────────┐
    │                             │
    │                             ▼
    │                    users = fetchedUsers
    │                    isLoading = false
    │                             │
    │                             ▼
    │                         View updates
    │                         Shows user list
    │
    └─ Error ────────────────────┐
                                 │
                                 ▼
                       catch let error as AppError
                                 │
                                 ▼
                       errorMessage = error.userMessage
                       isLoading = false
                       analyticsTracker.trackError(error)
                                 │
                                 ▼
                         View updates
                         Shows error view
                                 │
                                 ▼
                         [Retry Button]
                                 │
                                 │ User taps
                                 ▼
                       viewModel.send(.retry)
                                 │
                                 ▼
                         Try again...
```

## Component Relationships

```
┌─────────────────────────────────────────────────────────────────┐
│                        App Layer                                 │
│                                                                  │
│  ArcanaApp                                                       │
│  ├─ Creates NavGraph                                             │
│  ├─ Sets up NavigationStack                                      │
│  ├─ Configures Dependencies                                      │
│  └─ Provides ModelContainer                                      │
└──────────────────────┬───────────────────────────────────────────┘
                       │
┌──────────────────────┼───────────────────────────────────────────┐
│                      │   Presentation Layer                       │
│                      │                                            │
│  Views               │   ViewModels                               │
│  ├─ MainView ────────┼── MainViewModel                            │
│  ├─ UserListView ────┼── UserListViewModel                        │
│  └─ UserFormView ────┼── UserFormViewModel                        │
│                      │                                            │
│  All views display   │   All viewModels contain:                  │
│  state from their    │   • Business logic                         │
│  viewModels          │   • State management                       │
│                      │   • Navigation calls                       │
│                      │   • Service calls                          │
└──────────────────────┼───────────────────────────────────────────┘
                       │
┌──────────────────────┼───────────────────────────────────────────┐
│                      │   Domain Layer                             │
│                      │                                            │
│  Models              │   Navigation                               │
│  ├─ User             │   ├─ AppRoute                              │
│  ├─ AppError         │   ├─ NavGraph                              │
│  └─ AnalyticsEvent   │   └─ NavGraphView                          │
└──────────────────────┼───────────────────────────────────────────┘
                       │
┌──────────────────────┼───────────────────────────────────────────┐
│                      │   Data Layer                               │
│                      │                                            │
│  Services            │   Repositories                             │
│  ├─ UserService ─────┼── UserRepository                           │
│  └─ Analytics... ────┼── AnalyticsRepository                      │
│                      │                                            │
│  Entities (SwiftData)│                                            │
│  ├─ UserEntity       │                                            │
│  └─ AnalyticsEventEntity                                          │
└──────────────────────┴───────────────────────────────────────────┘
```

## Sequence Diagram: Navigate to User List

```
User        MainView    MainViewModel    NavGraph    NavigationStack
 │              │              │             │              │
 │─Tap Button─> │              │             │              │
 │              │─send(.navigate)            │              │
 │              │              │             │              │
 │              │       handle input         │              │
 │              │              │             │              │
 │              │        track analytics     │              │
 │              │              │             │              │
 │              │              │─push(.userList)            │
 │              │              │             │              │
 │              │              │       append to path       │
 │              │              │             │              │
 │              │              │             │──path changed─>│
 │              │              │             │              │
 │              │              │             │  navigationDestination
 │              │              │             │  triggered
 │              │              │             │              │
 │              │              │             │<─show UserListView─
 │              │              │             │              │
 │<─────────────────────────────────────────────UserListView shown
```

## File Structure

```
arcana-ios/
├── App/
│   └── ArcanaAppWithNavigation.swift
├── Navigation/
│   ├── AppRoute.swift
│   ├── NavGraph.swift
│   └── NavGraphView (in NavGraph.swift)
├── Features/
│   ├── Main/
│   │   ├── MainView.swift
│   │   └── MainViewModel.swift
│   ├── UserList/
│   │   ├── UserListView.swift
│   │   └── UserListViewModel.swift
│   └── UserForm/
│       ├── UserFormView.swift
│       └── UserFormViewModel.swift
├── Models/
│   ├── User.swift
│   ├── AppError.swift
│   └── AnalyticsEvent.swift
├── Services/
│   ├── UserService.swift
│   └── AnalyticsTracker.swift
└── Documentation/
    ├── NAVIGATION_GUIDE.md
    ├── MVVM_NAVGRAPH_SUMMARY.md
    ├── MVVM_NAVGRAPH_QUICKSTART.md
    └── MVVM_NAVGRAPH_DIAGRAMS.md (this file)
```

---

**Created:** 2025/11/15  
**Purpose:** Visual reference for architecture  
**Status:** ✅ Complete
