# Swift Dependencies Integration Guide

## 🎯 Overview

The Arcana iOS project now uses [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) from Point-Free for dependency injection. This provides:

- ✅ **Type-safe** dependency injection
- ✅ **Compile-time** safety
- ✅ **Automatic** test mocks
- ✅ **SwiftUI Preview** support
- ✅ **No runtime** crashes
- ✅ **Minimal boilerplate**

## 📦 Package Integration

The package has been added to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.1.0"),
],

targets: [
    .target(
        name: "ArcanaCore",
        dependencies: [
            .product(name: "Dependencies", package: "swift-dependencies"),
        ]
    ),
]
```

## 🏗 Dependency Structure

### 1. Define Dependency Keys

Each dependency gets its own file in `Core/DI/`:

```swift
// UserServiceDependency.swift
import Dependencies

extension DependencyValues {
    var userService: UserService {
        get { self[UserServiceKey.self] }
        set { self[UserServiceKey.self] = newValue }
    }
}

private enum UserServiceKey: DependencyKey {
    // Production implementation
    static let liveValue: UserService = UserServiceImpl(...)
    
    // Test implementation (automatic mocks)
    static let testValue: UserService = MockUserService()
    
    // Preview implementation (SwiftUI previews)
    static let previewValue: UserService = MockUserService()
}
```

### 2. Use in ViewModels

ViewModels use `@Dependency` property wrapper:

```swift
import Dependencies

@MainActor
final class UserListViewModel: ObservableObject {
    @Dependency(\.userService) var userService
    @Dependency(\.analyticsTracker) var analyticsTracker
    
    init() {
        // Dependencies auto-injected!
    }
    
    func loadUsers() async {
        let users = try await userService.getUsers()
        // ...
    }
}
```

### 3. Use in Views

Views just create ViewModels normally:

```swift
struct UserListView: View {
    @StateObject private var viewModel = UserListViewModel()
    
    var body: some View {
        // ...
    }
}
```

## 📋 Available Dependencies

### UserService

**Location**: `Core/DI/UserServiceDependency.swift`

**Usage**:
```swift
@Dependency(\.userService) var userService

// Use it
let users = try await userService.getUsers()
let user = try await userService.createUser(newUser)
```

**Implementations**:
- `liveValue`: Real `UserServiceImpl` with repository
- `testValue`: `MockUserService` for testing
- `previewValue`: `MockUserService` for SwiftUI previews

### AnalyticsTracker

**Location**: `Core/DI/AnalyticsTrackerDependency.swift`

**Usage**:
```swift
@Dependency(\.analyticsTracker) var analyticsTracker

// Use it
analyticsTracker.trackEvent(.userCreated)
analyticsTracker.trackScreen("User List")
```

**Implementations**:
- `liveValue`: Real `PersistentAnalyticsTracker` (set at app launch)
- `testValue`: `MockAnalyticsTracker` for testing
- `previewValue`: `MockAnalyticsTracker` for SwiftUI previews

### UserRepository

**Location**: `Core/DI/UserRepositoryDependency.swift`

**Usage**:
```swift
@Dependency(\.userRepository) var repository

// Use it
let users = try await repository.getUsers()
```

**Implementations**:
- `liveValue`: Real `OfflineFirstUserRepository` (set at app launch)
- `testValue`: `MockUserRepository` for testing
- `previewValue`: `MockUserRepository` for SwiftUI previews

## 🎨 SwiftUI Previews

Previews automatically use `previewValue`:

```swift
#Preview {
    UserListView()
        // Uses MockUserService and MockAnalyticsTracker automatically!
}
```

To override dependencies in previews:

```swift
#Preview("With Specific Data") {
    UserListView()
        .dependency(\.userService, MockUserService(users: customUsers))
}
```

## 🧪 Testing

### Automatic Test Mocks

Tests automatically use `testValue`:

```swift
@MainActor
final class UserListViewModelTests: XCTestCase {
    func testLoadUsers() async {
        // Create ViewModel - gets MockUserService automatically
        let viewModel = UserListViewModel()
        
        // Test it
        viewModel.send(.loadInitial)
        
        // Verify
        XCTAssertEqual(viewModel.state.users.count, 5)
    }
}
```

### Custom Test Dependencies

Override dependencies for specific tests:

```swift
func testLoadUsers_withError() async throws {
    // Create custom mock
    let mockService = MockUserService()
    mockService.getUsersResult = .failure(someError)
    
    // Override dependency
    let viewModel = withDependencies {
        $0.userService = mockService
    } operation: {
        UserListViewModel()
    }
    
    // Test error handling
    viewModel.send(.loadInitial)
    
    XCTAssertNotNil(viewModel.state.errorMessage)
}
```

### Verify Mock Calls

```swift
func testTracksAnalytics() async throws {
    // Get mock tracker
    let mockTracker = MockAnalyticsTracker()
    
    let viewModel = withDependencies {
        $0.analyticsTracker = mockTracker
    } operation: {
        UserListViewModel()
    }
    
    viewModel.send(.loadInitial)
    
    // Verify tracking
    XCTAssertEqual(mockTracker.trackScreenCallCount, 1)
    XCTAssertEqual(mockTracker.lastScreen, "User List")
}
```

## 🚀 App Setup

### Initialize Live Dependencies

In your app entry point:

```swift
import SwiftUI
import SwiftData
import Dependencies

