# Internationalization (i18n) Guide

## Overview

The arcana-ios project now includes comprehensive internationalization support, allowing the app to be easily localized into multiple languages.

## 🌍 Supported Languages

- **English (en)** - Base language
- **Chinese Simplified (zh-Hans)** - 简体中文

Additional languages can be added following the same pattern.

## 📁 Project Structure

```
arcana-ios/
├── Sources/
│   └── ArcanaCore/
│       └── Localization/
│           └── LocalizedString.swift  # Localization infrastructure
└── Resources/
    └── Localizations/
        ├── en.lproj/
        │   └── Localizable.strings    # English strings
        └── zh-Hans.lproj/
            └── Localizable.strings    # Chinese strings
```

## 🔧 How to Use

### Type-Safe Localization Keys

Use the `L10n` enum for type-safe access to localized strings:

```swift
import SwiftUI

// Using type-safe keys
Text(L10n.Main.title.localized)
Text(L10n.UserForm.createTitle.localized)
Text(L10n.Common.cancel.localized)
```

### String Extension

For quick localization:

```swift
// Simple localization
Text("main.title".localized)

// With arguments
Text("user_list.total_users".localized(userCount))
```

### Direct NSLocalizedString

For more complex cases:

```swift
let message = NSLocalizedString("user_list.delete_confirm_message",
                                comment: "Delete confirmation message")
```

## 📝 Localization Categories

### Common Strings
- OK, Cancel, Save, Delete, Edit, Add, Create, Update
- Refresh, Loading, Error, Retry, Close, Done, Back

### Main Screen
- App title and subtitle
- Welcome messages
- Navigation buttons

### User List
- Screen title
- Search placeholder
- Empty states
- Offline mode messages
- Sync status
- Delete confirmations

### User Form
- Form titles (Create/Edit)
- Field labels (First Name, Last Name, Email, Avatar)
- Placeholders
- Button labels

### Validation Errors
- Required field errors
- Format validation errors

### Network Errors
- No connection
- Timeout
- Server errors
- Not found
- Unauthorized

## 🔨 Adding New Strings

### 1. Add to LocalizedString.swift

```swift
enum L10n {
    enum MyFeature {
        static let title = "my_feature.title"
        static let description = "my_feature.description"
    }
}
```

### 2. Add to Localizable.strings (en.lproj)

```
// MARK: - My Feature
"my_feature.title" = "My Feature Title";
"my_feature.description" = "Feature description here";
```

### 3. Add to Other Languages

```
// zh-Hans.lproj/Localizable.strings
"my_feature.title" = "我的功能标题";
"my_feature.description" = "功能描述";
```

### 4. Use in Code

```swift
Text(L10n.MyFeature.title.localized)
```

## 🌐 Adding a New Language

### Step 1: Create Language Directory

```bash
mkdir -p arcana-ios/Resources/Localizations/es.lproj  # Spanish example
```

### Step 2: Create Localizable.strings

Copy `en.lproj/Localizable.strings` to the new language folder and translate all strings.

### Step 3: Add to Xcode Project

1. Open Xcode
2. Select your project in the navigator
3. Go to Project Info tab
4. Under "Localizations", click `+` to add the new language
5. Add the `Localizable.strings` file to the project
6. In File Inspector, check the new language under "Localize"

### Step 4: Test

Change device/simulator language to verify translations.

## 🎯 Best Practices

### 1. Always Use Keys, Never Hardcode

❌ **Bad:**
```swift
Text("Create User")
Button("Cancel") { }
```

✅ **Good:**
```swift
Text(L10n.UserForm.createTitle.localized)
Button(L10n.Common.cancel.localized) { }
```

### 2. Use Descriptive Keys

❌ **Bad:**
```swift
static let msg1 = "msg.1"
```

✅ **Good:**
```swift
static let deleteConfirmMessage = "user_list.delete_confirm_message"
```

### 3. Group Related Keys

```swift
enum UserForm {
    static let createTitle = "user_form.create_title"
    static let editTitle = "user_form.edit_title"
    static let createButton = "user_form.create_button"
    // ... related keys together
}
```

### 4. Handle Plurals Properly

For strings with counts, use format specifiers:

```swift
// Localizable.strings
"user_list.total_users" = "%d users loaded";

// Usage
Text("user_list.total_users".localized(count))
```

