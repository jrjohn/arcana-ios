# Architecture Compliance Rules

This directory contains JSON-based rule definitions for the architecture compliance system.

## 📋 Available Rule Sets

### Official Rules (6 categories, 67 rules)

1. **naming-conventions.json** - Consistent naming patterns
2. **layer-separation.json** - Clean Architecture boundaries
3. **best-practices.json** - Swift/iOS best practices
4. **configuration.json** - Configuration management
5. **swift-api-design.json** - [Swift.org API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines)
6. **google-swift-style.json** - [Google Swift Style Guide](https://google.github.io/swift)

## 🔧 Creating Custom Rules

### Quick Start

Create a new `.json` file in this directory:

```json
{
  "name": "Your Rule Category",
  "description": "What these rules check for",
  "severity": "warning",
  "enabled": true,
  "rules": [
    {
      "id": "XXX001",
      "name": "Rule Name",
      "description": "Detailed description",
      "pattern": "regex pattern",
      "file_pattern": "**/*.swift",
      "severity": "error|warning|info",
      "message": "Helpful error message"
    }
  ]
}
```

### Rule Properties Reference

| Property | Required | Type | Description |
|----------|----------|------|-------------|
| `id` | ✅ | string | Unique identifier (e.g., "SEC001") |
| `name` | ✅ | string | Human-readable name |
| `description` | ✅ | string | What the rule checks |
| `pattern` | ✅ | regex | Pattern to match violations |
| `file_pattern` | ❌ | glob | Files to check (default: `**/*.swift`) |
| `exclude_pattern` | ❌ | regex | Files/patterns to skip |
| `severity` | ✅ | enum | `error`, `warning`, or `info` |
| `message` | ✅ | string | User-facing error message |

### Severity Levels

- **error**: Critical issues that must be fixed (e.g., architecture violations)
- **warning**: Important issues that should be addressed (e.g., code quality)
- **info**: Suggestions and recommendations (e.g., best practices)

## 📝 Example Rules

### Security Rule

```json
{
  "name": "Security Best Practices",
  "enabled": true,
  "rules": [
    {
      "id": "SEC001",
      "name": "No Hardcoded Secrets",
      "description": "API keys and secrets must not be hardcoded",
      "pattern": "(apiKey|api_key|secret)\\s*=\\s*\"[A-Za-z0-9]{20,}\"",
      "file_pattern": "**/Sources/**/*.swift",
      "exclude_pattern": "test",
      "severity": "error",
      "message": "Never hardcode secrets. Use Keychain or environment variables."
    }
  ]
}
```

### Performance Rule

```json
{
  "name": "Performance Guidelines",
  "enabled": true,
  "rules": [
    {
      "id": "PERF001",
      "name": "Avoid Nested Loops",
      "description": "Nested loops can cause O(n²) complexity",
      "pattern": "for\\s+.*in.*\\{[^}]*for\\s+.*in",
      "file_pattern": "**/*.swift",
      "exclude_pattern": "test",
      "severity": "warning",
      "message": "Consider refactoring nested loops for better performance"
    }
  ]
}
```

### Documentation Rule

```json
{
  "name": "Documentation Standards",
  "enabled": true,
  "rules": [
    {
      "id": "DOC001",
      "name": "Public API Documentation",
      "description": "All public APIs must be documented",
      "pattern": "public\\s+(class|func|var|struct)",
      "file_pattern": "**/Sources/**/*.swift",
      "exclude_pattern": "test|///",
      "severity": "warning",
      "message": "Public APIs should have documentation comments (///)"
    }
  ]
}
```

## 🎯 Pattern Writing Tips

### Common Patterns

**Match class/struct/enum declarations:**
```regex
(class|struct|enum)\\s+([A-Z]\\w*)\\s*[:{]
```

**Match function declarations:**
```regex
func\\s+(\\w+)\\s*\\(
```

**Match imports:**
```regex
import\\s+(\\w+)
```

**Match hardcoded strings:**
```regex
\"[^\"]{20,}\"
```

**Match numbers (magic numbers):**
```regex
\\s\\d{2,}\\s
```

### Regex Tips

1. **Escape special characters**: `\\.`, `\\(`, `\\)`, `\\{`, `\\}`
2. **Use word boundaries**: `\\b` for word edges
3. **Capture groups**: `(pattern)` to capture matches
4. **Non-capturing groups**: `(?:pattern)` when you don't need capture
5. **Character classes**: `[A-Z]`, `[0-9]`, `\\w`, `\\s`
6. **Quantifiers**: `*` (0+), `+` (1+), `?` (0-1), `{n,m}` (range)

### Testing Patterns

Use [regex101.com](https://regex101.com) to test your patterns:
1. Select "Python" flavor
2. Paste sample Swift code
3. Test your pattern
4. Verify matches are correct

## 🔍 File Patterns

### Glob Pattern Examples

```
**/*.swift           # All Swift files
**/Domain/**/*.swift # Only Domain layer
**/*Tests.swift      # Only test files
Sources/**/*.swift   # Everything in Sources
```

### Exclude Patterns

```
test|mock|preview    # Skip test, mock, and preview files
generated            # Skip generated code
Test|Mock|Stub       # Skip test-related files
```

## ✅ Best Practices

1. **Start Simple**: Begin with basic patterns and refine
2. **Test Thoroughly**: Use regex101.com before adding rules
3. **Be Specific**: Avoid false positives with precise patterns
4. **Document Well**: Clear messages help developers fix issues
5. **Use Exclusions**: Skip legitimate cases with exclude_pattern
6. **Group Related Rules**: Keep related rules in same file
7. **Choose Right Severity**: ERROR for must-fix, WARNING for should-fix, INFO for nice-to-have

## 🚀 Enabling/Disabling Rules

### Disable Entire Rule Set

Set `"enabled": false` at the top level:

```json
{
  "name": "My Rules",
  "enabled": false,
  "rules": [...]
}
```

### Disable Specific Rule

Remove the rule from the `rules` array or create a separate disabled rules file.

## 📊 Testing Your Rules

After creating a rule file:

```bash
# Run compliance check
make compliance

# Or directly
python3 scripts/check_architecture_compliance.py

# View results
open docs/architecture-compliance.html
```

## 🔗 Additional Resources

- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines)
- [Regex101 - Pattern Testing](https://regex101.com)
- [Python Regex Documentation](https://docs.python.org/3/library/re.html)
- [Architecture Compliance Documentation](../../ARCHITECTURE_COMPLIANCE.md)

## 💡 Rule Ideas

Consider creating rules for:

- **Security**: SQL injection, XSS vulnerabilities, insecure crypto
- **Performance**: Inefficient algorithms, memory leaks
- **Testing**: Test naming conventions, assertion quality
- **Accessibility**: Missing accessibility labels, VoiceOver support
- **Localization**: Hardcoded user-facing strings
- **Threading**: Main thread blocking, race conditions
- **Memory**: Retain cycles, large allocations

---

**Happy Rule Writing!** 🎉

For questions or examples, see the [main documentation](../../ARCHITECTURE_COMPLIANCE.md).
