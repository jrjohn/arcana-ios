//
//  MockAnalyticsTracker.swift
//  arcana-iosTests
//
//  Created by Claude Code
//

import Foundation
@testable import arcana_ios

/// Mock implementation of AnalyticsTracker for testing
final class MockAnalyticsTracker: AnalyticsTracker {
    var trackedEvents: [(event: AnalyticsEvent, params: [String: Any])] = []
    var trackedScreens: [(screen: String, params: [String: Any])] = []
    var trackedErrors: [(error: Error, context: [String: Any])] = []
    var trackedAppErrors: [(appError: AppError, context: [String: Any])] = []

    let sessionId: String = "mock-session-id"

    func trackEvent(_ event: AnalyticsEvent, params: [String: Any]) {
        trackedEvents.append((event, params))
    }

    func trackScreen(_ screen: String, params: [String: Any]) {
        trackedScreens.append((screen, params))
    }

    func trackError(_ error: Error, context: [String: Any]) {
        trackedErrors.append((error, context))
    }

    func trackAppError(_ appError: AppError, context: [String: Any]) {
        trackedAppErrors.append((appError, context))
    }

    func reset() {
        trackedEvents.removeAll()
        trackedScreens.removeAll()
        trackedErrors.removeAll()
        trackedAppErrors.removeAll()
    }
}
