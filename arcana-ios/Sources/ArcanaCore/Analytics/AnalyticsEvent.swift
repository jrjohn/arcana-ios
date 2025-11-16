//
//  AnalyticsEvent.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation

/// Comprehensive analytics event types for tracking user behavior
enum AnalyticsEvent: String {
    
    // MARK: - Screen Views
    case screenHomeViewed = "screen_home_viewed"
    case screenUserListViewed = "screen_user_list_viewed"
    case screenUserDetailViewed = "screen_user_detail_viewed"
    case screenUserFormViewed = "screen_user_form_viewed"
    case screenAnalyticsViewed = "screen_analytics_viewed"
    
    // MARK: - User Actions
    case userCreateClicked = "user_create_clicked"
    case userCreateSuccess = "user_create_success"
    case userCreateFailed = "user_create_failed"
    case userUpdateClicked = "user_update_clicked"
    case userUpdateSuccess = "user_update_success"
    case userUpdateFailed = "user_update_failed"
    case userDeleteClicked = "user_delete_clicked"
    case userDeleteSuccess = "user_delete_success"
    case userDeleteFailed = "user_delete_failed"
    case userSelected = "user_selected"
    
    // MARK: - List Actions
    case listRefreshed = "list_refreshed"
    case listScrolled = "list_scrolled"
    case listSearched = "list_searched"
    case listFiltered = "list_filtered"
    case listSorted = "list_sorted"
    
    // MARK: - Network Events
    case networkRequestStarted = "network_request_started"
    case networkRequestSuccess = "network_request_success"
    case networkRequestFailed = "network_request_failed"
    case networkRequestRetried = "network_request_retried"
    
    // MARK: - API Events
    case apiRequestStarted = "api_request_started"
    case apiRequestSucceeded = "api_request_succeeded"
    case apiRequestFailed = "api_request_failed"
    case apiResponseParsed = "api_response_parsed"
    case apiRateLimitHit = "api_rate_limit_hit"
    
    // MARK: - Sync Events
    case syncStarted = "sync_started"
    case syncCompleted = "sync_completed"
    case syncFailed = "sync_failed"
    case backgroundSyncStarted = "background_sync_started"
    case backgroundSyncCompleted = "background_sync_completed"
    
    // MARK: - Cache Events
    case cacheHit = "cache_hit"
    case cacheMiss = "cache_miss"
    case cacheCleared = "cache_cleared"
    case cacheExpired = "cache_expired"
    
    // MARK: - Error Events
    case errorOccurred = "error_occurred"
    case validationError = "validation_error"
    case networkError = "network_error"
    case serverError = "server_error"
    case databaseError = "database_error"
    
    // MARK: - Performance Events
    case pageLoaded = "page_loaded"
    case apiCallDuration = "api_call_duration"
    case databaseQueryDuration = "database_query_duration"
    case screenRenderTime = "screen_render_time"
    
    // MARK: - Offline Events
    case offlineModeEnabled = "offline_mode_enabled"
    case offlineModeDisabled = "offline_mode_disabled"
    case offlineDataAccessed = "offline_data_accessed"
    case pendingChangesQueued = "pending_changes_queued"
    
    // MARK: - Session Events
    case appLaunched = "app_launched"
    case appForegrounded = "app_foregrounded"
    case appBackgrounded = "app_backgrounded"
    case appTerminated = "app_terminated"
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
    
    /// Category for this event
    var category: String {
        let eventName = rawValue
        
        if eventName.hasPrefix("screen_") {
            return "Screen"
        } else if eventName.hasPrefix("user_") {
            return "User Action"
        } else if eventName.hasPrefix("network_") {
            return "Network"
        } else if eventName.hasPrefix("sync_") {
            return "Sync"
        } else if eventName.hasPrefix("cache_") {
            return "Cache"
        } else if eventName.hasPrefix("error_") || eventName.contains("error") {
            return "Error"
        } else if eventName.hasPrefix("offline_") {
            return "Offline"
        } else if eventName.hasPrefix("app_") || eventName.hasPrefix("session_") {
            return "Session"
        } else if eventName.hasPrefix("list_") {
            return "List"
        } else {
            return "Performance"
        }
    }
}

/// Analytics event data structure
struct AnalyticsEventData: Codable, Identifiable {
    let id: String
    let eventType: AnalyticsEvent
    let timestamp: Date
    let sessionId: String
    let parameters: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventType
        case timestamp
        case sessionId
        case parameters
    }
    
    init(
        id: String = UUID().uuidString,
        eventType: AnalyticsEvent,
        timestamp: Date = Date(),
        sessionId: String,
        parameters: [String: String] = [:]
    ) {
        self.id = id
        self.eventType = eventType
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.parameters = parameters
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        let eventTypeString = try container.decode(String.self, forKey: .eventType)
        eventType = AnalyticsEvent(rawValue: eventTypeString) ?? .errorOccurred
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        parameters = try container.decode([String: String].self, forKey: .parameters)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(eventType.rawValue, forKey: .eventType)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(parameters, forKey: .parameters)
    }
}
