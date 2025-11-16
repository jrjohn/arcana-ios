# Contributing to Arcana iOS

Thank you for your interest in contributing to Arcana iOS! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Documentation](#documentation)

---

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

---

## Getting Started

### Prerequisites

- **Xcode** 16.0 or later
- **iOS** 18.0+ deployment target
- **Swift** 6.0+
- **Git** for version control
- **Node.js** (for documentation generation)

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/arcana-ios.git
   cd arcana-ios
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/arcana-ios.git
   ```

---

## Development Setup

### 1. Install Dependencies

```bash
# Install npm dependencies for documentation
npm install

# Open Xcode project
open arcana-ios.xcodeproj
```

### 2. Build the Project

```bash
xcodebuild -project arcana-ios.xcodeproj -scheme arcana-ios -destination 'platform=iOS Simulator,name=iPhone 17' build
```

### 3. Run Tests

```bash
xcodebuild test -project arcana-ios.xcodeproj -scheme arcana-ios -destination 'platform=iOS Simulator,name=iPhone 17'
```

### 4. Generate Documentation

```bash
# Generate Mermaid diagrams
npm run generate-diagrams

# Generate API documentation
xcodebuild docbuild -scheme arcana-ios
```

---

## Project Structure

```
arcana-ios/
├── arcana-ios/Sources/
│   ├── ArcanaCore/          # Core infrastructure
│   ├── ArcanaDomain/        # Business logic
│   ├── ArcanaData/          # Data layer
│   └── ArcanaPresentation/  # UI layer
├── docs/                    # Documentation
│   ├── api/                 # Generated API docs
│   ├── architecture/        # Mermaid diagrams
│   └── diagrams/            # Generated PNG diagrams
└── Tests/                   # Unit and integration tests
```

### Module Responsibilities

- **ArcanaCore**: Dependency injection, networking, analytics
- **ArcanaDomain**: Models, services, validation (pure Swift)
- **ArcanaData**: Repositories, data sources, persistence
- **ArcanaPresentation**: SwiftUI views, view models, components

---

## Coding Standards

### Swift Style Guide

Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)

#### Naming Conventions

```swift
// ✅ Good
func fetchUserData(for userId: String) async throws -> User
var isLoading: Bool = false
let maximumRetryCount = 3

// ❌ Bad
func getData(id: String) -> User  // Not async, not descriptive
var loading = false               // Not clear type
let MAX_RETRY = 3                 // Not camelCase
```

#### Code Organization

```swift
// MARK: - Properties
private let userService: UserService
private var users: [User] = []

// MARK: - Initialization
init(userService: UserService) {
    self.userService = userService
}

// MARK: - Public Methods
func loadUsers() async {
    // ...
}

// MARK: - Private Methods
private func validateUser(_ user: User) -> Bool {
    // ...
}
```

### SwiftUI Best Practices

```swift
// ✅ Prefer computed properties for simple views
private var userList: some View {
    List(users) { user in
        UserRow(user: user)
    }
}

// ✅ Use @Observable for ViewModels
@MainActor
@Observable
final class UserListViewModel {
    private(set) var users: [User] = []
    private(set) var isLoading: Bool = false
}

// ✅ Inject dependencies via @Dependency
@Dependency(\.userService) var userService
```

### Swift 6 Concurrency

```swift
// ✅ Mark UI ViewModels with @MainActor
@MainActor
@Observable
final class ViewModel { }

// ✅ Use Sendable for data passed between actors
struct User: Sendable { }

// ✅ Mark nonisolated when needed
nonisolated func hash(into hasher: inout Hasher) { }

// ✅ Proper async/await
func loadData() async {
    do {
        let data = try await service.fetchData()
        self.data = data
    } catch {
        handleError(error)
    }
}
```

### Documentation

```swift
/// Fetches users from the repository with pagination support.
///
/// This method loads users page by page, caching results locally
/// and falling back to offline data when network is unavailable.
///
/// - Parameters:
///   - page: The page number to fetch (1-indexed)
///   - perPage: Number of items per page
/// - Returns: A paginated result containing users and pagination metadata
/// - Throws: `AppError` if the operation fails
func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User> {
    // Implementation
}
```

---

## Testing Guidelines

### Test Structure

```swift
import Testing
@testable import ArcanaDomain

@Test func testUserValidation() {
    let result = UserValidator.validateEmail("test@example.com")
    #expect(result == .success(()))
}

@Test func testInvalidEmail() {
    let result = UserValidator.validateEmail("invalid")
    #expect(result == .failure(.invalidEmail))
}
```

### Async Testing

```swift
@Test func testAsyncUserLoad() async throws {
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

### Test Coverage Requirements

- **Unit Tests**: All business logic, validators, services
- **ViewModel Tests**: State changes, effect handling
- **Integration Tests**: Repository with data sources
- **Minimum Coverage**: 80% for new code

---

## Pull Request Process

### 1. Create a Branch

```bash
git checkout -b feature/amazing-feature
# or
git checkout -b fix/critical-bug
```

### Branch Naming Convention

- `feature/` - New features
- `fix/` - Bug fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation updates
- `test/` - Test additions or fixes

### 2. Make Changes

- Write clean, readable code
- Follow coding standards
- Add/update tests
- Update documentation

### 3. Commit Changes

```bash
git add .
git commit -m "feat: add pagination to user list"
```

#### Commit Message Format

```
type(scope): subject

body (optional)

footer (optional)
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

**Examples**:
```
feat(user-list): add pagination with lazy loading

Implement pagination system with 10 items per page.
Includes statistics banner showing page progress.

Closes #123
```

### 4. Push Changes

```bash
git push origin feature/amazing-feature
```

### 5. Create Pull Request

1. Go to GitHub repository
2. Click "New Pull Request"
3. Select your branch
4. Fill out PR template
5. Request review

### Pull Request Checklist

- [ ] Code follows project style guidelines
- [ ] All tests pass (`xcodebuild test`)
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] No build warnings
- [ ] Commits follow conventional commit format
- [ ] PR description is clear and detailed
- [ ] Related issues are linked

---

## Documentation

### Updating Documentation

#### 1. Architecture Diagrams

Edit Mermaid files in `docs/architecture/`:

```bash
# Edit diagram
vim docs/architecture/01-overall-architecture.mmd

# Generate PNGs
npm run generate-diagrams

# Preview
open docs/diagrams/01-overall-architecture.png
```

#### 2. API Documentation

Add DocC comments to public APIs:

```swift
/// Brief description.
///
/// Detailed explanation of the functionality.
///
/// - Parameters:
///   - param1: Description
///   - param2: Description
/// - Returns: Return value description
/// - Throws: Error conditions
public func someMethod(param1: String, param2: Int) throws -> Result {
    // Implementation
}
```

Generate docs:

```bash
xcodebuild docbuild -scheme arcana-ios
```

#### 3. README Updates

Update `README.md` for:
- New features
- Breaking changes
- Installation steps
- Configuration changes

---

## Code Review Guidelines

### For Contributors

- Respond to feedback promptly
- Be open to suggestions
- Make requested changes
- Ask questions if unclear

### For Reviewers

- Be constructive and respectful
- Focus on code quality
- Check for edge cases
- Verify tests pass
- Ensure documentation is updated

---

## Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

### Creating a Release

1. Update version in Xcode project
2. Update CHANGELOG.md
3. Create git tag:
   ```bash
   git tag -a v1.2.0 -m "Release v1.2.0"
   git push origin v1.2.0
   ```
4. Create GitHub release with notes

---

## Getting Help

- **Documentation**: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Issues**: [GitHub Issues](https://github.com/yourusername/arcana-ios/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/arcana-ios/discussions)

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Arcana iOS! 🎉
