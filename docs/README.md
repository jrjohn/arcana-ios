# Arcana iOS Documentation

Welcome to the comprehensive documentation for Arcana iOS!

## 📚 Documentation Index

### Getting Started
- [Main README](../README.md) - Project overview and quick start
- [Contributing Guidelines](../CONTRIBUTING.md) - How to contribute to the project

### Architecture
- [Architecture Overview](ARCHITECTURE.md) - Comprehensive architecture documentation
- [ViewModel Pattern](VIEWMODEL_PATTERN.md) - Input/Output/Effect pattern guide
- [Pagination Guide](PAGINATION.md) - Lazy loading implementation
- [Offline-First Strategy](OFFLINE_FIRST.md) - Offline sync architecture

### Diagrams

#### Mermaid Source Files (Editable)
Located in [`architecture/`](architecture/):
1. [01-overall-architecture.mmd](architecture/01-overall-architecture.mmd) - System overview
2. [02-clean-architecture-layers.mmd](architecture/02-clean-architecture-layers.mmd) - Layer separation
3. [03-pagination-system.mmd](architecture/03-pagination-system.mmd) - Pagination flow
4. [04-data-flow.mmd](architecture/04-data-flow.mmd) - Data flow through layers
5. [05-offline-first-sync.mmd](architecture/05-offline-first-sync.mmd) - Sync mechanism
6. [06-dependency-graph.mmd](architecture/06-dependency-graph.mmd) - Dependency injection

#### Generated PNG Diagrams
Located in [`diagrams/`](diagrams/) - Auto-generated from Mermaid sources

### API Reference
- [API Documentation](api/index.html) - Auto-generated from DocC comments

---

## 🔧 Generating Documentation

### Prerequisites

```bash
# Install Node.js dependencies
npm install
```

### Generate Diagrams

```bash
# Generate all diagrams
npm run generate-diagrams

# Watch for changes
npm run watch-diagrams

# List diagrams
npm run list-diagrams
```

### Generate API Docs

```bash
# Generate DocC documentation
xcodebuild docbuild -scheme arcana-ios -destination 'platform=iOS Simulator,name=iPhone 17'

# Documentation will be available at:
# .build/documentation/index.html
```

---

## 📖 Documentation Standards

### Markdown Files

- Use clear headings (H1 for title, H2 for sections)
- Include table of contents for long documents
- Add code examples with syntax highlighting
- Use mermaid diagrams for visual explanations

### Code Documentation

```swift
/// Brief one-line description.
///
/// Detailed explanation that can span multiple lines.
/// Include usage examples when helpful.
///
/// ```swift
/// let result = try await service.getUsers(page: 1, perPage: 10)
/// ```
///
/// - Parameters:
///   - page: The page number to fetch (1-indexed)
///   - perPage: Number of items per page
/// - Returns: A paginated result containing users
/// - Throws: `AppError` if the operation fails
public func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User>
```

### Diagrams

- Store source `.mmd` files in `architecture/`
- Generate PNG to `diagrams/` directory
- Use consistent naming: `##-description.mmd`
- Include descriptions in diagram titles

---

## 🎯 Key Concepts

### Clean Architecture

Arcana iOS follows Uncle Bob's Clean Architecture with clear layer separation:

- **Presentation**: SwiftUI views and ViewModels
- **Domain**: Business logic, models, and validation
- **Data**: Repositories and data sources
- **Core**: Infrastructure and utilities

### MVVM with Input/Output/Effect

ViewModels use a structured pattern:

- **Input**: Events from UI → ViewModel
- **Output**: State for UI rendering
- **Effect**: Side effects (navigation, alerts)

### Offline-First

Data flows through layers with offline support:

1. Local database is source of truth
2. Remote API syncs in background
3. Pending changes queued when offline
4. Auto-sync when network restored

---

## 🔗 External Resources

- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

---

## 📝 Contributing to Documentation

1. Edit Markdown files or Mermaid diagrams
2. Generate updated diagrams: `npm run generate-diagrams`
3. Build API docs: `xcodebuild docbuild`
4. Preview changes
5. Submit pull request

See [Contributing Guidelines](../CONTRIBUTING.md) for details.

---

## 📞 Need Help?

- Open an [issue](https://github.com/yourusername/arcana-ios/issues)
- Start a [discussion](https://github.com/yourusername/arcana-ios/discussions)
- Check [Architecture Guide](ARCHITECTURE.md)

---

**Last Updated**: 2024-11-16
