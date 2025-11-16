# swift-dependencies Quick Reference

## 📦 Setup (One Time)

```swift
// In your @main App
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
        }
        .modelContainer(modelContainer)
    }
}
```

## 🎯 Basic Usage

### In ViewModels

```swift
@MainActor
final class MyViewModel: ObservableObject {
    @Dependency(\.userService) var userService
    @Dependency(\.analyticsTracker) var tracker
    
    init() {}  // That's it!
}
```

### In Views

```swift
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        // Use viewModel
    }
}
```

## 🧪 Testing

### Automatic Mocks

```swift
func testSomething() async {
    let viewModel = MyViewModel()
    // Uses mocks automatically!
    
    await viewModel.loadData()
    XCTAssertFalse(viewModel.users.isEmpty)
}
```

### Custom Mocks

```swift
func testWithCustomMock() async {
    let mockService = MockUserService()
    mockService.getUsersResult = .failure(error)
    
    let viewModel = withDependencies {
        $0.userService = mockService
    } operation: {
        MyViewModel()
    }
    
    await viewModel.loadData()
    XCTAssertNotNil(viewModel.error)
}
```

## 🎨 SwiftUI Previews

### Automatic

```swift
#Preview {
    MyView()  // Uses preview mocks automatically!
}
```

### Custom Data

```swift
#Preview("Custom") {
    AppDependencies.withPreviewDependencies(
        mockUsers: customUsers
    ) {
        MyView()
    }
}
```

## 📋 Available Dependencies

```swift
@Dependency(\.userService) var userService
@Dependency(\.analyticsTracker) var tracker
@Dependency(\.userRepository) var repository
```

## 🔧 Creating New Dependencies

### 1. Define Key

```swift
// MyServiceDependency.swift
import Dependencies

extension DependencyValues {
    var myService: MyService {
        get { self[MyServiceKey.self] }
        set { self[MyServiceKey.self] = newValue }
    }
}

private enum MyServiceKey: DependencyKey {
    static let liveValue: MyService = MyServiceImpl()
    static let testValue: MyService = MockMyService()
    static let previewValue: MyService = MockMyService()
}
```

### 2. Use It

```swift
@Dependency(\.myService) var myService
```

## 💡 Pro Tips

### Verify Mocks

```swift
let mockTracker = MockAnalyticsTracker()

let viewModel = withDependencies {
    $0.analyticsTracker = mockTracker
} operation: {
    MyViewModel()
}

viewModel.doSomething()

XCTAssertEqual(mockTracker.trackEventCallCount, 1)
XCTAssertEqual(mockTracker.lastEvent, .somethingHappened)
```

### Override Multiple

```swift
withDependencies {
    $0.userService = mockService
    $0.analyticsTracker = mockTracker
    $0.userRepository = mockRepo
} operation: {
    // Use overrides
}
```

### Debug

```swift
#if DEBUG
AppDependencies.printDependencyInfo()
// 📦 Dependency Configuration:
//   UserService: UserServiceImpl
//   AnalyticsTracker: PersistentAnalyticsTracker
//   UserRepository: OfflineFirstUserRepository
#endif
```

## 🚫 What NOT to Do

```swift
// ❌ Don't create dependencies yourself
let service = UserServiceImpl()

// ✅ Use @Dependency instead
@Dependency(\.userService) var service

// ❌ Don't pass dependencies in init
init(userService: UserService) { ... }

// ✅ Inject automatically
@Dependency(\.userService) var userService
init() { }
```

## 📚 Resources

- **Full Guide**: `SWIFT_DEPENDENCIES_GUIDE.md`
- **Examples**: `Core/DI/*.swift`
- **Official**: https://github.com/pointfreeco/swift-dependencies

## 🎉 Cheat Sheet

```swift
// Define
extension DependencyValues {
    var myDep: MyType {
        get { self[MyKey.self] }
        set { self[MyKey.self] = newValue }
    }
}

// Use
@Dependency(\.myDep) var myDep

// Test
withDependencies {
    $0.myDep = mock
} operation: {
    // test
}

// Preview
#Preview {
    MyView()  // automatic!
}
```

---

**That's all you need! 🚀**
