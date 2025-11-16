.PHONY: help test test-unit test-ui coverage compliance clean build

# Default target
help:
	@echo "📱 arcana-ios Build & Test Commands"
	@echo ""
	@echo "Available targets:"
	@echo "  make build          - Build project and run compliance check"
	@echo "  make test           - Run all tests with coverage and generate HTML report"
	@echo "  make test-unit      - Run only unit tests with coverage"
	@echo "  make test-ui        - Run only UI tests"
	@echo "  make coverage       - Generate coverage reports from latest test run"
	@echo "  make compliance     - Run architecture compliance check"
	@echo "  make clean          - Clean build artifacts and test results"
	@echo ""

# Run all tests with coverage and auto-generate HTML report
test:
	@echo "🧪 Running all tests with coverage..."
	@xcodebuild test \
		-scheme arcana-ios \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-enableCodeCoverage YES \
		-derivedDataPath DerivedData \
		| tee test_output.log
	@echo ""
	@echo "📊 Generating coverage reports..."
	@./scripts/generate_coverage_html.sh
	@echo ""
	@echo "✅ Tests complete! Opening coverage report..."
	@open docs/test-coverage.html

# Run only unit tests with coverage
test-unit:
	@echo "🧪 Running unit tests with coverage..."
	@xcodebuild test \
		-scheme arcana-ios \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-enableCodeCoverage YES \
		-only-testing:arcana-iosTests \
		-derivedDataPath DerivedData \
		| tee unit_test_output.log
	@echo ""
	@echo "📊 Generating coverage reports..."
	@./scripts/generate_coverage_html.sh
	@echo ""
	@echo "✅ Unit tests complete! Opening coverage report..."
	@open docs/test-coverage.html

# Run only UI tests
test-ui:
	@echo "🧪 Running UI tests..."
	@xcodebuild test \
		-scheme arcana-ios \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-only-testing:arcana-iosUITests \
		-derivedDataPath DerivedData \
		| tee ui_test_output.log
	@echo ""
	@echo "✅ UI tests complete!"

# Generate coverage reports from latest test run
coverage:
	@echo "📊 Generating coverage reports from latest test run..."
	@./scripts/generate_coverage_html.sh
	@echo ""
	@echo "✅ Coverage reports generated! Opening HTML report..."
	@open docs/test-coverage.html

# Build project and run compliance check
build:
	@echo "🏗️  Building project..."
	@xcodebuild build \
		-scheme arcana-ios \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-derivedDataPath DerivedData \
		| tee build_output.log
	@echo ""
	@echo "🔍 Running architecture compliance check..."
	@python3 scripts/check_architecture_compliance.py
	@echo ""
	@echo "✅ Build and compliance check complete! Opening report..."
	@open docs/architecture-compliance.html

# Run architecture compliance check
compliance:
	@echo "🔍 Running architecture compliance check..."
	@python3 scripts/check_architecture_compliance.py
	@echo ""
	@echo "✅ Opening compliance report..."
	@open docs/architecture-compliance.html

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf DerivedData
	@rm -f test_output.log unit_test_output.log ui_test_output.log build_output.log
	@rm -f coverage_report.json coverage_report.txt coverage_report.html
	@rm -f docs/compliance-data.json
	@echo "✅ Clean complete!"
