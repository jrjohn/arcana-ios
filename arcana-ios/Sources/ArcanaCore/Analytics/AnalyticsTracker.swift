//
//  AnalyticsTracker.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation

/// Protocol for analytics tracking
protocol AnalyticsTracker: AnyObject {
    /// Track an event with optional parameters
    func trackEvent(_ event: AnalyticsEvent, params: [String: Any])
    
    /// Track a screen view
    func trackScreen(_ screen: String, params: [String: Any])
    
    /// Track an error
    func trackError(_ error: Error, context: [String: Any])
    
    /// Track an AppError with error codes
    func trackAppError(_ appError: AppError, context: [String: Any])
    
    /// Get current session ID
    var sessionId: String { get }
}

// MARK: - Default Implementations
extension AnalyticsTracker {
    func trackEvent(_ event: AnalyticsEvent) {
        trackEvent(event, params: [:])
    }
    
    func trackScreen(_ screen: String) {
        trackScreen(screen, params: [:])
    }
    
    func trackError(_ error: Error) {
        trackError(error, context: [:])
    }
    
    func trackAppError(_ appError: AppError) {
        trackAppError(appError, context: [:])
    }
}
