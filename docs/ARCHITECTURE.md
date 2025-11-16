# Architecture Documentation

> Comprehensive guide to Arcana iOS application architecture

## Table of Contents

- [Overview](#overview)
- [Clean Architecture Layers](#clean-architecture-layers)
- [Data Flow](#data-flow)
- [Offline-First Strategy](#offline-first-strategy)
- [Pagination System](#pagination-system)
- [Dependency Injection](#dependency-injection)
- [Error Handling](#error-handling)
- [Analytics System](#analytics-system)
- [Testing Strategy](#testing-strategy)

---

## Overview

Arcana iOS follows **Clean Architecture** principles, separating concerns into distinct layers with clear boundaries. This ensures:

- ✅ **Testability** - Each layer can be tested independently
- ✅ **Maintainability** - Changes are localized to specific layers
- ✅ **Scalability** - Easy to add new features without breaking existing code
- ✅ **Independence** - Business logic has zero UI framework dependencies

### Architecture Principles

1. **Dependency Rule** - Dependencies point inward (Presentation → Domain → Data)
2. **Single Responsibility** - Each class/module has one reason to change
3. **Interface Segregation** - Protocol-based dependencies
4. **Dependency Inversion** - Depend on abstractions, not implementations

---

## Clean Architecture Layers

### 1. Presentation Layer (`ArcanaPresentation`)

**Responsibility**: Handle user interface and user interactions

```
ArcanaPresentation/
├── Screens/
│   ├── User/
│   │   ├── UserListView.swift          # SwiftUI view
│   │   ├── UserListViewModel.swift     # @Observable ViewModel
│   │   ├── UserFormView.swift
│   │   └── UserFormViewModel.swift
├── Components/
│   ├── AvatarView.swift                # Reusable components
│   ├── SyncStatusBanner.swift
│   └── UserStatisticsBanner.swift
└── Theme/
    └── ArcanaTheme.swift               # Colors, fonts, spacing
```

**Key Patterns**:
- **MVVM** - ViewModels manage state and business logic
- **Input/Output/Effect** - Structured communication pattern
- **SwiftUI Observation** - `@Observable` macro for reactivity

**Example**:
```swift
@MainActor
@Observable
final class UserListViewModel {
    enum Input {
        case loadInitial
        case loadNextPage
        case selectUser(User)
    }

    enum Effect {
        case showError(AppError)
        case navigateToDetail(User)
    }

    private(set) var users: [User] = []
    private(set) var isLoading: Bool = false

    @Dependency(\.userService) var userService

    func send(_ input: Input) { /* ... */ }
}
```

---

### 2. Domain Layer (`ArcanaDomain`)

**Responsibility**: Business logic, validation, and domain models

```
ArcanaDomain/
├── Model/
│   └── User.swift                    # Domain model
├── Service/
│   ├── UserService.swift            # Protocol
│   └── UserServiceImpl.swift        # Implementation
└── Validation/
    └── UserValidator.swift           # Input validation
```

**Key Principles**:
- **Zero Dependencies** - No UIKit, SwiftUI, SwiftData imports
- **Pure Swift** - Only Foundation and standard library
- **Value Objects** - Immutable domain models
- **Validation Logic** - Centralized input validation

**Example**:
```swift
protocol UserService {
    func getUsers() async throws -> [User]
    func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User>
    func createUser(_ user: User) async throws -> User
}

struct User: Identifiable, Codable, Sendable {
    let id: String
    var email: String
    var firstName: String
    var lastName: String
    var avatar: String
}
```

---

### 3. Data Layer (`ArcanaData`)

**Responsibility**: Data access, persistence, and API communication

```
ArcanaData/
├── Repository/
│   ├── UserRepository.swift            # Protocol
│   └── OfflineFirstUserRepository.swift # Implementation
├── Local/
│   ├── Entities/
│   │   ├── UserEntity.swift           # SwiftData model
│   │   ├── AnalyticsEventEntity.swift
│   │   └── PendingChangeEntity.swift  # Offline queue
│   └── DataSource/
│       └── SwiftDataUserDataSource.swift
└── Remote/
    ├── RemoteUserDataSource.swift     # Protocol
    ├── ReqresUserDataSource.swift     # API implementation
    └── MockRemoteUserDataSource.swift # Testing mock
```

**Key Patterns**:
- **Repository Pattern** - Abstract data sources
- **Offline-First** - Local database is source of truth
- **Data Source Pattern** - Separate local and remote data sources

**Example**:
```swift
final class OfflineFirstUserRepository: UserRepository {
    private let localDataSource: LocalUserDataSource
    private let remoteDataSource: RemoteUserDataSource
    private let cache: LRUCache<String, User>

    func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User> {
        do {
            // 1. Fetch from remote
            let result = try await remoteDataSource.getUsers(page: page, perPage: perPage)

            // 2. Update local database
            try await localDataSource.saveUsers(result.items)

            // 3. Update cache
            for user in result.items {
                cache.setValue(user, forKey: user.id)
            }

            return result
        } catch {
            // 4. Fallback to local on network error
            if case .networkError = AppError.from(error) {
                let localUsers = try await localDataSource.getUsers()
                // Return paginated local data...
            }
            throw error
        }
    }
}
```

---

## Data Flow

### 1. Read Flow (Get Users)

```
UI (UserListView)
    ↓ send(.loadInitial)
ViewModel (UserListViewModel)
    ↓ userService.getUsers(page:perPage:)
Service (UserServiceImpl)
    ↓ repository.getUsers(page:perPage:)
Repository (OfflineFirstUserRepository)
    ├─ Try Remote API
    │   ├─ Success → Save to Local → Update Cache → Return
    │   └─ Failure → Try Local → Return Cached Data
    └─ Return PaginatedResult<User>
        ↓
ViewModel updates @Observable state
        ↓
SwiftUI automatically re-renders view
```

### 2. Write Flow (Create User)

```
UI (UserFormView)
    ↓ send(.submit)
ViewModel (UserFormViewModel)
    ↓ Validate Input
    ↓ userService.createUser(user)
Service (UserServiceImpl)
    ↓ Validate User
    ↓ repository.createUser(user)
Repository (OfflineFirstUserRepository)
    ├─ Save to Local (Optimistic)
    ├─ Update Cache
    ├─ Try Remote API
    │   ├─ Success → Update Local with Server Response
    │   └─ Failure → Queue for Background Sync
    └─ Return Created User
        ↓
ViewModel updates state
        ↓
UI shows success/error
```

---

## Offline-First Strategy

### Architecture

```
┌─────────────────────────────────────────┐
│           User Action (CRUD)            │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│    1. Save to Local Database (Fast)     │
│    2. Update LRU Cache                  │
└──────────────┬──────────────────────────┘
               ↓
         ┌─────┴─────┐
         │           │
    Online?     Offline?
         │           │
         ↓           ↓
   Try Remote    Queue Change
      API        (SwiftData)
         │           │
         ↓           │
    Success?         │
    ├─ Yes ──────────┤
    │  Update Local  │
    │  with Server   │
    │  Response      │
    │                │
    └─ No            │
       Queue for     │
       Sync          │
         │           │
         └─────┬─────┘
               ↓
    ┌──────────────────────┐
    │  Network Restored?   │
    │  ├─ Monitor NWPath   │
    │  └─ Auto-sync Queue  │
    └──────────────────────┘
```

### Implementation Details

#### 1. Pending Change Queue

```swift
@Model
final class PendingChangeEntity {
    var id: String
    var userId: String
    var operation: String // "create", "update", "delete"
    var userDataJSON: String
    var timestamp: Date
    var retryCount: Int
    var lastError: String?
}
```

#### 2. Network Monitoring

```swift
@MainActor
final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected: Bool = true

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                if path.status == .satisfied {
                    // Trigger sync
                }
            }
        }
    }
}
```

#### 3. Background Sync

```swift
@MainActor
func processOfflineChanges() async {
    let pendingChanges = try? modelContext.fetch(FetchDescriptor<PendingChangeEntity>())

    for change in pendingChanges {
        do {
            switch change.operation {
            case "create": try await remoteDataSource.createUser(change.user)
            case "update": try await remoteDataSource.updateUser(change.user)
            case "delete": try await remoteDataSource.deleteUser(change.user)
            }
            modelContext.delete(change) // Success - remove from queue
        } catch {
            change.retryCount += 1
            if change.retryCount >= 3 {
                modelContext.delete(change) // Max retries exceeded
            }
        }
    }
}
```

---

## Pagination System

### Architecture

```
┌─────────────────────────────────────────┐
│        UserListView (SwiftUI)           │
│  ┌───────────────────────────────────┐  │
│  │  List {                           │  │
│  │    ForEach(users) { user in       │  │
│  │      UserCard(user)                │  │
│  │        .onAppear {                 │  │
│  │          if isLastItem {           │  │
│  │            loadNextPage()          │  │
│  │          }                          │  │
│  │        }                            │  │
│  │    }                                │  │
│  │    if isLoadingMore {               │  │
│  │      ProgressView()                 │  │
│  │    }                                │  │
│  │  }                                  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│       UserListViewModel                 │
│  - currentPage: Int = 1                 │
│  - totalPages: Int = 1                  │
│  - hasMorePages: Bool = false           │
│  - perPage: Int = 10                    │
│                                         │
│  func send(.loadNextPage) {             │
│    let result = userService             │
│      .getUsers(page: currentPage + 1)   │
│    users.append(result.items)           │
│    currentPage = result.currentPage     │
│    hasMorePages = result.hasMore        │
│  }                                      │
└─────────────────────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│       UserRepository                    │
│                                         │
│  func getUsers(page, perPage)           │
│    → PaginatedResult<User>              │
│                                         │
│  struct PaginatedResult<T> {            │
│    let items: [T]                       │
│    let currentPage: Int                 │
│    let totalPages: Int                  │
│    let hasMore: Bool                    │
│  }                                      │
└─────────────────────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│       API Service (Alamofire)           │
│  GET /users?page=2&per_page=10          │
│                                         │
│  Response: {                            │
│    "page": 2,                           │
│    "per_page": 10,                      │
│    "total": 50,                         │
│    "total_pages": 5,                    │
│    "data": [...]                        │
│  }                                      │
└─────────────────────────────────────────┘
```

### Key Features

1. **Lazy Loading** - Data loaded only when needed
2. **Infinite Scroll** - Automatic pagination on scroll
3. **Loading States** - Visual feedback during fetch
4. **Offline Support** - Cached pages available offline
5. **Statistics Banner** - Shows total loaded and page progress

---

## Dependency Injection

Using **swift-dependencies** for compile-time safe dependency injection:

### 1. Define Dependency

```swift
extension DependencyValues {
    var userService: UserService {
        get { self[UserServiceKey.self] }
        set { self[UserServiceKey.self] = newValue }
    }
}

private enum UserServiceKey: DependencyKey {
    static var liveValue: UserService {
        DependencyStorage.userService
    }
}
```

### 2. Setup in App

```swift
@main
struct ArcanaApp: App {
    let modelContainer: ModelContainer

    init() {
        modelContainer = AppDependencies.createModelContainer()
        AppDependencies.setup(modelContainer: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
```

### 3. Inject in ViewModel

```swift
@MainActor
@Observable
final class UserListViewModel {
    @Dependency(\.userService) var userService
    @Dependency(\.analyticsTracker) var analyticsTracker

    func loadUsers() async {
        let users = try await userService.getUsers()
    }
}
```

### 4. Override for Testing

```swift
func testUserList() {
    AppDependencies.withTestDependencies(
        userService: MockUserService()
    ) {
        let viewModel = UserListViewModel()
        // Test with mock service
    }
}
```

---

## Error Handling

### Centralized Error System

```swift
enum AppError: Error {
    case networkError(ErrorCode, message: String, isRetryable: Bool, underlyingError: Error?)
    case serverError(ErrorCode, statusCode: Int, message: String)
    case validationError(ErrorCode, field: String, message: String)
    case unknownError(ErrorCode, message: String, underlyingError: Error?)

    var errorCode: ErrorCode { /* ... */ }
    var message: String { /* ... */ }
    var isRetryable: Bool { /* ... */ }
}

enum ErrorCode: String {
    // Network errors
    case E1000_NO_CONNECTION
    case E1003_NETWORK_IO

    // Server errors
    case E3000_SERVER_ERROR
    case E3002_NOT_FOUND

    // Validation errors
    case E5000_INVALID_INPUT

    var code: String { rawValue }
}
```

### Error Tracking

```swift
do {
    try await userService.createUser(user)
} catch {
    let appError = AppError.from(error)
    analyticsTracker.trackAppError(appError, context: [
        "screen": "user_form",
        "operation": "createUser"
    ])
    onEffect?(.showError(appError))
}
```

---

## Analytics System

### Event Tracking

```swift
enum AnalyticsEvent: String {
    case appLaunched = "app_launched"
    case pageLoaded = "page_loaded"
    case userSelected = "user_selected"
    case userCreateSuccess = "user_create_success"
}

protocol AnalyticsTracker {
    func trackEvent(_ event: AnalyticsEvent, params: [String: Any])
    func trackScreen(_ screen: String, params: [String: Any])
    func trackError(_ error: Error, context: [String: Any])
}
```

### Persistent Storage

```swift
@Model
final class AnalyticsEventEntity {
    var id: String
    var eventName: String
    var parametersJSON: String
    var timestamp: Date
    var sessionId: String
    var isSynced: Bool
}
```

---

## Testing Strategy

### 1. Unit Tests

```swift
@Test func testUserValidation() {
    let result = UserValidator.validateEmail("invalid")
    #expect(result == .failure(.invalidEmail))
}
```

### 2. ViewModel Tests

```swift
@Test func testUserListLoading() async {
    let mockService = MockUserService()
    mockService.getUsersResult = .success([User.mock()])

    await AppDependencies.withTestDependencies(userService: mockService) {
        let viewModel = UserListViewModel()
        await viewModel.send(.loadInitial)

        #expect(viewModel.users.count == 1)
        #expect(!viewModel.isLoading)
    }
}
```

### 3. Integration Tests

```swift
@Test func testOfflineFirstFlow() async {
    let repository = OfflineFirstUserRepository(...)

    // Create user offline
    let user = try await repository.createUser(User.mock())

    // Verify queued for sync
    let pending = try modelContext.fetch(FetchDescriptor<PendingChangeEntity>())
    #expect(pending.count == 1)

    // Simulate network restored
    await repository.processOfflineChanges()

    // Verify synced
    let afterSync = try modelContext.fetch(FetchDescriptor<PendingChangeEntity>())
    #expect(afterSync.isEmpty)
}
```

---

## Best Practices

1. **Keep ViewModels Thin** - Business logic in Services
2. **Protocol-Based Design** - Easy mocking and testing
3. **Immutable Models** - Value types for thread safety
4. **Async/Await** - Modern concurrency patterns
5. **Actor Isolation** - @MainActor for UI, actors for data
6. **Sendable Conformance** - Thread-safe data passing
7. **Documentation** - Public APIs have DocC comments

---

## References

- [Clean Architecture (Uncle Bob)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [SwiftUI Observation](https://developer.apple.com/documentation/observation)
- [swift-dependencies](https://github.com/pointfreeco/swift-dependencies)
