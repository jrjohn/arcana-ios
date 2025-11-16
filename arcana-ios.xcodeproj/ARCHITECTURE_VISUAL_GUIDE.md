# Arcana iOS - Architecture Visual Guide

## 🏗 Clean Architecture Flow

```
┌───────────────────────────────────────────────────────────────────────┐
│                        📱 PRESENTATION LAYER                           │
│                                                                       │
│  ┌──────────────────┐         ┌──────────────────┐                  │
│  │   UserListView   │────────▶│UserListViewModel │                  │
│  │   (SwiftUI)      │         │  Input/Output    │                  │
│  └──────────────────┘         └──────────────────┘                  │
│                                        │                              │
│                                        │ send(.loadInitial)           │
│                                        ▼                              │
└───────────────────────────────────────────────────────────────────────┘
                                         │
                                         │ service.getUsers()
                                         ▼
┌───────────────────────────────────────────────────────────────────────┐
│                         🎯 DOMAIN LAYER                                │
│                                                                       │
│  ┌──────────────────┐         ┌──────────────────┐                  │
│  │   UserService    │────────▶│  UserValidator   │                  │
│  │  (Business Logic)│         │  (Validation)    │                  │
│  └──────────────────┘         └──────────────────┘                  │
│           │                                                           │
│           │ repository.getUsers()                                    │
│           ▼                                                           │
└───────────────────────────────────────────────────────────────────────┘
                                         │
                                         │
                                         ▼
┌───────────────────────────────────────────────────────────────────────┐
│                          💾 DATA LAYER                                 │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │              OfflineFirstUserRepository                      │   │
│  │                                                               │   │
│  │  ┌───────────┐  ┌────────────┐  ┌─────────────────┐        │   │
│  │  │  1. Cache │→ │ 2. Local   │→ │ 3. Remote       │        │   │
│  │  │  LRU+TTL  │  │  SwiftData │  │  Network/Mock   │        │   │
│  │  └───────────┘  └────────────┘  └─────────────────┘        │   │
│  │                                                               │   │
│  │  Strategy: Cache → Local DB → Remote (fallback chain)       │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow Diagram

### Read Operation (Get Users)

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  User Taps                                                          │
│  "Users Tab"                                                        │
│       │                                                             │
│       ▼                                                             │
│  UserListView.onAppear()                                           │
│       │                                                             │
│       ▼                                                             │
│  viewModel.send(.loadInitial)                                      │
│       │                                                             │
│       ▼                                                             │
│  UserListViewModel.loadUsers()                                     │
│       │                                                             │
│       ├──────▶ state.isLoading = true                             │
│       │                                                             │
│       ▼                                                             │
│  userService.getUsers()                                            │
│       │                                                             │
│       ▼                                                             │
│  UserServiceImpl.getUsers()                                        │
│       │                                                             │
│       ├──────▶ analyticsTracker.track(.requestStarted)            │
│       │                                                             │
│       ▼                                                             │
│  repository.getUsers()                                             │
│       │                                                             │
│       ▼                                                             │
│  OfflineFirstUserRepository                                        │
│       │                                                             │
│       ├─▶ Check Cache ─────────────┐                              │
│       │   (5 min TTL)              │                              │
│       │                            │                              │
│       │   ┌────────────────────────┘                              │
│       │   │ Found? YES                                            │
│       │   └─▶ Return cached users                                 │
│       │       Start background sync                               │
│       │                                                             │
│       │   Found? NO ──▶ Continue                                  │
│       │                                                             │
│       ├─▶ Check Local DB ──────────┐                              │
│       │   (SwiftData)              │                              │
│       │                            │                              │
│       │   ┌────────────────────────┘                              │
│       │   │ Found? YES                                            │
│       │   └─▶ Update cache                                        │
│       │       Start background sync                               │
│       │       Return users                                        │
│       │                                                             │
│       │   Found? NO ──▶ Continue                                  │
│       │                                                             │
│       ├─▶ Fetch Remote ─────────────┐                             │
│       │   (API/Mock)               │                             │
│       │                            │                             │
│       │   ┌────────────────────────┘                              │
│       │   │ Success                                               │
│       │   ├─▶ Save to local DB                                    │
│       │   ├─▶ Update cache                                        │
│       │   └─▶ Return users                                        │
│       │                                                             │
│       │   Error (Offline)                                         │
│       │   └─▶ Return empty or cached                              │
│       │                                                             │
│       ▼                                                             │
│  Back to ViewModel                                                 │
│       │                                                             │
│       ├──────▶ state.users = users                                │
│       ├──────▶ state.isLoading = false                            │
│       └──────▶ analyticsTracker.track(.success)                   │
│                                                                     │
│  View Updates                                                      │
│       │                                                             │
│       └──────▶ Show user list                                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Write Operation (Create User)

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  User Fills Form                                                    │
│  & Taps "Create"                                                    │
│       │                                                             │
│       ▼                                                             │
│  FormViewModel.send(.submit)                                       │
│       │                                                             │
│       ├──────▶ Validate all fields                                │
│       │                                                             │
│       │   Email valid? ────────▶ NO ──▶ Show error                │
│       │   Name valid?                   Return                     │
│       │                                                             │
│       │   All valid ──▶ YES                                        │
│       │                                                             │
│       ▼                                                             │
│  userService.createUser(user)                                      │
│       │                                                             │
│       ├──────▶ Validate user                                       │
│       ├──────▶ analyticsTracker.track(.createClicked)             │
│       │                                                             │
│       ▼                                                             │
│  repository.createUser(user)                                       │
│       │                                                             │
│       ├─▶ 1. Save to Local DB                                     │
│       │      (Optimistic update)                                   │
│       │                                                             │
│       ├─▶ 2. Update Cache                                          │
│       │                                                             │
│       ├─▶ 3. Try Remote API                                        │
│       │      │                                                      │
│       │      ├─▶ Success                                           │
│       │      │   ├─▶ Update local with server response            │
│       │      │   └─▶ Return created user                          │
│       │      │                                                      │
│       │      └─▶ Error (Offline)                                   │
│       │          ├─▶ Keep local version                           │
│       │          ├─▶ Mark for sync                                │
│       │          └─▶ Return local user                            │
│       │                                                             │
│       ▼                                                             │
│  Back to ViewModel                                                 │
│       │                                                             │
│       ├──────▶ effects.send(.dismiss(user))                       │
│       └──────▶ analyticsTracker.track(.createSuccess)             │
│                                                                     │
│  View Dismisses                                                    │
│       │                                                             │
│       └──────▶ Call onSave(user)                                  │
│               Refresh list                                         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## 📊 Input/Output Pattern

### ViewModel Structure

```
┌────────────────────────────────────────────────────────────────┐
│                    UserListViewModel                           │
│                                                                │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  INPUT (User Actions)                                │    │
│  │                                                       │    │
│  │  enum Input {                                        │    │
│  │    case loadInitial        // On view appear        │    │
│  │    case refresh            // Pull to refresh       │    │
│  │    case selectUser(User)   // Tap on user          │    │
│  │    case deleteUser(User)   // Swipe to delete      │    │
│  │    case search(String)     // Search query          │    │
│  │    case retryLastOperation // Retry after error     │    │
│  │  }                                                   │    │
│  │                                                       │    │
│  │  func send(_ input: Input) { ... }                  │    │
│  └──────────────────────────────────────────────────────┘    │
│                           │                                   │
│                           │ Process                           │
│                           ▼                                   │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  OUTPUT (View State)                                 │    │
│  │                                                       │    │
│  │  struct Output {                                     │    │
│  │    var users: [User] = []                           │    │
│  │    var isLoading: Bool = false                      │    │
│  │    var isRefreshing: Bool = false                   │    │
│  │    var errorMessage: String?                        │    │
│  │    var searchQuery: String = ""                     │    │
│  │    var filteredUsers: [User] = []                   │    │
│  │  }                                                   │    │
│  │                                                       │    │
│  │  @Published private(set) var state = Output()       │    │
│  └──────────────────────────────────────────────────────┘    │
│                           │                                   │
│                           │ Triggers                          │
│                           ▼                                   │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  EFFECTS (Side Effects)                              │    │
│  │                                                       │    │
│  │  enum Effect {                                       │    │
│  │    case showError(AppError)      // Show alert      │    │
│  │    case showSuccess(String)      // Show toast      │    │
│  │    case navigateTo(Route)        // Navigate        │    │
│  │    case showConfirmation(User)   // Confirm dialog  │    │
│  │  }                                                   │    │
│  │                                                       │    │
│  │  let effects = PassthroughSubject<Effect, Never>()  │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Benefits

