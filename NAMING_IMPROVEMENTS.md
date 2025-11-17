# ViewModel Naming Improvements

> **Renamed method and property names for better clarity**

Date: 2025-11-17

---

## Summary

Successfully renamed ViewModel methods and properties across all 3 ViewModels for better semantic clarity:
- `send()` → `input()` - Better reflects that we're processing input actions
- `state` → `output` - Better aligns with Input/Output/Effect pattern

---

## Changes Made

### Method Renaming: `send()` → `input()`

**Rationale:**
- The method processes **input** actions from the user
- Name `send()` was too generic and didn't convey purpose
- `input()` clearly indicates this is the entry point for user actions
- Aligns better with the Input/Output/Effect architecture pattern

**Before:**
```swift
func send(_ input: Input) async -> Effect? {
    switch input {
        // ...
    }
}

// Usage
await viewModel.send(.loadData)
```

**After:**
```swift
func input(_ action: Input) async -> Effect? {
    switch action {
        // ...
    }
}

// Usage
await viewModel.input(.loadData)
```

### Property Renaming: `state` → `output`

**Rationale:**
- ViewModels follow Input/Output/Effect pattern
- `state` is too generic - doesn't align with the pattern name
- `output` clearly indicates this is the ViewModel's output to the View
- Creates clear Input → Processing → Output flow

**Before:**
```swift
private(set) var state = Output()

// Usage
viewModel.state.users
viewModel.state.isLoading
```

**After:**
```swift
private(set) var output = Output()

// Usage
viewModel.output.users
viewModel.output.isLoading
```

---

## Files Changed

### ViewModels (3 files)

#### 1. UserFormViewModel.swift ✅
- Renamed `send()` → `input()`
- Renamed `state` → `output`
- Updated all internal references
- Updated parameter name: `input` → `action`

#### 2. UserListViewModel.swift ✅
- Renamed `send()` → `input()`
- Renamed `state` → `output`
- Updated all internal references (11 properties)
- Updated parameter name: `input` → `action`
- Updated recursive call in `retryLastOperation()`

#### 3. MainViewModel.swift ✅
- Renamed `send()` → `input()`
- Renamed `state` → `output`
- Updated all internal references (3 properties)
- Updated parameter name: `input` → `action`

### Views (3 files)

#### 1. UserFormView.swift ✅
- Updated all `viewModel.state.*` → `viewModel.output.*`
- Updated all `viewModel.send(` → `viewModel.input(`
- 4 form field bindings updated
- Submit button updated
- Preview helper method updated

#### 2. UserListView.swift ✅
- Updated all `viewModel.state.*` → `viewModel.output.*`
- Updated all `viewModel.send(` → `viewModel.input(`
- Search bar binding updated
- All button actions updated
- Statistics banner updated
- Sync banner updated

#### 3. MainView.swift ✅
- Updated all `viewModel.state.*` → `viewModel.output.*`
- Updated all `viewModel.send(` → `viewModel.input(`
- User count display updated
- Error display updated
- All button actions updated

---

## Pattern Comparison

### Old Pattern
```swift
@MainActor
@Observable
final class SomeViewModel {
    enum Input { ... }
    enum Effect { ... }
    struct Output { ... }

    private(set) var state = Output()  // ❌ Generic name

    func send(_ input: Input) async -> Effect? {  // ❌ Generic name
        // ...
    }
}

// Usage
let effect = await viewModel.send(.someAction)
let value = viewModel.state.someProperty
```

### New Pattern
```swift
@MainActor
@Observable
final class SomeViewModel {
    enum Input { ... }
    enum Effect { ... }
    struct Output { ... }

    private(set) var output = Output()  // ✅ Aligns with pattern

    func input(_ action: Input) async -> Effect? {  // ✅ Clear purpose
        // ...
    }
}

// Usage
let effect = await viewModel.input(.someAction)
let value = viewModel.output.someProperty
```

---

## Benefits

### 1. Better Semantic Clarity
- `input()` clearly indicates this processes input actions
- `output` clearly indicates this is the ViewModel's output
- Aligns perfectly with Input/Output/Effect pattern name

### 2. Improved Code Readability
```swift
// Before - unclear what "send" means
await viewModel.send(.loadData)
let users = viewModel.state.users

// After - crystal clear
await viewModel.input(.loadData)
let users = viewModel.output.users
```