### 5. Use Comments in .strings Files

```
// MARK: - User List
"user_list.title" = "Users";  /* Navigation title for user list screen */
```

### 6. Keep Keys Organized

Use prefixes to group related strings:
- `common.` - Common UI elements
- `main.` - Main screen
- `user_list.` - User list screen
- `user_form.` - User form screen
- `validation.` - Validation messages
- `network_error.` - Network error messages

## 🧪 Testing Localization

### In Simulator

1. Go to Settings > General > Language & Region
2. Change "iPhone Language" to test language
3. Relaunch app to see translated strings

### In Xcode

Use scheme arguments to test specific languages:

1. Edit Scheme > Run > Arguments
2. Add: `-AppleLanguages (en, zh-Hans)`
3. Run the app

### Pseudo-Localization

For testing UI layout with longer strings:

```swift
#if DEBUG
extension String {
    var pseudoLocalized: String {
        "[\(self.map { String($0) }.joined(separator: " "))]"
    }
}
#endif
```

## 📊 Localization Checklist

- [ ] All user-facing strings use localization keys
- [ ] Keys are added to `L10n` enum
- [ ] English strings are in `en.lproj/Localizable.strings`
- [ ] Translated strings in all supported languages
- [ ] Strings with variables use proper format specifiers
- [ ] UI tested in all supported languages
- [ ] Text doesn't get truncated in any language
- [ ] RTL support considered (if supporting Arabic/Hebrew)

## 🚀 Quick Migration Guide

To migrate existing hardcoded strings:

### Find Hardcoded Strings

```bash
# Search for hardcoded Text/Button strings
grep -r 'Text("' arcana-ios/Sources/
grep -r 'Button("' arcana-ios/Sources/
```

### Replace Pattern

```swift
// Before
Text("Manage Users")

// After
Text(L10n.Main.manageUsers.localized)
```

## 📱 InfoPlist Localization

For app name and system permissions:

### Create InfoPlist.strings

```bash
mkdir -p arcana-ios/Resources/Localizations/zh-Hans.lproj
touch arcana-ios/Resources/Localizations/zh-Hans.lproj/InfoPlist.strings
```

### Add Localizations

```
// InfoPlist.strings
"CFBundleDisplayName" = "Arcana";
"NSCameraUsageDescription" = "需要相机权限以拍摄头像照片";
"NSPhotoLibraryUsageDescription" = "需要照片库权限以选择头像";
```

## 🔍 Debugging Localization Issues

### Missing Translations

Enable logging to detect missing keys:

```swift
#if DEBUG
extension String {
    var localized: String {
        let translated = NSLocalizedString(self, comment: "")
        if translated == self {
            print("⚠️ Missing translation for key: \(self)")
        }
        return translated
    }
}
#endif
```

### Show Localization Keys

For debugging, show keys instead of values:

```swift
#if DEBUG
let showKeys = UserDefaults.standard.bool(forKey: "ShowLocalizationKeys")
if showKeys {
    return self  // Return key instead of translated string
}
#endif
```

## 🎨 UI Considerations

### Text Length Variations

Different languages have different text lengths:

- German: Often 30-50% longer than English
- Chinese: Often shorter than English
- Arabic/Hebrew: Right-to-left layout

### Solutions

1. Use flexible layouts (SwiftUI auto-handles this well)
2. Test with longest expected translations
3. Avoid fixed-width constraints
4. Use `lineLimit(nil)` for multi-line text

### Example

```swift
Text(L10n.Main.welcomeMessage.localized)
    .lineLimit(nil)  // Allow multiple lines
    .minimumScaleFactor(0.8)  // Allow slight scaling if needed
```

## 📚 Resources

- [Apple Localization Guide](https://developer.apple.com/documentation/xcode/localizing-your-app)
- [NSLocalizedString Documentation](https://developer.apple.com/documentation/foundation/nslocalizedstring)
- [Internationalization Best Practices](https://developer.apple.com/internationalization/)

## 🤝 Contributing Translations

To contribute a new language translation:

1. Fork the repository
2. Create language directory (e.g., `fr.lproj` for French)
3. Copy and translate `Localizable.strings`
4. Test thoroughly
5. Submit pull request

---

**Last Updated**: 2025-11-16
**Supported Languages**: English, Chinese (Simplified)
**Status**: ✅ Fully Implemented
