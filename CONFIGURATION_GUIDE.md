# Configuration Management Guide

## Overview

The arcana-ios project uses a centralized configuration system based on `.plist` files for managing URLs, constants, feature flags, and environment-specific settings.

## 📁 Configuration Files

```
arcana-ios/Resources/Config/
├── Config.plist                    # Base configuration
├── Config-Development.plist        # Development environment
├── Config-Production.plist         # Production environment
└── Config-Staging.plist           # Staging environment (optional)
```

## 🔧 Configuration Structure

### Config.plist (Base Configuration)

The base configuration file contains default values for all environments:

```xml
<dict>
    <key>API</key>
    <dict>
        <key>BaseURL</key>
        <string>https://reqres.in/api</string>
        <key>Timeout</key>
        <integer>30</integer>
    </dict>

    <key>Features</key>
    <dict>
        <key>OfflineMode</key>
        <true/>
    </dict>
</dict>
```

### Environment-Specific Configs

Environment configs override base values:

- **Config-Development.plist** - Development settings
- **Config-Production.plist** - Production settings
- **Config-Staging.plist** - Staging settings

## 💻 Usage in Code

### Type-Safe Access via AppConstants

```swift
import Foundation

// API Configuration
let baseURL = AppConstants.API.baseURL
let timeout = AppConstants.API.timeout
let maxRetries = AppConstants.API.maxRetries

// Feature Flags
if AppConstants.Features.offlineMode {
    // Enable offline mode
}

if AppConstants.Features.search {
    // Show search functionality
}

// UI Constants
let duration = AppConstants.UI.animationDuration
let debounce = AppConstants.UI.debounceDelay

// Pagination
let pageSize = AppConstants.Pagination.defaultPageSize
```

### Direct Access via AppConfiguration

```swift
let config = AppConfiguration.shared

// API settings
print(config.apiBaseURL)
print(config.apiTimeout)

// Custom values
if let customValue: String = config.value(for: "Custom.Key") {
    print(customValue)
}

// Check feature
if config.isFeatureEnabled("NewFeature") {
    // Feature is enabled
}
```

## 📝 Configuration Categories

### 1. API Configuration

```swift
AppConstants.API.baseURL        // Base API URL
AppConstants.API.timeout        // Request timeout in seconds
AppConstants.API.maxRetries     // Maximum retry attempts
```

**Plist Structure:**
```xml
<key>API</key>
<dict>
    <key>BaseURL</key>
    <string>https://api.example.com</string>
    <key>Timeout</key>
    <integer>30</integer>
    <key>MaxRetries</key>
    <integer>3</integer>
</dict>
```

### 2. Endpoints

```swift
config.usersEndpoint            // /users
config.userEndpoint             // /users/%@
config.createUserEndpoint       // /users
config.updateUserEndpoint       // /users/%@
config.deleteUserEndpoint       // /users/%@
```

**Plist Structure:**
```xml
<key>Endpoints</key>
<dict>
    <key>Users</key>
    <string>/users</string>
    <key>User</key>
    <string>/users/%@</string>
</dict>
```

### 3. Pagination

```swift
AppConstants.Pagination.defaultPageSize  // 6
AppConstants.Pagination.maxPageSize      // 12
```

**Plist Structure:**
```xml
<key>Pagination</key>
<dict>
    <key>DefaultPageSize</key>
    <integer>6</integer>
    <key>MaxPageSize</key>
    <integer>12</integer>
</dict>
```

### 4. Cache Configuration

```swift
AppConstants.Cache.maxSize      // 100
AppConstants.Cache.ttl          // 300 seconds
AppConstants.Cache.enabled      // true/false
```

**Plist Structure:**
```xml
<key>Cache</key>
<dict>
    <key>MaxSize</key>
    <integer>100</integer>
    <key>TTL</key>
    <integer>300</integer>
    <key>Enabled</key>
    <true/>
</dict>
```

### 5. Feature Flags

