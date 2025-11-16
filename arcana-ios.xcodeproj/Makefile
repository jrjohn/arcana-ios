# Arcana iOS - Swift Package Manager Makefile

.PHONY: help build test clean format lint resolve update

# Default target
help:
	@echo "Arcana iOS - Swift Package Manager Commands"
	@echo ""
	@echo "Usage:"
	@echo "  make build          - Build all targets"
	@echo "  make test           - Run all tests"
	@echo "  make test-core      - Run Core module tests"
	@echo "  make test-domain    - Run Domain module tests"
	@echo "  make test-data      - Run Data module tests"
	@echo "  make test-ui        - Run Presentation module tests"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make resolve        - Resolve package dependencies"
	@echo "  make update         - Update package dependencies"
	@echo "  make coverage       - Generate test coverage report"
	@echo "  make lint           - Run SwiftLint (if installed)"
	@echo "  make format         - Format code with swift-format (if installed)"
	@echo "  make docs           - Generate documentation"
	@echo "  make setup          - Initial setup (resolve dependencies)"

# Build all targets
build:
	@echo "🏗️  Building all targets..."
	swift build

# Build in release mode
build-release:
	@echo "🏗️  Building in release mode..."
	swift build -c release

# Run all tests
test:
	@echo "🧪 Running all tests..."
	swift test

# Run Core module tests
test-core:
	@echo "🧪 Running Core module tests..."
	swift test --filter ArcanaCoreTests

# Run Domain module tests
test-domain:
	@echo "🧪 Running Domain module tests..."
	swift test --filter ArcanaDomainTests

# Run Data module tests
test-data:
	@echo "🧪 Running Data module tests..."
	swift test --filter ArcanaDataTests

# Run Presentation module tests
test-ui:
	@echo "🧪 Running Presentation module tests..."
	swift test --filter ArcanaPresentationTests

# Generate test coverage
coverage:
	@echo "📊 Generating test coverage..."
	swift test --enable-code-coverage
	@echo "Coverage report generated"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	swift package clean
	rm -rf .build
	rm -rf .swiftpm
	@echo "✅ Clean complete"

# Resolve dependencies
resolve:
	@echo "📦 Resolving dependencies..."
	swift package resolve
	@echo "✅ Dependencies resolved"

# Update dependencies
update:
	@echo "📦 Updating dependencies..."
	swift package update
	@echo "✅ Dependencies updated"

# Reset dependencies
reset:
	@echo "🔄 Resetting dependencies..."
	swift package reset
	@echo "✅ Dependencies reset"

# Show dependency graph
graph:
	@echo "📊 Showing dependency graph..."
	swift package show-dependencies

# Lint code (requires SwiftLint)
lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		echo "🔍 Linting code..."; \
		swiftlint; \
	else \
		echo "⚠️  SwiftLint not installed. Install with: brew install swiftlint"; \
	fi

# Format code (requires swift-format)
format:
	@if command -v swift-format >/dev/null 2>&1; then \
		echo "✨ Formatting code..."; \
		swift-format format -i -r Sources/; \
		swift-format format -i -r Tests/; \
		echo "✅ Code formatted"; \
	else \
		echo "⚠️  swift-format not installed. Install with: brew install swift-format"; \
	fi

# Generate documentation
docs:
	@echo "📚 Generating documentation..."
	@if command -v swift-doc >/dev/null 2>&1; then \
		swift-doc generate Sources/ --module-name ArcanaIOS --output docs/; \
		echo "✅ Documentation generated in docs/"; \
	else \
		echo "⚠️  swift-doc not installed. Install with: brew install swift-doc"; \
	fi

# Setup project
setup:
	@echo "🚀 Setting up Arcana iOS..."
	@make resolve
	@echo "✅ Setup complete!"

# Open in Xcode
xcode:
	@echo "🔨 Opening in Xcode..."
	open Package.swift

# Print package info
info:
	@echo "📦 Package Information:"
	@swift package dump-package | python3 -m json.tool

# Validate package
validate:
	@echo "✅ Validating package..."
	swift package validate

# Archive for distribution
archive:
	@echo "📦 Creating archive..."
	swift build -c release
	@echo "✅ Archive created in .build/release/"

# Show package structure
tree:
	@echo "📁 Package Structure:"
	@tree -I '.build|.swiftpm' -L 3

# Quick build and test
quick:
	@make build
	@make test

# Full CI pipeline
ci:
	@echo "🔄 Running CI pipeline..."
	@make clean
	@make resolve
	@make build
	@make test
	@make lint || true
	@echo "✅ CI pipeline complete!"