```
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   TESTABLE   │   │  PREDICTABLE │   │    CLEAR     │
├──────────────┤   ├──────────────┤   ├──────────────┤
│ • Mock inputs│   │ • One-way    │   │ • Explicit   │
│ • Verify     │   │   data flow  │   │   actions    │
│   outputs    │   │ • Known state│   │ • Obvious    │
│ • Check      │   │   changes    │   │   effects    │
│   effects    │   │ • No hidden  │   │ • Type-safe  │
│              │   │   mutations  │   │              │
└──────────────┘   └──────────────┘   └──────────────┘
```

## 🔐 Dependency Injection

```
┌─────────────────────────────────────────────────────────────────┐
│                       DIContainer                               │
│                       (Singleton)                               │
│                                                                 │
│  configure(modelContainer) ─┐                                  │
│                             │                                  │
│                             ▼                                  │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  1. Create Analytics                                 │     │
│  │     analyticsTracker = PersistentAnalyticsTracker()  │     │
│  └──────────────────────────────────────────────────────┘     │
│                             │                                  │
│                             ▼                                  │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  2. Create Data Sources                              │     │
│  │     localDataSource = SwiftDataUserDataSource()      │     │
│  │     remoteDataSource = MockRemoteUserDataSource()    │     │
│  └──────────────────────────────────────────────────────┘     │
│                             │                                  │
│                             ▼                                  │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  3. Create Repository                                │     │
│  │     userRepository = OfflineFirstUserRepository(     │     │
│  │       local, remote, analytics                       │     │
│  │     )                                                │     │
│  └──────────────────────────────────────────────────────┘     │
│                             │                                  │
│                             ▼                                  │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  4. Create Services                                  │     │
│  │     userService = UserServiceImpl(                   │     │
│  │       repository, analytics                          │     │
│  │     )                                                │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                 │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  Factory Methods                                     │     │
│  │                                                       │     │
│  │  makeUserListViewModel() -> UserListViewModel {      │     │
│  │    return UserListViewModel(                         │     │
│  │      userService: userService,                       │     │
│  │      analyticsTracker: analyticsTracker              │     │
│  │    )                                                 │     │
│  │  }                                                   │     │
│  │                                                       │     │
│  │  makeUserFormViewModel(mode) -> UserFormViewModel {  │     │
│  │    return UserFormViewModel(                         │     │
│  │      mode: mode,                                     │     │
│  │      userService: userService,                       │     │
│  │      analyticsTracker: analyticsTracker              │     │
│  │    )                                                 │     │
│  │  }                                                   │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 📈 Analytics Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  User Action (e.g., Create User)                               │
│       │                                                         │
│       ▼                                                         │
│  ViewModel tracks event                                        │
│       │                                                         │
│       ├──────▶ analyticsTracker.trackEvent(                    │
│       │         .userCreateClicked,                            │
│       │         params: ["email": user.email]                  │
│       │       )                                                 │
│       │                                                         │
│       ▼                                                         │
│  PersistentAnalyticsTracker                                    │
│       │                                                         │
│       ├─▶ Create AnalyticsEventEntity                          │
│       │   - id: UUID                                           │
│       │   - eventType: "EVENT"                                 │
│       │   - eventName: "user_create_clicked"                   │
│       │   - timestamp: Date()                                  │
│       │   - sessionId: [SESSION_ID]                            │
│       │   - params: {"email": "..."}                           │
│       │   - isSynced: false                                    │
│       │                                                         │
│       ├─▶ Save to SwiftData                                    │
│       │                                                         │
│       └─▶ Log to console                                       │
│           📊 Event tracked: user_create_clicked                │
│                                                                 │
│  Later: Query Analytics                                        │
│       │                                                         │
│       ├─▶ getEventsCount()                                     │
│       ├─▶ getErrorEvents()                                     │
│       ├─▶ getEvents(category: "User Action")                   │
│       └─▶ clearAllEvents()                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🎯 Summary

This architecture provides:

✅ **Testability** - Every layer is testable  
✅ **Maintainability** - Clear separation of concerns  
✅ **Scalability** - Easy to add features  
✅ **Flexibility** - Swap implementations easily  
✅ **Performance** - Caching and offline support  
✅ **Reliability** - Error handling everywhere  
✅ **Observability** - Comprehensive analytics  

---

**Clean Architecture + Offline-First + Modern Swift = Production-Ready App**
