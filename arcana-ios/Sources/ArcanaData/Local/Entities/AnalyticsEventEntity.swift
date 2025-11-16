//
//  AnalyticsEventEntity.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation
import SwiftData

/// SwiftData model for persisting analytics events
@Model
final class AnalyticsEventEntity {
    @Attribute(.unique) var id: String
    var eventType: String
    var eventName: String
    var timestamp: Date
    var sessionId: String
    var category: String
    var parametersJSON: String
    var isSynced: Bool
    
    init(
        id: String,
        eventType: String,
        eventName: String,
        timestamp: Date,
        sessionId: String,
        category: String,
        parametersJSON: String,
        isSynced: Bool = false
    ) {
        self.id = id
        self.eventType = eventType
        self.eventName = eventName
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.category = category
        self.parametersJSON = parametersJSON
        self.isSynced = isSynced
    }
    
    /// Convert parameters from JSON string
    var parameters: [String: String] {
        guard let data = parametersJSON.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }
        return dict
    }
    
    /// Create from AnalyticsEvent
    static func from(
        event: AnalyticsEvent,
        sessionId: String,
        params: [String: Any]
    ) -> AnalyticsEventEntity {
        // Convert params to string dictionary and JSON
        let stringParams = params.mapValues { String(describing: $0) }
        let parametersJSON = (try? JSONSerialization.data(withJSONObject: stringParams))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        
        return AnalyticsEventEntity(
            id: UUID().uuidString,
            eventType: "EVENT",
            eventName: event.rawValue,
            timestamp: Date(),
            sessionId: sessionId,
            category: event.category,
            parametersJSON: parametersJSON,
            isSynced: false
        )
    }
    
    /// Create from AppError
    static func fromError(
        error: AppError,
        sessionId: String,
        context: [String: Any]
    ) -> AnalyticsEventEntity {
        var params = context.mapValues { String(describing: $0) }
        
        // Add error code information
        params["error_code"] = error.errorCode.code
        params["error_code_description"] = error.errorCode.description
        params["error_code_category"] = error.errorCode.category
        params["error_message"] = error.message
        params["is_retryable"] = String(error.isRetryable)
        
        let parametersJSON = (try? JSONSerialization.data(withJSONObject: params))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        
        return AnalyticsEventEntity(
            id: UUID().uuidString,
            eventType: "ERROR",
            eventName: "error_occurred",
            timestamp: Date(),
            sessionId: sessionId,
            category: "Error",
            parametersJSON: parametersJSON,
            isSynced: false
        )
    }
}
