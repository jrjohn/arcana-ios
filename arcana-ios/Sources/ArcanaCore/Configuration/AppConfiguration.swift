//
//  AppConfiguration.swift
//  arcana-ios
//
//  Centralized configuration management
//

import Foundation

/// Main configuration manager for the app
final class AppConfiguration {
    /// Shared singleton instance
    static let shared = AppConfiguration()

    /// Current environment
    enum Environment: String {
        case development = "Development"
        case staging = "Staging"
        case production = "Production"

        var configFileName: String {
            switch self {
            case .development:
                return "Config-Development"
            case .staging:
                return "Config-Staging"
            case .production:
                return "Config-Production"
            }
        }
    }

    // MARK: - Properties

    private let config: [String: Any]
    private let environmentConfig: [String: Any]?

    /// Current environment
    let environment: Environment

    // MARK: - API Configuration

    var apiBaseURL: String {
        getString(for: "API.BaseURL") ?? "https://reqres.in/api"
    }

    var apiTimeout: TimeInterval {
        TimeInterval(getInt(for: "API.Timeout") ?? 30)
    }

    var apiMaxRetries: Int {
        getInt(for: "API.MaxRetries") ?? 3
    }

    // MARK: - Endpoints

    var usersEndpoint: String {
        getString(for: "Endpoints.Users") ?? "/users"
    }

    var userEndpoint: String {
        getString(for: "Endpoints.User") ?? "/users/%@"
    }

    var createUserEndpoint: String {
        getString(for: "Endpoints.CreateUser") ?? "/users"
    }

    var updateUserEndpoint: String {
        getString(for: "Endpoints.UpdateUser") ?? "/users/%@"
    }

    var deleteUserEndpoint: String {
        getString(for: "Endpoints.DeleteUser") ?? "/users/%@"
    }

    // MARK: - Pagination

    var defaultPageSize: Int {
        getInt(for: "Pagination.DefaultPageSize") ?? 6
    }

    var maxPageSize: Int {
        getInt(for: "Pagination.MaxPageSize") ?? 12
    }

    // MARK: - Cache Configuration

    var cacheMaxSize: Int {
        getInt(for: "Cache.MaxSize") ?? 100
    }

    var cacheTTL: TimeInterval {
        TimeInterval(getInt(for: "Cache.TTL") ?? 300)
    }

    var cacheEnabled: Bool {
        getBool(for: "Cache.Enabled") ?? true
    }

    // MARK: - Analytics

    var analyticsEnabled: Bool {
        getBool(for: "Analytics.Enabled") ?? true
    }

    var analyticsDebugMode: Bool {
        getBool(for: "Analytics.DebugMode") ?? false
    }

    var trackScreenViews: Bool {
        getBool(for: "Analytics.TrackScreenViews") ?? true
    }

    var trackUserActions: Bool {
        getBool(for: "Analytics.TrackUserActions") ?? true
    }

    // MARK: - Feature Flags

    var offlineModeEnabled: Bool {
        getBool(for: "Features.OfflineMode") ?? true
    }

    var autoSyncEnabled: Bool {
        getBool(for: "Features.AutoSync") ?? true
    }

    var pullToRefreshEnabled: Bool {
        getBool(for: "Features.PullToRefresh") ?? true
    }

    var searchEnabled: Bool {
        getBool(for: "Features.SearchEnabled") ?? true
    }

    var deleteEnabled: Bool {
        getBool(for: "Features.DeleteEnabled") ?? true
    }

    var editEnabled: Bool {
        getBool(for: "Features.EditEnabled") ?? true
    }

    // MARK: - UI Configuration

    var animationDuration: TimeInterval {
        getDouble(for: "UI.AnimationDuration") ?? 0.3
    }

    var debounceDelay: TimeInterval {
        getDouble(for: "UI.DebounceDelay") ?? 0.3
    }

    var toastDuration: TimeInterval {
        getDouble(for: "UI.ToastDuration") ?? 2.0
    }

    var loadingIndicatorDelay: TimeInterval {
        getDouble(for: "UI.LoadingIndicatorDelay") ?? 0.5
    }

    // MARK: - App Information

    var appName: String {
        getString(for: "App.Name") ?? "Arcana"
    }

