# Architecture Compliance System

**Automated architecture and code quality validation for the Arcana iOS project**

## Overview

The Architecture Compliance System automatically validates your codebase against predefined architecture rules on every build. It helps maintain Clean Architecture principles, enforce coding standards, and catch common issues early in the development process.

## Features

✅ **Automated Validation** - Runs automatically on every build via `make build`
✅ **Custom Rules** - Define your own rules using JSON configuration
✅ **Beautiful HTML Reports** - Interactive, filterable violation reports
✅ **Multiple Rule Categories** - Naming conventions, layer separation, best practices, configuration management
✅ **Severity Levels** - Error, Warning, and Info classifications
✅ **Real-time Filtering** - Search and filter violations in the HTML report
✅ **Zero Dependencies** - Uses only Python 3 (included with macOS)

## Quick Start

### Run Compliance Check

```bash
# Run standalone compliance check
make compliance

# Or run with build
make build
```

### View Report

The HTML report is automatically generated at:
```
docs/architecture-compliance.html
```

It will open automatically after running `make compliance` or `make build`.

## Rule Categories

The system includes 6 built-in rule categories with **67 total rules** based on industry best practices, [Swift.org API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines), and [Google's Swift Style Guide](https://google.github.io/swift):

### 1. Naming Conventions (`naming-conventions.json`)

Enforces consistent naming patterns across the codebase:

- **NC001**: ViewModels must end with `ViewModel` suffix
- **NC002**: SwiftUI Views should end with `View` suffix
- **NC003**: Repository implementations must end with `Repository`
- **NC004**: Service implementations should end with `Service` or `ServiceImpl`
- **NC005**: Avoid `Protocol` suffix in protocol names

**Example Rule:**
```json
{
  "id": "NC001",
  "name": "ViewModel Naming",
  "description": "ViewModels must end with 'ViewModel'",
  "pattern": "class\\s+([A-Z][a-zA-Z0-9]*)(?<!ViewModel)\\s*:\\s*.*ObservableObject",
  "file_pattern": "**/*ViewModel.swift",
  "severity": "error",
  "message": "ViewModel classes must end with 'ViewModel' suffix"
}
```

### 2. Layer Separation (`layer-separation.json`)

Enforces Clean Architecture layer boundaries:

- **LS001**: Domain layer must not import Presentation or Data layers
- **LS002**: Presentation should not directly import Data layer
- **LS003**: Data layer must not import Presentation layer
- **LS004**: SwiftUI should only be used in Presentation layer
- **LS005**: Prefer SwiftUI over UIKit in new code

**Example Rule:**
```json
{
  "id": "LS001",
  "name": "Domain Layer Independence",
  "description": "Domain layer must not import Presentation or Data layers",
  "pattern": "import\\s+(ArcanaPresentation|ArcanaData|SwiftUI|UIKit)",
  "file_pattern": "**/ArcanaDomain/**/*.swift",
  "severity": "error",
  "message": "Domain layer must not depend on Presentation or Data layers"
}
```

### 3. Best Practices (`best-practices.json`)

Swift and iOS development best practices:

- **BP001**: Avoid force unwrapping optionals (`!`)
- **BP002**: Use proper logging instead of `print()`
- **BP003**: Track technical debt with TODO/FIXME comments
- **BP004**: Prefer async/await over completion handlers
- **BP005**: ViewModels should be marked with `@MainActor`
- **BP006**: Types crossing actor boundaries should conform to Sendable
- **BP007**: Avoid magic numbers, use named constants

**Example Rule:**
```json
{
  "id": "BP001",
  "name": "No Force Unwrap",
  "description": "Avoid force unwrapping optionals",
  "pattern": "![\\s\\)]",
  "file_pattern": "**/Sources/**/*.swift",
  "exclude_pattern": "(test|mock|preview|sample)",
  "severity": "warning",
  "message": "Avoid force unwrapping (!), use optional binding or guard instead"
}
```

### 4. Configuration Management (`configuration.json`)

Ensures proper use of the configuration system:

- **CM001**: URLs should come from configuration, not hardcoded
- **CM002**: Timeout values should come from configuration
- **CM003**: Pagination values should come from configuration
- **CM004**: Encourage use of AppConstants over direct config access

**Example Rule:**
```json
{
  "id": "CM001",
  "name": "No Hardcoded URLs",
  "description": "URLs should come from configuration",
  "pattern": "https?://[^\"'\\s]+",
  "file_pattern": "**/Sources/**/*.swift",
  "exclude_pattern": "(test|mock|preview|comment|AppConfiguration)",
  "severity": "warning",
  "message": "Use AppConstants or configuration for URLs instead of hardcoding"
}
```

### 5. Swift API Design Guidelines (`swift-api-design.json`)

Enforces official [Swift.org API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines):

**Fundamentals:**
- **API001**: Clarity at point of use - avoid redundant words
- **API002**: Boolean properties read as assertions
- **API003**: Protocols describing capabilities use "able" suffix
- **API009**: Avoid obscure abbreviations
- **API010**: Use established terms from domain

**Naming:**
- **API012**: Functions/variables use lowerCamelCase (ERROR)
- **API013**: Types use UpperCamelCase (ERROR)
- **API014**: Enum cases use lowerCamelCase
- **API015**: Use standard collection terminology

**Methods:**
- **API004**: Mutating vs non-mutating method naming
- **API005**: Factory methods begin with 'make'
- **API022**: Side effect naming conventions

**Parameters:**
- **API006**: Type conversion initializers omit first label
- **API007**: Weak type information needs role description
- **API008**: Prepositional phrase argument labels
- **API020**: Choose good parameter names

**Collections:**
- **API021**: Prefer empty collection over nil (WARNING)

**Documentation:**
- **API016**: Document computational complexity if not O(1)

**Advanced:**
- **API011**: Prefer methods/properties to free functions
- **API017**: Closure parameters typically unnamed
- **API018**: Use default parameters
- **API019**: Label closure/tuple parameters

**Example Rules:**
```json
{
  "id": "API012",
  "name": "Follow Case Conventions",
  "description": "Functions and variables should use lowerCamelCase",
  "pattern": "(func|var|let)\\s+[A-Z]\\w*\\s*[(:=]",
  "file_pattern": "**/Sources/**/*.swift",
  "exclude_pattern": "(case|enum|test|URL|HTTP|API)",
  "severity": "error",
  "message": "Functions, variables, and constants should use lowerCamelCase"
}
```

```json
{
  "id": "API021",
  "name": "Avoid Returning Optional Collection",
  "description": "Prefer empty collection over nil",
  "pattern": "->\\s*\\[\\w+\\]\\?",
  "file_pattern": "**/Sources/**/*.swift",
  "severity": "warning",
  "message": "Prefer returning empty collection instead of optional. Return [] instead of nil."
}
```

### 6. Google Swift Style Guide (`google-swift-style.json`)

Enforces [Google's Swift Style Guide](https://google.github.io/swift) standards:

**Formatting:**
- **GSG001**: No semicolons at end of statements
- **GSG002**: Use shorthand array/dictionary syntax ([Type] vs Array<Type>)
- **GSG013**: No horizontal alignment with extra whitespace
- **GSG014**: One statement per line
- **GSG024**: Two-space indentation (informational)

**Naming:**
- **GSG003**: Global constants use lowerCamelCase, not ALL_CAPS (WARNING)
- **GSG016**: File names should match primary type

**Code Quality:**
- **GSG004**: Prefer guard for early exit over nested if
- **GSG005**: No force-try in production code (WARNING)
- **GSG023**: Error handling over force operations (WARNING)
- **GSG017**: Avoid fallthrough in switch statements

**Documentation:**
- **GSG006**: Public/open APIs must have documentation (WARNING)
- **GSG007**: Use triple-slash (///) comments, not /** */

**Safety:**
- **GSG008**: Playground literals forbidden in production (ERROR)
- **GSG010**: Use optionals instead of sentinel values
- **GSG011**: Implicitly unwrapped optionals only for @IBOutlet

**Architecture:**
- **GSG009**: Explicit access control modifiers
- **GSG012**: Prefer explicit self in initializers
- **GSG015**: Use // MARK: for code organization
- **GSG018**: Omit explicit get block for read-only computed properties
- **GSG019**: Import complete modules, not individual declarations
- **GSG020**: Use trailing closure syntax
- **GSG021**: Only define custom operators with clear domain meaning
- **GSG022**: Separate protocol conformance into extensions

**Example Rules:**
```json
{
  "id": "GSG003",
  "name": "No ALL_CAPS Constants",
  "description": "Global constants should use lowerCamelCase, not ALL_CAPS",
  "pattern": "let\\s+[A-Z][A-Z_0-9]+\\s*=",
  "file_pattern": "**/Sources/**/*.swift",
  "exclude_pattern": "test",
  "severity": "warning",
  "message": "Use lowerCamelCase for constants, not ALL_CAPS (Google Swift Style Guide)"
}
```

```json
{
  "id": "GSG006",
  "name": "Document Public APIs",
  "description": "All public and open declarations must have documentation comments",
  "pattern": "^\\s*(public|open)\\s+(class|struct|enum|func|var|let)",
  "file_pattern": "**/Sources/**/*.swift",
  "exclude_pattern": "test|///",
  "severity": "warning",
  "message": "Public/open APIs must have documentation comments (///)"
}
```

```json
{
  "id": "GSG008",
  "name": "No Playground Literals",
  "description": "Playground literals are forbidden in production code",
  "pattern": "#(colorLiteral|imageLiteral|fileLiteral)",
  "file_pattern": "**/Sources/**/*.swift",
  "severity": "error",
  "message": "Playground literals (#colorLiteral, #imageLiteral, #fileLiteral) are forbidden in production code"
}
```

## Creating Custom Rules

### Rule File Structure

Create a new JSON file in `docs/rules/` with the following structure:

```json
{
  "name": "Rule Category Name",
  "description": "Description of this rule category",
  "severity": "warning",
  "enabled": true,
  "rules": [
    {
      "id": "XXX001",
      "name": "Rule Name",
      "description": "What this rule checks for",
      "pattern": "regex pattern to match",
      "file_pattern": "**/*.swift",
      "exclude_pattern": "test|mock",
      "severity": "error|warning|info",
      "message": "Error message to show when violated"
    }
  ]
}
```

### Rule Properties

| Property | Required | Description |
|----------|----------|-------------|
| `id` | Yes | Unique rule identifier (e.g., "NC001") |
| `name` | Yes | Human-readable rule name |
| `description` | Yes | Detailed description of what the rule checks |
| `pattern` | Yes | Regular expression to match violations |
| `file_pattern` | No | Glob pattern for files to check (default: `**/*.swift`) |
| `exclude_pattern` | No | Regex pattern for files to exclude |
| `severity` | Yes | `error`, `warning`, or `info` |
| `message` | Yes | Message shown when rule is violated |

### Pattern Examples

**Match class declarations:**
```regex
class\\s+([A-Z][a-zA-Z0-9]*)\\s*:\\s*
```

**Match import statements:**
```regex
import\\s+SwiftUI
```

**Match hardcoded URLs:**
```regex
https?://[^"'\\s]+
```

**Match force unwrap:**
```regex
![\\s\\)]
```

**Match print statements:**
```regex
\\bprint\\s*\\(
```

### Example: Custom Security Rule

Create `docs/rules/security.json`:

```json
{
  "name": "Security Best Practices",
  "description": "Security-related code checks",
  "severity": "error",
  "enabled": true,
  "rules": [
    {
      "id": "SEC001",
      "name": "No Hardcoded API Keys",
      "description": "API keys should not be hardcoded",
      "pattern": "(apiKey|api_key|API_KEY)\\s*=\\s*\"[A-Za-z0-9]+\"",
      "file_pattern": "**/Sources/**/*.swift",
      "severity": "error",
      "message": "API keys must not be hardcoded. Use Keychain or environment variables."
    },
    {
      "id": "SEC002",
      "name": "No SQL String Concatenation",
      "description": "Prevent SQL injection vulnerabilities",
      "pattern": "\"SELECT.*\\+.*\"",
      "file_pattern": "**/*.swift",
      "severity": "error",
      "message": "Use parameterized queries instead of string concatenation to prevent SQL injection"
    }
  ]
}
```

## HTML Report Features

The generated HTML report provides:

### Summary Dashboard
- Total violations count
- Breakdown by severity (Errors, Warnings, Info)
- Color-coded cards for quick assessment

### Interactive Filtering
- Filter by severity level (All, Errors, Warnings, Info)
- Real-time search across files, rules, and messages
- Instant results update

### Detailed Violation Cards
Each violation shows:
- Rule message and description
- File name and line number
- Rule ID for reference
- Code snippet showing the violation
- Full file path
- Color-coded severity badge

### Responsive Design
- Works on desktop and mobile
- Smooth animations and transitions
- Searchable and filterable
- Scrollable violations list

## Integration

### Xcode Build Phase (Optional)

To run compliance check on every Xcode build:

1. Open your project in Xcode
2. Select your target → Build Phases
3. Click "+" → New Run Script Phase
4. Add the following script:

```bash
# Architecture Compliance Check
python3 "${PROJECT_DIR}/scripts/check_architecture_compliance.py"
```

5. Move it to run after "Compile Sources"

### Makefile Integration (Included)

The compliance check is already integrated into the Makefile:

```makefile
# Run with build
make build

# Run standalone
make compliance
```

### CI/CD Integration

For continuous integration, add to your workflow:

```yaml
# .github/workflows/ci.yml
- name: Run Architecture Compliance Check
  run: |
    python3 scripts/check_architecture_compliance.py
    if [ $? -ne 0 ]; then
      echo "Architecture compliance check failed!"
      exit 1
    fi
```

The script returns:
- Exit code `0`: No errors (warnings/info allowed)
- Exit code `1`: Errors found

## Best Practices

### Rule Severity Guidelines

**Use ERROR for:**
- Architecture violations (layer boundary breaches)
- Security issues
- Critical naming violations
- Dependency rule violations

**Use WARNING for:**
- Code quality issues
- Best practice violations
- Recommended patterns
- Configuration management

**Use INFO for:**
- Technical debt markers (TODO/FIXME)
- Optional improvements
- Suggestions for better code

### Excluding Files

Use `exclude_pattern` to skip:
- Test files: `test|mock|preview`
- Generated code: `generated|\.pb\.swift`
- Third-party code: `Pods|Carthage`
- Legacy code: `legacy|deprecated`

### Pattern Writing Tips

1. **Be Specific**: Match exact patterns to avoid false positives
2. **Use Anchors**: `^` and `$` for line start/end matching
3. **Escape Special Chars**: `\\.`, `\\(`, `\\)`
4. **Test Patterns**: Use online regex testers before adding rules
5. **Consider Context**: Use `exclude_pattern` for legitimate cases

## Troubleshooting

### No Violations Found (But Expected Some)

1. Check that rules are enabled: `"enabled": true`
2. Verify file patterns match your structure
3. Test regex patterns with online tools
4. Check `exclude_pattern` isn't too broad

### Too Many False Positives

1. Add specific `exclude_pattern` for legitimate cases
2. Make regex pattern more specific
3. Consider changing severity from ERROR to WARNING

### Script Errors

```bash
# Check Python version (requires 3.6+)
python3 --version

# Run with verbose output
python3 -v scripts/check_architecture_compliance.py
```

## File Locations

```
arcana-ios/
├── docs/
│   ├── rules/                                    # Rule definitions
│   │   ├── naming-conventions.json               # Naming rules
│   │   ├── layer-separation.json                 # Architecture rules
│   │   ├── best-practices.json                   # Code quality rules
│   │   ├── configuration.json                    # Config management rules
│   │   └── your-custom-rules.json                # Your custom rules
│   ├── architecture-compliance.html              # Generated HTML report
│   └── compliance-data.json                      # Generated JSON data
├── scripts/
│   ├── check_architecture_compliance.py          # Main compliance checker
│   └── check-architecture-compliance.sh          # Bash version (legacy)
└── Makefile                                       # Build automation
```

## Rule Statistics

Current rules by category:

| Category | Rules | Severity Breakdown |
|----------|-------|-------------------|
| Naming Conventions | 5 | 2 errors, 2 warnings, 1 info |
| Layer Separation | 5 | 3 errors, 1 warning, 1 info |
| Best Practices | 7 | 0 errors, 4 warnings, 3 info |
| Configuration | 4 | 0 errors, 3 warnings, 1 info |
| Swift API Design | 22 | 2 errors, 3 warnings, 17 info |
| **Google Swift Style** | **24** | **1 error, 8 warnings, 15 info** |
| **Total** | **67** | **8 errors, 21 warnings, 38 info** |

### Rule Distribution by Severity

- **Errors (8)**: Critical violations that break architecture or naming conventions
- **Warnings (21)**: Important issues that should be addressed
- **Info (38)**: Suggestions and best practice recommendations

## Examples

### Adding a Performance Rule

Create `docs/rules/performance.json`:

```json
{
  "name": "Performance Best Practices",
  "description": "Performance optimization checks",
  "severity": "warning",
  "enabled": true,
  "rules": [
    {
      "id": "PERF001",
      "name": "Avoid @State in ObservableObject",
      "description": "@State should not be used in ObservableObject classes",
      "pattern": "@State.*var.*\\n.*:.*ObservableObject",
      "file_pattern": "**/*.swift",
      "severity": "warning",
      "message": "Use @Published instead of @State in ObservableObject"
    }
  ]
}
```

### Adding a Documentation Rule

```json
{
  "id": "DOC001",
  "name": "Public API Documentation",
  "description": "Public classes and functions should have documentation",
  "pattern": "public\\s+(class|func|var|struct|enum)",
  "inverse_pattern": "///",
  "file_pattern": "**/Sources/**/*.swift",
  "exclude_pattern": "test",
  "severity": "info",
  "message": "Public APIs should have documentation comments"
}
```

## Future Enhancements

Possible future additions:

- [ ] Complexity analysis (cyclomatic complexity)
- [ ] Dependency graph validation
- [ ] Test coverage enforcement per file
- [ ] Custom severity thresholds
- [ ] Rule exclusions per file via comments
- [ ] Integration with SwiftLint
- [ ] GitHub Actions bot comments
- [ ] Trend analysis over time

## Support

For questions or issues:

1. Check this documentation
2. Review example rules in `docs/rules/`
3. Test regex patterns at [regex101.com](https://regex101.com)
4. Create an issue in the project repository

---

**Version**: 1.0.0
**Last Updated**: 2025-11-16
**Maintainer**: Arcana iOS Team
