//
//  AnalyticsTrackerDependency.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Dependencies
import Foundation

// MARK: - AnalyticsTracker Dependency Key

extension DependencyValues {
    var analyticsTracker: AnalyticsTracker {
        get { self[AnalyticsTrackerKey.self] }
        set { self[AnalyticsTrackerKey.self] = newValue }
    }
}

enum AnalyticsTrackerKey: DependencyKey {
    static let liveValue: AnalyticsTracker = {
        // Note: This will be initialized in the app with the actual ModelContainer
        fatalError("AnalyticsTracker must be set at app launch with actual ModelContainer")
    }()
    
    static let testValue: AnalyticsTracker = MockAnalyticsTracker()
    
    static let previewValue: AnalyticsTracker = MockAnalyticsTracker()
}

// MARK: - Mock AnalyticsTracker

final class MockAnalyticsTracker: AnalyticsTracker {
    var sessionId: String = UUID().uuidString
    var trackEventCallCount = 0
    var trackScreenCallCount = 0
    var trackErrorCallCount = 0
    var trackAppErrorCallCount = 0
    
    var lastEvent: AnalyticsEvent?
    var lastScreen: String?
    var lastError: Error?
    var lastAppError: AppError?
    var lastParams: [String: Any] = [:]
    
    func trackEvent(_ event: AnalyticsEvent, params: [String: Any] = [:]) {
        trackEventCallCount += 1
        lastEvent = event
        lastParams = params
    }
    
    func trackScreen(_ screen: String, params: [String: Any] = [:]) {
        trackScreenCallCount += 1
        lastScreen = screen
        lastParams = params
    }
    
    func trackError(_ error: Error, context: [String: Any] = [:]) {
        trackErrorCallCount += 1
        lastError = error
        lastParams = context
    }
    
    func trackAppError(_ appError: AppError, context: [String: Any] = [:]) {
        trackAppErrorCallCount += 1
        lastAppError = appError
        lastParams = context
    }
}