@main
struct ArcanaApp: App {
    let modelContainer: ModelContainer
    
    init() {
        // Setup SwiftData
        modelContainer = createModelContainer()
        
        // Setup live dependencies
        setupDependencies()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
    
    private func setupDependencies() {
        // Set up analytics tracker with real ModelContainer
        let analyticsTracker = PersistentAnalyticsTracker(
            modelContainer: modelContainer
        )
        
        // Set up data sources
        let localDataSource = SwiftDataUserDataSource(
            modelContainer: modelContainer,
            analyticsTracker: analyticsTracker
        )
        
        let remoteDataSource = MockRemoteUserDataSource()
        
        // Set up repository
        let repository = OfflineFirstUserRepository(
            localDataSource: localDataSource,
            remoteDataSource: remoteDataSource,
            analyticsTracker: analyticsTracker
        )
        
        // Set up service
        let userService = UserServiceImpl(
            repository: repository,
            analyticsTracker: analyticsTracker
        )
        
        // Register live values
        DependencyValues._current.userService = userService
        DependencyValues._current.analyticsTracker = analyticsTracker
        DependencyValues._current.userRepository = repository
    }
}
```

## 🔧 Advanced Usage

### Scoped Dependencies

Create dependencies for specific scopes:

```swift
struct DetailView: View {
    let user: User
    
    var body: some View {
        DetailContent()
            .dependency(\.currentUser, user)
    }
}
```

### Conditional Dependencies

Different implementations based on environment:

```swift
private enum UserServiceKey: DependencyKey {
    static var liveValue: UserService {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("MOCK_API") {
            return MockUserService()
        }
        #endif
        return UserServiceImpl(...)
    }
}
```

### Dependency Composition

Compose dependencies from other dependencies:

```swift
private enum UserServiceKey: DependencyKey {
    static var liveValue: UserService {
        @Dependency(\.userRepository) var repository
        @Dependency(\.analyticsTracker) var analyticsTracker
        
        return UserServiceImpl(
            repository: repository,
            analyticsTracker: analyticsTracker
        )
    }
}
```

## 📊 Benefits Over DIContainer

### Before (DIContainer)

```swift
// Manual setup required
let container = DIContainer.shared
container.configure(modelContainer: modelContainer)

// Manual injection
let viewModel = UserListViewModel(
    userService: container.userService,
    analyticsTracker: container.analyticsTracker
)

// Tests require manual mocks
let viewModel = UserListViewModel(
    userService: MockUserService(),
    analyticsTracker: MockAnalyticsTracker()
)
```

### After (swift-dependencies)

```swift
// Automatic setup
let viewModel = UserListViewModel()
// Dependencies auto-injected!

// Tests are automatic
let viewModel = UserListViewModel()
// Uses test mocks automatically!

// Previews are automatic
#Preview { UserListView() }
// Uses preview mocks automatically!
```

## 🎯 Migration Checklist

- [x] Add swift-dependencies to Package.swift
- [x] Create dependency keys (UserService, AnalyticsTracker, UserRepository)
- [x] Update ViewModels to use `@Dependency`
- [x] Update tests to use withDependencies
- [x] Update previews (they work automatically!)
- [x] Set up live values in app entry point
- [ ] Remove old DIContainer (optional)

## 📚 Resources

### Documentation
- [swift-dependencies GitHub](https://github.com/pointfreeco/swift-dependencies)
- [Point-Free Videos](https://www.pointfree.co/collections/dependencies)
- [API Documentation](https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/)

### Examples
- See `Core/DI/` for dependency definitions
- See `Presentation/Screens/User/UserListViewModel.swift` for usage
- See test files for testing examples

## 🎉 Summary

**swift-dependencies provides:**

✅ Type-safe dependency injection  
✅ Automatic test mocks  
✅ SwiftUI preview support  
✅ No boilerplate  
✅ Compile-time safety  
✅ Easy testing  
✅ Better than DIContainer  

**Usage is simple:**

```swift
// 1. Define dependency
extension DependencyValues {
    var myService: MyService {
        get { self[MyServiceKey.self] }
        set { self[MyServiceKey.self] = newValue }
    }
}

// 2. Use in ViewModel
@Dependency(\.myService) var myService

// 3. That's it! Tests and previews work automatically!
```

---

**Modern, type-safe dependency injection with zero boilerplate! 🚀**
