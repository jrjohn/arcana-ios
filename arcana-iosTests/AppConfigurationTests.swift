//
//  AppConfigurationTests.swift
//  arcana-iosTests
//
//  Tests for AppConfiguration and AppConstants
//

import Testing
import Foundation
@testable import arcana_ios

/// Tests for AppConfiguration singleton
struct AppConfigurationTests {

    // MARK: - Environment Tests

    @Test("AppConfiguration has a valid environment")
    func testEnvironment() {
        let config = AppConfiguration.shared
        #expect(config.environment == .development || config.environment == .staging || config.environment == .production)
    }

    @Test("Environment provides correct config file names")
    func testEnvironmentConfigFileNames() {
        #expect(AppConfiguration.Environment.development.configFileName == "Config-Development")
        #expect(AppConfiguration.Environment.staging.configFileName == "Config-Staging")
        #expect(AppConfiguration.Environment.production.configFileName == "Config-Production")
    }

    @Test("Environment raw values are correct")
    func testEnvironmentRawValues() {
        #expect(AppConfiguration.Environment.development.rawValue == "Development")
        #expect(AppConfiguration.Environment.staging.rawValue == "Staging")
        #expect(AppConfiguration.Environment.production.rawValue == "Production")
    }

    // MARK: - API Configuration Tests

    @Test("AppConfiguration has a valid API base URL")
    func testApiBaseURL() {
        let url = AppConfiguration.shared.apiBaseURL
        #expect(!url.isEmpty)
        #expect(url.hasPrefix("https://") || url.hasPrefix("http://"))
    }

    @Test("AppConfiguration has a positive API timeout")
    func testApiTimeout() {
        let timeout = AppConfiguration.shared.apiTimeout
        #expect(timeout > 0)
    }

    @Test("AppConfiguration has a valid max retries count")
    func testApiMaxRetries() {
        let retries = AppConfiguration.shared.apiMaxRetries
        #expect(retries >= 0)
    }

    // MARK: - Endpoint Tests

    @Test("AppConfiguration has non-empty endpoints")
    func testEndpoints() {
        let config = AppConfiguration.shared
        #expect(!config.usersEndpoint.isEmpty)
        #expect(!config.userEndpoint.isEmpty)
        #expect(!config.createUserEndpoint.isEmpty)
        #expect(!config.updateUserEndpoint.isEmpty)
        #expect(!config.deleteUserEndpoint.isEmpty)
    }

    // MARK: - Pagination Tests

    @Test("AppConfiguration has valid pagination defaults")
    func testPagination() {
        let config = AppConfiguration.shared
        #expect(config.defaultPageSize > 0)
        #expect(config.maxPageSize >= config.defaultPageSize)
    }

    // MARK: - Cache Configuration Tests

    @Test("AppConfiguration has valid cache settings")
    func testCacheConfiguration() {
        let config = AppConfiguration.shared
        #expect(config.cacheMaxSize > 0)
        #expect(config.cacheTTL > 0)
    }

    // MARK: - Analytics Tests

    @Test("AppConfiguration has analytics settings")
    func testAnalyticsConfiguration() {
        let config = AppConfiguration.shared
        // Just verify the properties are accessible
        let _ = config.analyticsEnabled
        let _ = config.analyticsDebugMode
        let _ = config.trackScreenViews
        let _ = config.trackUserActions
    }

    // MARK: - Feature Flags Tests

    @Test("AppConfiguration feature flags are accessible")
    func testFeatureFlags() {
        let config = AppConfiguration.shared
        let _ = config.offlineModeEnabled
        let _ = config.autoSyncEnabled
        let _ = config.pullToRefreshEnabled
        let _ = config.searchEnabled
        let _ = config.deleteEnabled
        let _ = config.editEnabled
    }

    // MARK: - UI Configuration Tests

    @Test("AppConfiguration UI settings are positive")
    func testUIConfiguration() {
        let config = AppConfiguration.shared
        #expect(config.animationDuration > 0)
        #expect(config.debounceDelay > 0)
        #expect(config.toastDuration > 0)
    }

    // MARK: - App Information Tests

    @Test("AppConfiguration app info is non-empty")
    func testAppInformation() {
        let config = AppConfiguration.shared
        #expect(!config.appName.isEmpty)
        #expect(!config.appVersion.isEmpty)
        #expect(!config.buildNumber.isEmpty)
        #expect(!config.logLevel.isEmpty)
    }

    // MARK: - Logging Configuration Tests

    @Test("AppConfiguration logging is accessible")
    func testLoggingConfiguration() {
        let logging = AppConfiguration.shared.logging
        #expect(!logging.logLevel.isEmpty)
        let _ = logging.enabled
        let _ = logging.logHeaders
        let _ = logging.logBody
    }

    // MARK: - Custom Value Tests

    @Test("AppConfiguration value(for:) returns nil for unknown keys")
    func testCustomValueForUnknownKey() {
        let value: String? = AppConfiguration.shared.value(for: "NonExistent.Key")
        #expect(value == nil)
    }

    @Test("AppConfiguration isFeatureEnabled returns false for unknown features")
    func testIsFeatureEnabledForUnknown() {
        let enabled = AppConfiguration.shared.isFeatureEnabled("UnknownFeature")
        #expect(enabled == false)
    }
}

/// Tests for AppConstants type alias
struct AppConstantsTests {

    @Test("AppConstants.API provides valid URL")
    func testAPIConstants() {
        let url = AppConstants.API.baseURL
        #expect(!url.isEmpty)
        let timeout = AppConstants.API.timeout
        #expect(timeout > 0)
        let retries = AppConstants.API.maxRetries
        #expect(retries >= 0)
    }

    @Test("AppConstants.Pagination provides valid sizes")
    func testPaginationConstants() {
        #expect(AppConstants.Pagination.defaultPageSize > 0)
        #expect(AppConstants.Pagination.maxPageSize >= AppConstants.Pagination.defaultPageSize)
    }

    @Test("AppConstants.Cache provides valid values")
    func testCacheConstants() {
        #expect(AppConstants.Cache.maxSize > 0)
        #expect(AppConstants.Cache.ttl > 0)
    }

    @Test("AppConstants.Features provides valid flags")
    func testFeatureConstants() {
        let _ = AppConstants.Features.offlineMode
        let _ = AppConstants.Features.autoSync
        let _ = AppConstants.Features.pullToRefresh
        let _ = AppConstants.Features.search
        let _ = AppConstants.Features.delete
        let _ = AppConstants.Features.edit
    }

    @Test("AppConstants.UI provides valid durations")
    func testUIConstants() {
        #expect(AppConstants.UI.animationDuration > 0)
        #expect(AppConstants.UI.debounceDelay > 0)
        #expect(AppConstants.UI.toastDuration > 0)
    }

    @Test("AppConstants.Logging provides values")
    func testLoggingConstants() {
        let _ = AppConstants.Logging.enabled
        let _ = AppConstants.Logging.logHeaders
        let _ = AppConstants.Logging.logBody
        let _ = AppConstants.Logging.logLevel
    }
}
