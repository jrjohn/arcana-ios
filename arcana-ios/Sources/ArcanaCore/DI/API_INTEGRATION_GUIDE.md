# API Service Integration Guide

This guide explains how to use the real API service with reqres.in for user management in the Arcana iOS app.

## Overview

The app now includes a complete REST API integration using Alamofire to connect to the reqres.in API at `https://reqres.in/api/users`.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         App Layer                            │
│                    (ViewModels, Views)                       │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      UserService                             │
│                   (Business Logic)                           │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  OfflineFirstUserRepository                  │
│              (Offline-first Strategy)                        │
└───────┬─────────────────────────────────────────────┬───────┘
        │                                              │
        ▼                                              ▼
┌──────────────────────┐                  ┌──────────────────────┐
│  LocalDataSource     │                  │ RemoteDataSource     │
│  (SwiftData)         │                  │ (ReqresUserDataSource)│
└──────────────────────┘                  └───────────┬──────────┘
                                                      │
                                                      ▼
                                          ┌──────────────────────┐
                                          │    ApiService        │
                                          │   (Alamofire)        │
                                          └───────────┬──────────┘
                                                      │
                                                      ▼
                                          ┌──────────────────────┐
                                          │   reqres.in API      │
                                          │ https://reqres.in    │
                                          └──────────────────────┘
```

## Components

### 1. ApiService

The core REST API client built with Alamofire.

**Features:**
- ✅ Full CRUD operations (Create, Read, Update, Delete)
- ✅ Pagination support for user lists
- ✅ Automatic retry on network failures (up to 3 times)
- ✅ Request/Response interceptors for logging
- ✅ Type-safe response models
- ✅ Swift Concurrency (async/await)

**Endpoints Implemented:**

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/users?page={page}` | Get paginated user list |
| GET | `/api/users/{id}` | Get single user |
| POST | `/api/users` | Create new user |
| PUT | `/api/users/{id}` | Update user (full) |
| PATCH | `/api/users/{id}` | Update user (partial) |
| DELETE | `/api/users/{id}` | Delete user |

### 2. ReqresUserDataSource

Implementation of `RemoteUserDataSource` protocol that uses `ApiService`.

**Features:**
- ✅ Converts between reqres.in API models and app User models
- ✅ Fetches all pages automatically
- ✅ Analytics tracking for all API calls
- ✅ Error mapping to AppError types
- ✅ ISO8601 date parsing

### 3. Response Models

Type-safe models for API responses:

```swift
struct UsersListResponse: Codable {
    let page: Int
    let perPage: Int
    let total: Int
    let totalPages: Int
    let data: [ReqresUser]
}

struct ReqresUser: Codable {
    let id: Int
    let email: String
    let firstName: String
    let lastName: String
    let avatar: String
}
```

## Configuration

### Enable Real API

In your `AppDelegate` or app initialization:

```swift
// Use real API (default)
AppDependencies.setup(modelContainer: sharedModelContainer, useRealAPI: true)

// Use mock API for testing
AppDependencies.setup(modelContainer: sharedModelContainer, useRealAPI: false)
```

### Custom API Base URL

If you want to use a different API endpoint:

```swift
let apiService = ApiService(baseURL: "https://your-api.com/api")
let remoteDataSource = ReqresUserDataSource(
    apiService: apiService,
    analyticsTracker: analyticsTracker
)
```

## Usage Examples

### Get All Users

```swift
let apiService = ApiService()

// Get first page
let response = try await apiService.getUsers(page: 1, perPage: 6)
print("Total users: \(response.total)")
print("Users on this page: \(response.data.count)")

// Convert to app User models
let users = response.data.map { $0.toUser() }
```

### Get Single User

```swift
let response = try await apiService.getUser(id: "2")
let user = response.data.toUser()
print("User: \(user.fullName)")
```

### Create User

```swift
let response = try await apiService.createUser(
    name: "John Doe",
    job: "Developer"
)
print("Created user with ID: \(response.id)")
```

### Update User

```swift
// Full update (PUT)
let response = try await apiService.updateUser(
    id: "2",
    name: "Jane Smith",
    job: "Senior Developer"
)

// Partial update (PATCH)
let response = try await apiService.patchUser(
    id: "2",
    name: "Jane Smith",
    job: nil // Don't update job
)
```

### Delete User

```swift
try await apiService.deleteUser(id: "2")
// Returns 204 No Content on success
```

## Error Handling

### API Errors

The API service maps errors to AppError types:

```swift
do {
    let users = try await userService.getUsers()
} catch let error as AppError {
    switch error.code {
    case .E2001_NETWORK:
        print("Network connection failed")
    case .E2002_SERVER:
        print("Server error")
    case .E3002_NOT_FOUND:
        print("User not found")
    case .E1003_PARSING:
        print("Failed to parse response")
    default:
        print("Unknown error: \(error.message)")
    }
}
```

### Automatic Retry

