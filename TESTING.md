# Testing & Coverage Automation

This project includes automated testing and coverage report generation.

## Quick Start

### Run All Tests with Coverage
```bash
make test
```
This will:
1. Run all unit and UI tests
2. Generate coverage reports automatically
3. Open the HTML coverage report in your browser

### Run Only Unit Tests
```bash
make test-unit
```

### Run Only UI Tests
```bash
make test-ui
```

### Generate Coverage Report (from latest test run)
```bash
make coverage
```

### View Help
```bash
make help
```

## Available Commands

| Command | Description |
|---------|-------------|
| `make test` | Run all tests with coverage and auto-generate HTML report |
| `make test-unit` | Run only unit tests with coverage |
| `make test-ui` | Run only UI tests |
| `make coverage` | Generate coverage reports from latest test run |
| `make clean` | Clean build artifacts and test results |

## Manual Testing

If you prefer to run tests manually:

### Using xcodebuild
```bash
# Run all tests with coverage
xcodebuild test \
  -scheme arcana-ios \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -enableCodeCoverage YES \
  -derivedDataPath DerivedData

# Generate coverage report
./scripts/generate_coverage_html.sh
```

### Using Xcode
1. Press `⌘+U` to run all tests
2. Run `make coverage` to generate the HTML report

## Coverage Reports

After running tests, coverage reports are generated in multiple formats:

### 📊 HTML Report (Recommended)
- **Location**: `docs/test-coverage.html`
- **Features**: Interactive, color-coded, sortable
- **Open with**: `open docs/test-coverage.html`

### 📄 Other Formats
- **JSON**: `coverage_report.json` - Raw data
- **Text**: `coverage_report.txt` - Terminal-friendly summary
- **Analysis**: `COVERAGE_ANALYSIS.md` - Detailed analysis document

## Coverage Thresholds

The project uses color-coded coverage levels:

| Coverage | Level | Color |
|----------|-------|-------|
| ≥90% | Excellent | 🟢 Green |
| 70-90% | Good | 🔵 Blue |
| 50-70% | Moderate | 🟡 Orange |
| <50% | Low | 🔴 Red |

## UI Tests

The project includes comprehensive UI tests that:
- Actually interact with the app (not just placeholders)
- Navigate through screens
- Test user flows and gestures
- Capture screenshots
- Measure performance

See `UI_TESTS_IMPROVEMENTS.md` for details on the UI test enhancements.

### UI Test Behavior

If you see the app launch and close multiple times during UI tests, this is **normal**.

The launch tests can be configured to run across different UI configurations (light/dark mode, text sizes, etc.). Currently set to run once per test for faster execution.

To change this behavior, edit `arcana-iosUITests/arcana_iosUITestsLaunchTests.swift` line 12:
```swift
override class var runsForEachTargetApplicationUIConfiguration: Bool {
    false  // Change to true to test all UI configurations
}
```

## CI/CD Integration

The Makefile targets are designed to work in CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run tests and generate coverage
  run: make test

- name: Upload coverage report
  uses: actions/upload-artifact@v3
  with:
    name: coverage-report
    path: docs/test-coverage.html
```

## Troubleshooting

### No test results found
Run tests first:
```bash
make test
```

### Simulator issues
If the simulator has issues:
1. Quit the Simulator app
2. Run `make clean`
3. Run `make test` again

### Coverage report generation fails
Check that:
1. Tests have completed successfully
2. Coverage is enabled (`-enableCodeCoverage YES`)
3. Python 3 is installed: `python3 --version`

## Project Structure

```
arcana-ios/
├── Makefile                    # Automation commands
├── scripts/
│   └── generate_coverage_html.sh  # Coverage generation script
├── generate_html_coverage.py   # HTML report generator
├── docs/
│   └── test-coverage.html     # Generated HTML report
├── arcana-iosTests/           # Unit tests (94.84% coverage)
├── arcana-iosUITests/         # UI tests (100% coverage)
├── COVERAGE_ANALYSIS.md       # Detailed coverage analysis
├── UI_TESTS_IMPROVEMENTS.md   # UI test documentation
└── TESTING.md                 # This file
```

## Coverage Goals

- **Current**: 26.42% overall
- **Target**: 80%+

Focus areas for improvement:
1. Data persistence layer (OfflineFirstUserRepository, SwiftDataUserDataSource)
2. Navigation and routing (NavGraph, AppRoute)
3. API and network layers (ApiService, ReqresUserDataSource)
4. UI view logic extraction

See `COVERAGE_ANALYSIS.md` for detailed recommendations.

## Tips

1. **Run tests frequently** - `make test-unit` is fast for quick feedback
2. **Check coverage after changes** - Ensure new code is tested
3. **Review HTML report** - Visual feedback helps identify gaps
4. **Keep UI tests stable** - Use longer timeouts for reliability
5. **Clean periodically** - `make clean` if tests behave oddly

## Resources

- [Apple Testing Documentation](https://developer.apple.com/documentation/xctest)
- [Code Coverage Best Practices](https://developer.apple.com/documentation/xcode/code-coverage)
- Project coverage analysis: `COVERAGE_ANALYSIS.md`
- UI test improvements: `UI_TESTS_IMPROVEMENTS.md`