```swift
AppConstants.Features.offlineMode       // Offline mode support
AppConstants.Features.autoSync          // Automatic synchronization
AppConstants.Features.pullToRefresh     // Pull-to-refresh gesture
AppConstants.Features.search            // Search functionality
AppConstants.Features.delete            // Delete operations
AppConstants.Features.edit              // Edit operations
```

**Plist Structure:**
```xml
<key>Features</key>
<dict>
    <key>OfflineMode</key>
    <true/>
    <key>AutoSync</key>
    <true/>
    <key>SearchEnabled</key>
    <true/>
</dict>
```

### 6. UI Configuration

```swift
AppConstants.UI.animationDuration       // 0.3 seconds
AppConstants.UI.debounceDelay          // 0.3 seconds
AppConstants.UI.toastDuration          // 2.0 seconds
AppConstants.UI.loadingDelay           // 0.5 seconds
```

**Plist Structure:**
```xml
<key>UI</key>
<dict>
    <key>AnimationDuration</key>
    <real>0.3</real>
    <key>DebounceDelay</key>
    <real>0.3</real>
</dict>
```

### 7. Analytics

```swift
config.analyticsEnabled         // Enable/disable analytics
config.analyticsDebugMode       // Debug mode for analytics
config.trackScreenViews         // Track screen views
config.trackUserActions         // Track user actions
```

**Plist Structure:**
```xml
<key>Analytics</key>
<dict>
    <key>Enabled</key>
    <true/>
    <key>DebugMode</key>
    <true/>
</dict>
```

## 🌍 Environment-Specific Configuration

### Automatic Environment Detection

The app automatically detects the environment based on build configuration:

```swift
#if DEBUG
environment = .development
#else
environment = .production
#endif
```

### Override for Testing

You can override the environment in code:

```swift
// In tests or debug builds
let config = AppConfiguration.shared
print(config.environment)  // .development or .production
```

### Environment Values

**Development:**
- Uses `Config-Development.plist`
- Debug logging enabled
- Test API endpoints
- All features enabled for testing

**Production:**
- Uses `Config-Production.plist`
- Minimal logging
- Production API endpoints
- Stable features only

## 📱 Example: API Service Integration

Before (hardcoded):
```swift
class ApiService {
    private let baseURL = "https://reqres.in/api"
    private let timeout: TimeInterval = 30

    func fetchUsers() {
        let url = "\(baseURL)/users"
        // ...
    }
}
```

After (configuration-based):
```swift
class ApiService {
    private let baseURL = AppConstants.API.baseURL
    private let timeout = AppConstants.API.timeout

    func fetchUsers() {
        let endpoint = config.usersEndpoint
        let url = "\(baseURL)\(endpoint)"
        // ...
    }
}
```

## 🎛️ Feature Flags Usage

### Conditional Features

```swift
struct UserListView: View {
    var body: some View {
        List {
            // ... users
        }
        .refreshable {
            if AppConstants.Features.pullToRefresh {
                await viewModel.refresh()
            }
        }
        .searchable(text: $searchText) {
            // Only show if enabled
        }
        .disabled(!AppConstants.Features.search)
    }
}
```

### Runtime Feature Toggling

```swift
// Check feature before showing UI
if AppConstants.Features.delete {
    Button("Delete", role: .destructive) {
        deleteUser()
    }
}

// Enable/disable entire features
if AppConstants.Features.offlineMode {
    setupOfflineStorage()
}
```

## 🔒 Security Best Practices

### DO NOT Store Secrets in Config Files

❌ **Never store:**
- API Keys
- Passwords
- Certificates
- Private tokens

✅ **Instead use:**
- Keychain for sensitive data
- Environment variables
- Secure server-side configuration
- xcconfig files for build-specific secrets

### Example: Secure API Key

```swift
// Use Keychain or environment variable
let apiKey = ProcessInfo.processInfo.environment["API_KEY"] ?? ""

// Or use a secrets manager
let apiKey = SecretsManager.shared.get("API_KEY")
```

## 🧪 Testing with Configurations

### Mock Configuration in Tests

