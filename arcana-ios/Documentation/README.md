# Arcana iOS

A modern iOS application built with Clean Architecture, Offline-First design, and Comprehensive Analytics.

## 🎯 Overview

Arcana iOS is a production-ready iOS app that demonstrates best practices in iOS development:

- **Clean Architecture** - Separation of concerns with distinct layers
- **Offline-First** - Full functionality without internet connection
- **MVVM + Input/Output Pattern** - Predictable state management
- **Comprehensive Error Handling** - Standardized error codes (E####, W####)
- **Analytics Tracking** - Persistent event tracking with SwiftData
- **Modern SwiftUI** - Beautiful, responsive user interface

## 📋 Features

### Core Functionality
✅ User Management (CRUD operations)  
✅ Offline-First with smart caching  
✅ Real-time search and filtering  
✅ Form validation with error messages  
✅ SwiftData persistence  
✅ Comprehensive analytics tracking  
✅ Error code system for debugging  

### Architecture Highlights
- **Clean Architecture** with Data, Domain, and Presentation layers
- **Input/Output ViewModel Pattern** for predictable state management
- **LRU Cache** with TTL for optimal performance
- **Offline-First Repository** with automatic sync
- **Error Code System** for standardized error handling
- **Persistent Analytics** with SwiftData

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Presentation Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   SwiftUI    │→ │  ViewModels  │→ │  ViewStates  │       │
│  │    Views     │  │   (MVVM)     │  │  (Published) │       │
│  └──────┬───────┘  └──────────────┘  └──────────────┘       │
│         ↓                                                   │
│  ┌──────────────┐                                           │
│  │  Validation  │                                           │
│  │   & Value    │                                           │
│  │   Objects    │                                           │
│  └──────────────┘                                           │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Services   │→ │Business Logic│→ │Domain Models │       │
│  │  (Protocols) │  │  (Use Cases) │  │  (Structs)   │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ Repository   │→ │  SwiftData   │  │  URLSession  │       │
│  │(Offline-1st) │  │  (Local DB)  │  │   (Remote)   │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
ArcanaIOS/
├── Core/
│   ├── Analytics/          # Analytics tracking system
│   │   ├── AnalyticsEvent.swift
│   │   ├── AnalyticsTracker.swift
│   │   └── PersistentAnalyticsTracker.swift
│   ├── Common/             # Utilities, Extensions
│   │   ├── ErrorCode.swift
│   │   ├── AppError.swift
│   │   └── LRUCache.swift
│   └── DI/                 # Dependency Injection
│       └── DIContainer.swift
│
├── Data/                   # Data layer
│   ├── Local/              # SwiftData
│   │   ├── Entities/
│   │   │   ├── UserEntity.swift
│   │   │   └── AnalyticsEventEntity.swift
│   │   ├── LocalUserDataSource.swift
│   │   └── SwiftDataUserDataSource.swift
│   ├── Remote/             # Network data sources
│   │   ├── RemoteUserDataSource.swift
│   │   └── MockRemoteUserDataSource.swift
│   └── Repository/         # Repository implementations
│       ├── UserRepository.swift
│       └── OfflineFirstUserRepository.swift
│
├── Domain/                 # Business logic layer
│   ├── Model/              # Domain models
│   │   └── User.swift
│   ├── Service/            # Domain services
│   │   ├── UserService.swift
│   │   └── UserServiceImpl.swift
│   └── Validation/         # Input validators
│       └── UserValidator.swift
│
└── Presentation/           # Presentation layer
    ├── Screens/            # SwiftUI Views + ViewModels
    │   └── User/
    │       ├── UserListView.swift
    │       ├── UserListViewModel.swift
    │       ├── UserFormView.swift
    │       └── UserFormViewModel.swift
    ├── Components/         # Reusable UI components
    │   └── UserCard.swift
    └── Theme/              # UI theming
        └── ArcanaTheme.swift
```

## 🚀 Getting Started

### Prerequisites
- macOS 14.0+
- Xcode 15.0+
- iOS 16.0+ deployment target
- Swift 5.9+

### Installation

1. Clone the repository
2. Open `arcana-ios.xcodeproj` in Xcode
3. Build and run (⌘R)

### Quick Start

The app is ready to run out of the box with:
- Mock data pre-loaded
- Offline-first functionality
- Analytics tracking enabled
- Form validation working

## 🎨 Key Features Explained

### 1. Offline-First Architecture

The app works perfectly without internet:
- Data is cached using LRU cache with TTL
- SwiftData persists all user data locally
- Background sync when connection is restored

```swift
// Repository handles offline/online seamlessly
let users = try await userRepository.getUsers()
// Returns cached → local DB → remote (in that order)
```

### 2. Input/Output ViewModel Pattern

Clean separation of concerns in ViewModels:

```swift
@MainActor
final class UserListViewModel: ObservableObject {
    enum Input { case loadInitial, refresh, deleteUser(User) }
    struct Output { var users: [User], isLoading: Bool }
    enum Effect { case showError(AppError), showSuccess(String) }
    
    func send(_ input: Input) { ... }
}
```

### 3. Error Code System

Standardized error codes for debugging:

```swift
enum ErrorCode {
    case E1000_NO_CONNECTION      // Network errors
    case E2001_INVALID_EMAIL      // Validation errors
    case E3002_NOT_FOUND          // Server errors
    // ... and many more
}

// Usage:
catch {
    let appError = AppError.from(error)
    // [E1000] No internet connection available
}
```

### 4. Comprehensive Analytics

Track everything automatically:

```swift
analyticsTracker.trackEvent(.userCreateSuccess, params: [
    "userId": user.id,
    "email": user.email
])

analyticsTracker.trackAppError(appError, context: [
    "operation": "createUser"
])
```

### 5. Form Validation

Real-time validation with user-friendly errors:

```swift
let result = UserValidator.validateEmail(email)
// Shows: "Invalid email address format" if invalid
// Updates UI in real-time as user types
```

## 🎨 Design Theme

Arcana uses a beautiful purple gradient theme:

- **Primary Colors**: Purple (#667eea) to Violet (#764ba2)
- **Typography**: SF Rounded (system font)
- **Components**: Card-based design with shadows
- **Animations**: Smooth transitions and loading states

## 🧪 Testing

The architecture is designed for testability:

```swift
// Mock services for testing
class MockUserService: UserService { ... }
class MockAnalyticsTracker: AnalyticsTracker { ... }

// Use in tests or previews
let viewModel = UserListViewModel(
    userService: MockUserService(),
    analyticsTracker: MockAnalyticsTracker()
)
```

## 📊 Analytics Dashboard

The app includes an Analytics tab showing:
- Total events tracked
- Error events count
- Current session ID
- Ability to clear analytics data

## 🔒 Data Persistence

All data is persisted using SwiftData:
- **UserEntity** - User information
- **AnalyticsEventEntity** - Analytics events

Data survives app restarts and is synchronized when online.

## 🌐 Network Layer

Currently uses a mock data source for demonstration. To add real API:

1. Create `NetworkUserDataSource.swift`
2. Implement `RemoteUserDataSource` protocol
3. Replace `MockRemoteUserDataSource` in `DIContainer`

```swift
// Example:
class NetworkUserDataSource: RemoteUserDataSource {
    private let apiClient: URLSession
    private let baseURL = "https://api.example.com"
    
    func getUsers() async throws -> [User] {
        let url = URL(string: "\(baseURL)/users")!
        let (data, _) = try await apiClient.data(from: url)
        let dto = try JSONDecoder().decode([User.DTO].self, from: data)
        return try dto.map { try User.from(dto: $0) }
    }
}
```

## 🎯 Best Practices

This project demonstrates:

- ✅ Clean Architecture with clear layer separation
- ✅ SOLID principles throughout
- ✅ Protocol-oriented programming
- ✅ Dependency Injection for testability
- ✅ Async/await for modern concurrency
- ✅ SwiftUI best practices
- ✅ Error handling with typed errors
- ✅ Comprehensive logging and analytics
- ✅ Offline-first design patterns

## 📝 License

MIT License - Feel free to use this code for learning or production.

## 👨‍💻 Author

Created as a demonstration of iOS Clean Architecture best practices.

---

**Built with ❤️ using SwiftUI, SwiftData, and Clean Architecture**