### 3. Pattern Consistency
All three components are now clearly named:
- **Input** enum - defines input actions
- **Output** struct - defines output data
- **Effect** enum - defines side effects

Method and property names align:
- `input()` - processes Input actions
- `output` - holds Output data

### 4. Better Architecture Communication
The naming immediately communicates the architecture pattern:
- Views send **input** actions
- ViewModels provide **output** data
- ViewModels return **effects** for side effects

---

## Build Status

✅ **BUILD SUCCEEDED** - All changes compile successfully

---

## Summary of Changes

| File | send() → input() | state → output | Lines Changed |
|------|------------------|----------------|---------------|
| UserFormViewModel.swift | ✅ | ✅ | ~50 |
| UserFormView.swift | ✅ | ✅ | ~30 |
| UserListViewModel.swift | ✅ | ✅ | ~40 |
| UserListView.swift | ✅ | ✅ | ~25 |
| MainViewModel.swift | ✅ | ✅ | ~20 |
| MainView.swift | ✅ | ✅ | ~10 |

**Total:** ~175 lines across 6 files

---

## Before/After Examples

### UserFormViewModel

**Before:**
```swift
func send(_ input: Input) async -> Effect? {
    switch input {
    case .updateFirstName(let value):
        state.user = User(
            firstName: value,
            lastName: state.user.lastName,
            // ...
        )
        return nil
    }
}
```

**After:**
```swift
func input(_ action: Input) async -> Effect? {
    switch action {
    case .updateFirstName(let value):
        output.user = User(
            firstName: value,
            lastName: output.user.lastName,
            // ...
        )
        return nil
    }
}
```

### UserFormView

**Before:**
```swift
FormField(
    title: "First Name",
    text: Binding(
        get: { viewModel.state.user.firstName },
        set: { Task { _ = await viewModel.send(.updateFirstName($0)) } }
    ),
    error: viewModel.state.validationErrors.firstNameError
)
```

**After:**
```swift
FormField(
    title: "First Name",
    text: Binding(
        get: { viewModel.output.user.firstName },
        set: { Task { _ = await viewModel.input(.updateFirstName($0)) } }
    ),
    error: viewModel.output.validationErrors.firstNameError
)
```

### UserListViewModel

**Before:**
```swift
func send(_ input: Input) async -> Effect? {
    switch input {
    case .loadInitial:
        state.isLoading = true
        // ...
        state.users = result.items
        return nil
    }
}
```

**After:**
```swift
func input(_ action: Input) async -> Effect? {
    switch action {
    case .loadInitial:
        output.isLoading = true
        // ...
        output.users = result.items
        return nil
    }
}
```

### UserListView

**Before:**
```swift
Button("Refresh") {
    Task {
        if let effect = await viewModel.send(.refresh) {
            handleEffect(effect)
        }
    }
}
.disabled(viewModel.state.isRefreshing)

Text("\(viewModel.state.users.count) users")
```

**After:**
```swift
Button("Refresh") {
    Task {
        if let effect = await viewModel.input(.refresh) {
            handleEffect(effect)
        }
    }
}
.disabled(viewModel.output.isRefreshing)

Text("\(viewModel.output.users.count) users")
```

---

## Architecture Pattern Now Crystal Clear

```
┌─────────┐
│  View   │
└────┬────┘
     │ viewModel.input(.action)
     ▼
┌─────────────────────┐
│    ViewModel        │
│                     │
│  enum Input { }     │ ◄── Input actions
│  enum Effect { }    │ ◄── Side effects
│  struct Output { }  │ ◄── Output data
│                     │
│  func input()       │ ◄── Process input
│  var output         │ ◄── Provide output
└─────────────────────┘
     │ return Effect?
     │ + viewModel.output.*
     ▼
┌─────────┐
│  View   │
└─────────┘
```

---

## Related Documentation

- [ViewModel Output Analysis](VIEWMODEL_OUTPUT_ANALYSIS.md) - Output struct standardization
- [Consistency Improvements](CONSISTENCY_IMPROVEMENTS.md) - @Observable migration
- [Architecture Improvements](ARCHITECTURE_IMPROVEMENTS.md) - async send() migration

---

**Implemented:** 2025-11-17
**Build Status:** ✅ Success
**Pattern:** Input/Output/Effect with clear naming ✅
