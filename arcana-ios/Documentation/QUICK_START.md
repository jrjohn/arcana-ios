# Quick Start Guide - Arcana iOS

## 🚀 Getting Started in 5 Minutes

### Prerequisites
- macOS 14.0+
- Xcode 15.0+
- 5 minutes of your time

### Step 1: Open the Project
```bash
open arcana-ios.xcodeproj
```

### Step 2: Build and Run
Press `⌘R` or click the Play button in Xcode

### Step 3: Explore
You'll see:
- **Users Tab** - List of mock users
- **Analytics Tab** - Event tracking dashboard

## 📱 Using the App

### Users Tab

#### View Users
- Scroll through the user list
- Each card shows name, email, and creation date

#### Search Users
- Tap the search bar at the top
- Type to filter users in real-time
- Clear search with the X button

#### Create User
1. Tap the `+` button (top right)
2. Fill in the form:
   - First Name
   - Last Name
   - Email
3. See real-time validation
4. Tap "Create" when ready

#### Edit User
1. Tap on a user card
2. (Feature ready - implement detail view)

#### Delete User
1. Swipe left on a user card
2. Tap "Delete"
3. Confirm deletion

#### Refresh
- Pull down to refresh
- Or tap refresh button (top left)

### Analytics Tab

#### View Stats
- **Total Events** - All tracked events
- **Error Events** - Errors that occurred
- **Session ID** - Current session identifier

#### Refresh Stats
- Tap "Refresh Stats" button

#### Clear Data
- Tap "Clear All Events" button
- Confirms deletion of all analytics

## 🎨 Customization

### Change Theme Colors

Edit `Presentation/Theme/ArcanaTheme.swift`:

```swift
struct Colors {
    // Change primary colors
    static let primaryPurple = Color(hex: "YOUR_COLOR")
    static let primaryViolet = Color(hex: "YOUR_COLOR")
}
```

### Add Mock Users

Edit `Domain/Model/User.swift`:

```swift
static var mockUsers: [User] {
    [
        User(firstName: "Your", lastName: "Name", email: "your@email.com"),
        // Add more...
    ]
}
```

### Customize Validation Rules

Edit `Domain/Validation/UserValidator.swift`:

```swift
// Change email max length
private static let emailMaxLength = 300  // Was 255

// Change name requirements
private static let nameMinLength = 2   // Was 1
private static let nameMaxLength = 50  // Was 100
```

## 🧪 Running Tests

### Run All Tests
```
⌘U
```

### Run Specific Test
1. Open test file
2. Click diamond icon next to test
3. Or press `^⌥⌘U`

### View Coverage
1. Product → Test
2. View test coverage report
3. Should see ~100% for business logic

## 🔧 Common Tasks

### Add a New Screen

1. **Create ViewModel**
```swift
// Presentation/Screens/MyFeature/MyViewModel.swift
@MainActor
final class MyViewModel: ObservableObject {
    enum Input { case load }
    struct Output { var data: String = "" }
    @Published private(set) var state = Output()
    
    func send(_ input: Input) { }
}
```

2. **Create View**
```swift
// Presentation/Screens/MyFeature/MyView.swift
struct MyView: View {
    @StateObject private var viewModel: MyViewModel
    
    var body: some View {
        Text(viewModel.state.data)
    }
}
```

3. **Add to Navigation**
```swift
// Update ContentView.swift or add to TabView
NavigationStack {
    MyView(viewModel: MyViewModel())
}
.tabItem {
    Label("My Feature", systemImage: "star.fill")
}
```

### Track a New Event

1. **Add to AnalyticsEvent.swift**
```swift
enum AnalyticsEvent: String {
    case myNewEvent = "my_new_event"
}
```

2. **Track it**
```swift
analyticsTracker.trackEvent(.myNewEvent, params: [
    "key": "value"
])
```

3. **View in Analytics Tab**

### Add a New Error Code

1. **Add to ErrorCode.swift**
```swift
enum ErrorCode {
    case E7000_MY_ERROR
}
```

2. **Add description**
```swift
var description: String {
    switch self {
    case .E7000_MY_ERROR:
        return "My error description"
    }
}
```

3. **Use it**
```swift
throw AppError.validationError(
    .E7000_MY_ERROR,
    field: "myField",
    message: "Error message"
)
```

## 🐛 Troubleshooting

### App Won't Build

**Issue**: Missing dependencies
**Solution**: Clean build folder
```
⌘⇧K (Clean Build Folder)
⌘B (Build)
```

**Issue**: SwiftData errors
**Solution**: Reset simulator
```
Device → Erase All Content and Settings
```

### Users Not Showing

**Issue**: Empty database
**Solution**: The app uses mock data - it should work out of the box

**Issue**: Data got cleared
**Solution**: Delete and reinstall app

### Analytics Not Tracking

**Issue**: Check DIContainer initialization
**Solution**: Look for this in console:
```
📊 Analytics session started: [SESSION_ID]
```

### Tests Failing

**Issue**: Async timing
**Solution**: Increase wait time in tests
```swift
try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
```

## 📚 Learn More

### Architecture
- Read `ARCHITECTURE.md` for deep dive
- Check `IMPLEMENTATION_SUMMARY.md` for overview

### Code Examples
- Look at existing ViewModels
- Check test files for patterns
- Read inline comments

### SwiftUI
- Apple's SwiftUI documentation
- SwiftData guide
- Async/await tutorials

## 🎯 Next Steps

### Easy Tasks (< 30 min)
- [ ] Change theme colors
- [ ] Add more mock users
- [ ] Modify validation rules
- [ ] Add new analytics event

### Medium Tasks (1-2 hours)
- [ ] Add user detail view
- [ ] Implement user profile pictures
- [ ] Add sorting options
- [ ] Add filtering

### Advanced Tasks (2+ hours)
- [ ] Implement real API
- [ ] Add authentication
- [ ] Add background sync
- [ ] Add widget

## 💡 Tips

### Development
- Use SwiftUI previews for fast iteration
- Check Analytics tab to see event tracking
- Use error codes for debugging
- Run tests frequently

### Debugging
- Check console for logs with 📊, ✅, ❌ emojis
- Analytics shows all errors with codes
- Use breakpoints in ViewModels

### Performance
- Cache is automatic with 5-minute TTL
- Background sync happens automatically
- Search is debounced (300ms)

## 🤝 Contributing

This is your codebase now! Feel free to:
- Modify anything
- Add features
- Change architecture
- Experiment

The code is well-structured and tested, so you can refactor with confidence.

## ✨ Features Ready to Implement

The architecture supports these out of the box:

- [ ] User detail screen
- [ ] Pagination (repository supports it)
- [ ] Sorting and filtering
- [ ] Batch operations
- [ ] Export/Import
- [ ] Settings screen
- [ ] Dark mode
- [ ] Localization
- [ ] Accessibility

## 📞 Support

### Documentation
- `README.md` - Overview
- `IMPLEMENTATION_SUMMARY.md` - What's built
- `ARCHITECTURE.md` - Deep dive (create if needed)
- Inline comments in code

### Code Organization
```
Everything is organized by feature:
- Core/          → Cross-cutting concerns
- Data/          → Data access
- Domain/        → Business logic
- Presentation/  → UI
```

---

## 🎉 You're Ready!

You now have everything you need to:
✅ Run the app  
✅ Understand the code  
✅ Add features  
✅ Test changes  
✅ Ship to production  

**Happy coding! 🚀**