    var appVersion: String {
        getString(for: "App.Version") ?? Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var buildNumber: String {
        getString(for: "App.BuildNumber") ?? Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var logLevel: String {
        getString(for: "App.LogLevel") ?? "Info"
    }

    // MARK: - Initialization

    private init() {
        // Determine environment from build configuration
        #if DEBUG
        self.environment = .development
        #else
        self.environment = .production
        #endif

        // Load base configuration
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
            self.config = dict
        } else {
            self.config = [:]
            print("⚠️ Warning: Could not load Config.plist")
        }

        // Load environment-specific configuration
        if let envPath = Bundle.main.path(forResource: environment.configFileName, ofType: "plist"),
           let envDict = NSDictionary(contentsOfFile: envPath) as? [String: Any] {
            self.environmentConfig = envDict
        } else {
            self.environmentConfig = nil
            print("⚠️ Warning: Could not load \(environment.configFileName).plist")
        }

        logConfiguration()
    }

    // MARK: - Helper Methods

    private func getValue(for keyPath: String) -> Any? {
        // First check environment-specific config
        if let value = environmentConfig?.valueForKeyPath(keyPath) {
            return value
        }

        // Fall back to base config
        return config.valueForKeyPath(keyPath)
    }

    private func getString(for keyPath: String) -> String? {
        getValue(for: keyPath) as? String
    }

    private func getInt(for keyPath: String) -> Int? {
        getValue(for: keyPath) as? Int
    }

    private func getBool(for keyPath: String) -> Bool? {
        getValue(for: keyPath) as? Bool
    }

    private func getDouble(for keyPath: String) -> Double? {
        getValue(for: keyPath) as? Double
    }

    private func logConfiguration() {
        #if DEBUG
        print("🔧 AppConfiguration Loaded")
        print("   Environment: \(environment.rawValue)")
        print("   API Base URL: \(apiBaseURL)")
        print("   Analytics Enabled: \(analyticsEnabled)")
        print("   Debug Mode: \(analyticsDebugMode)")
        #endif
    }

    // MARK: - Public Methods

    /// Get custom configuration value
    func value<T>(for keyPath: String) -> T? {
        getValue(for: keyPath) as? T
    }

    /// Check if feature is enabled
    func isFeatureEnabled(_ feature: String) -> Bool {
        getBool(for: "Features.\(feature)") ?? false
    }
}

// MARK: - Dictionary Extension for Key Path

private extension Dictionary {
    func valueForKeyPath(_ keyPath: String) -> Any? {
        let keys = keyPath.components(separatedBy: ".")
        var current: Any? = self

        for key in keys {
            guard let dict = current as? [String: Any] else {
                return nil
            }
            current = dict[key]
        }

        return current
    }
}

// MARK: - Convenience Type Aliases

typealias Config = AppConfiguration

// MARK: - Constants Helper

enum AppConstants {
    /// API related constants
    enum API {
        static var baseURL: String { Config.shared.apiBaseURL }
        static var timeout: TimeInterval { Config.shared.apiTimeout }
        static var maxRetries: Int { Config.shared.apiMaxRetries }
    }

    /// Pagination constants
    enum Pagination {
        static var defaultPageSize: Int { Config.shared.defaultPageSize }
        static var maxPageSize: Int { Config.shared.maxPageSize }
    }

    /// Cache constants
    enum Cache {
        static var maxSize: Int { Config.shared.cacheMaxSize }
        static var ttl: TimeInterval { Config.shared.cacheTTL }
        static var enabled: Bool { Config.shared.cacheEnabled }
    }

    /// Feature flags
    enum Features {
        static var offlineMode: Bool { Config.shared.offlineModeEnabled }
        static var autoSync: Bool { Config.shared.autoSyncEnabled }
        static var pullToRefresh: Bool { Config.shared.pullToRefreshEnabled }
        static var search: Bool { Config.shared.searchEnabled }
        static var delete: Bool { Config.shared.deleteEnabled }
        static var edit: Bool { Config.shared.editEnabled }
    }

    /// UI constants
    enum UI {
        static var animationDuration: TimeInterval { Config.shared.animationDuration }
        static var debounceDelay: TimeInterval { Config.shared.debounceDelay }
        static var toastDuration: TimeInterval { Config.shared.toastDuration }
        static var loadingDelay: TimeInterval { Config.shared.loadingIndicatorDelay }
    }
}