Network errors are automatically retried up to 3 times with 1-second delays:

```swift
// ApiInterceptor handles retries automatically
func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
    guard request.retryCount < 3 else {
        completion(.doNotRetry)
        return
    }
    
    if let afError = error.asAFError, afError.isSessionTaskError {
        completion(.retryWithDelay(1.0))
    } else {
        completion(.doNotRetry)
    }
}
```

## Analytics Tracking

All API calls are automatically tracked:

```swift
// Request started
analyticsTracker.trackEvent(.apiRequestStarted, params: [
    "endpoint": "GET /users",
    "source": "reqres.in"
])

// Request succeeded
analyticsTracker.trackEvent(.apiRequestSucceeded, params: [
    "endpoint": "GET /users",
    "user_count": 12
])

// Request failed
analyticsTracker.trackError(error, context: [
    "endpoint": "GET /users",
    "operation": "getUsers"
])
```

## Offline-First Strategy

The app uses an offline-first architecture:

1. **Read Operations**: Check local cache first, then fetch from API
2. **Write Operations**: Save locally immediately, sync with API in background
3. **Sync**: Periodic background sync to keep data fresh

```swift
// OfflineFirstUserRepository handles this automatically
let users = try await repository.getUsers()
// 1. Returns cached users immediately if available
// 2. Fetches fresh data from API in background
// 3. Updates cache with new data
```

## Testing

### Unit Tests

```swift
func testGetUsers() async throws {
    let apiService = ApiService()
    let response = try await apiService.getUsers(page: 1)
    
    XCTAssertGreaterThan(response.total, 0)
    XCTAssertFalse(response.data.isEmpty)
}
```

### Mock API for Development

```swift
// In AppDependencies.swift
AppDependencies.setup(modelContainer: container, useRealAPI: false)

// Uses MockRemoteUserDataSource with simulated delays
```

## Pagination

The `ReqresUserDataSource` automatically fetches all pages:

```swift
func getUsers() async throws -> [User] {
    var allUsers: [User] = []
    var currentPage = 1
    var hasMorePages = true
    
    while hasMorePages {
        let response = try await apiService.getUsers(page: currentPage)
        let users = response.data.map { $0.toUser() }
        allUsers.append(contentsOf: users)
        
        hasMorePages = currentPage < response.totalPages
        currentPage += 1
    }
    
    return allUsers
}
```

## Best Practices

### 1. Use Repository Pattern

Always access data through the repository, not directly from the API:

```swift
// ✅ Good
let users = try await userRepository.getUsers()

// ❌ Bad
let response = try await apiService.getUsers()
```

### 2. Handle Errors Gracefully

```swift
do {
    let users = try await userService.getUsers()
    self.users = users
} catch {
    self.errorMessage = "Failed to load users"
    analyticsTracker.trackError(error)
}
```

### 3. Use Swift Concurrency

```swift
func loadUsers() async {
    isLoading = true
    defer { isLoading = false }
    
    do {
        users = try await userService.getUsers()
    } catch {
        handleError(error)
    }
}
```

## Limitations

### reqres.in API Constraints

- **Data Reset**: Created/updated/deleted users are not persisted (it's a test API)
- **Pagination**: Maximum 6 users per page
- **Rate Limiting**: May have rate limits (not documented)
- **No Authentication**: No authentication required

### Workarounds

The app uses SwiftData for local persistence, so:
- Created users are saved locally
- Updates are persisted locally
- Deletions are tracked locally
- Offline mode provides full functionality

## Troubleshooting

### Network Not Available

```swift
// The app automatically falls back to local data
let users = try await userService.getUsers()
// Returns cached users if network unavailable
```

### API Rate Limit

```swift
catch let error as AppError where error.code == .E2002_SERVER {
    // Wait and retry
    try await Task.sleep(for: .seconds(5))
    try await userService.refreshUsers()
}
```

### Invalid Response

```swift
catch let error as AppError where error.code == .E1003_PARSING {
    // Log the error and use cached data
    analyticsTracker.trackError(error)
    return cachedUsers
}
```

## Migration from Mock to Real API

To migrate from mock API to real API:

1. **Update AppDependencies.swift**:
   ```swift
   AppDependencies.setup(modelContainer: container, useRealAPI: true)
   ```

2. **No code changes needed** - the repository pattern abstracts the data source

3. **Test thoroughly** - ensure error handling works correctly

## Related Files

- `ApiService.swift` - REST API client
- `ReqresUserDataSource.swift` - Remote data source implementation
- `RemoteUserDataSource.swift` - Protocol definition
- `OfflineFirstUserRepository.swift` - Offline-first repository
- `AppDependencies.swift` - Dependency configuration
- `AnalyticsEvent.swift` - Analytics events including API tracking

## Further Reading

- [Alamofire Documentation](https://github.com/Alamofire/Alamofire)
- [reqres.in API Documentation](https://reqres.in/api-docs/)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Offline-First Architecture](https://offlinefirst.org/)