```swift
class MockAppConfiguration: AppConfiguration {
    override var apiBaseURL: String {
        "https://mock.api.test"
    }

    override var cacheEnabled: Bool {
        false  // Disable cache in tests
    }
}

// Use in tests
let config = MockAppConfiguration()
```

### Test Different Environments

```swift
func testDevelopmentConfig() {
    let config = AppConfiguration.shared
    XCTAssertEqual(config.environment, .development)
    XCTAssertTrue(config.analyticsDebugMode)
}
```

## 📋 Migration Checklist

To migrate existing hardcoded values:

- [ ] Identify all hardcoded URLs
- [ ] Identify all hardcoded constants
- [ ] Add values to appropriate plist file
- [ ] Add type-safe accessors to `AppConstants`
- [ ] Replace hardcoded values with config access
- [ ] Test in all environments
- [ ] Update documentation

### Find Hardcoded URLs

```bash
# Search for hardcoded URLs
grep -r "https://" arcana-ios/Sources/ --include="*.swift"

# Search for hardcoded numbers
grep -r "TimeInterval(" arcana-ios/Sources/ --include="*.swift"
```

## 🚀 Adding New Configuration Values

### Step 1: Add to Config.plist

```xml
<key>NewFeature</key>
<dict>
    <key>Enabled</key>
    <true/>
    <key>MaxItems</key>
    <integer>50</integer>
</dict>
```

### Step 2: Add Accessors to AppConfiguration

```swift
var newFeatureEnabled: Bool {
    getBool(for: "NewFeature.Enabled") ?? false
}

var newFeatureMaxItems: Int {
    getInt(for: "NewFeature.MaxItems") ?? 50
}
```

### Step 3: Add to AppConstants (Optional)

```swift
enum AppConstants {
    enum NewFeature {
        static var enabled: Bool { Config.shared.newFeatureEnabled }
        static var maxItems: Int { Config.shared.newFeatureMaxItems }
    }
}
```

### Step 4: Use in Code

```swift
if AppConstants.NewFeature.enabled {
    let max = AppConstants.NewFeature.maxItems
    // Use the feature
}
```

## 📊 Configuration Hierarchy

```
Base Config (Config.plist)
    ↓
Environment Config (Config-{Environment}.plist)
    ↓
Runtime Overrides (UserDefaults, Remote Config)
```

Environment-specific values override base values.

## 🔧 Build Configuration Setup

### Xcode Schemes

1. Create schemes for each environment:
   - **arcana-ios-Dev** - Development
   - **arcana-ios-Staging** - Staging
   - **arcana-ios-Prod** - Production

2. Set build configuration per scheme:
   - Edit Scheme → Run → Build Configuration
   - Choose Debug/Release as appropriate

### xcconfig Files (Optional)

For build-specific settings:

```bash
// Development.xcconfig
API_BASE_URL = https://dev.api.example.com

// Production.xcconfig
API_BASE_URL = https://api.example.com
```

## 📱 Remote Configuration (Future Enhancement)

For dynamic configuration without app updates:

```swift
// Fetch remote config
let remoteConfig = RemoteConfigService.shared

remoteConfig.fetch { result in
    switch result {
    case .success(let config):
        // Update feature flags dynamically
        Features.newFeature = config["new_feature"] as? Bool ?? false
    case .failure(let error):
        // Fall back to local config
    }
}
```

## 🎯 Best Practices

1. ✅ **Use type-safe accessors** via `AppConstants`
2. ✅ **Separate concerns** - API, UI, Features, etc.
3. ✅ **Environment-specific configs** for different builds
4. ✅ **Document all configuration keys**
5. ✅ **Provide sensible defaults**
6. ✅ **Never commit secrets** to config files
7. ✅ **Test configurations** in all environments
8. ✅ **Version control config files**

## 📚 Additional Resources

- [Property List Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/PropertyLists/)
- [Build Configuration Best Practices](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [Managing Different Environments](https://developer.apple.com/documentation/xcode/customizing-the-build-schemes-for-a-project)

---

**Last Updated**: 2025-11-16
**Status**: ✅ Fully Implemented
**Configuration Files**: 4 (Base + 3 Environments)
