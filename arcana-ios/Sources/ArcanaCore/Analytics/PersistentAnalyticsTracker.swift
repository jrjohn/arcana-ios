//
//  PersistentAnalyticsTracker.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation
import SwiftData
import OSLog

/// Analytics tracker that persists events to SwiftData
final class PersistentAnalyticsTracker: AnalyticsTracker {
    
    private let modelContainer: ModelContainer
    private(set) var sessionId: String
    private let logger = Logger(subsystem: "com.example.arcana.ios", category: "Analytics")
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.sessionId = UUID().uuidString
        
        // Log session start
        logger.info("📊 Analytics session started: \(self.sessionId)")
    }
    
    @MainActor
    private var context: ModelContext {
        modelContainer.mainContext
    }
    
    // MARK: - AnalyticsTracker Implementation
    
    func trackEvent(_ event: AnalyticsEvent, params: [String: Any] = [:]) {
        Task { @MainActor in
            let entity = AnalyticsEventEntity.from(
                event: event,
                sessionId: sessionId,
                params: params
            )
            
            context.insert(entity)
            
            do {
                try context.save()
                logger.debug("📊 Event tracked: \(event.rawValue) - \(params)")
            } catch {
                logger.error("❌ Failed to save analytics event: \(error.localizedDescription)")
            }
        }
    }
    
    func trackScreen(_ screen: String, params: [String: Any] = [:]) {
        var screenParams = params
        screenParams["screen_name"] = screen
        
        // Determine which screen event to use
        let event: AnalyticsEvent
        switch screen.lowercased() {
        case let s where s.contains("home"):
            event = .screenHomeViewed
        case let s where s.contains("list"):
            event = .screenUserListViewed
        case let s where s.contains("detail"):
            event = .screenUserDetailViewed
        case let s where s.contains("form"):
            event = .screenUserFormViewed
        case let s where s.contains("analytics"):
            event = .screenAnalyticsViewed
        default:
            event = .screenHomeViewed
        }
        
        trackEvent(event, params: screenParams)
    }
    
    func trackError(_ error: Error, context: [String: Any] = [:]) {
        let appError = AppError.from(error)
        trackAppError(appError, context: context)
    }
    
    func trackAppError(_ appError: AppError, context: [String: Any] = [:]) {
        Task { @MainActor in
            let entity = AnalyticsEventEntity.fromError(
                error: appError,
                sessionId: sessionId,
                context: context
            )
            
            self.context.insert(entity)
            
            do {
                try self.context.save()
                logger.error("❌ Error tracked: [\(appError.errorCode.code)] \(appError.message)")
            } catch {
                logger.error("❌ Failed to save error event: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Query Methods
    
    /// Get all analytics events
    func getAllEvents() async throws -> [AnalyticsEventEntity] {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    let descriptor = FetchDescriptor<AnalyticsEventEntity>(
                        sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
                    )
                    let events = try context.fetch(descriptor)
                    continuation.resume(returning: events)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get events by category
    func getEvents(category: String) async throws -> [AnalyticsEventEntity] {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    let predicate = #Predicate<AnalyticsEventEntity> { event in
                        event.category == category
                    }
                    let descriptor = FetchDescriptor<AnalyticsEventEntity>(
                        predicate: predicate,
                        sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
                    )
                    let events = try context.fetch(descriptor)
                    continuation.resume(returning: events)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get error events
    func getErrorEvents() async throws -> [AnalyticsEventEntity] {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    let predicate = #Predicate<AnalyticsEventEntity> { event in
                        event.eventType == "ERROR"
                    }
                    let descriptor = FetchDescriptor<AnalyticsEventEntity>(
                        predicate: predicate,
                        sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
                    )
                    let events = try context.fetch(descriptor)
                    continuation.resume(returning: events)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get events count
    func getEventsCount() async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    let descriptor = FetchDescriptor<AnalyticsEventEntity>()
                    let events = try context.fetch(descriptor)
                    continuation.resume(returning: events.count)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Clear all analytics events
    func clearAllEvents() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task { @MainActor in
                do {
                    try context.delete(model: AnalyticsEventEntity.self)
                    try context.save()
                    logger.info("📊 All analytics events cleared")
                    continuation.resume()
                } catch {
                    logger.error("❌ Failed to clear analytics events: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Mark events as synced
    func markEventsSynced(_ eventIds: [String]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task { @MainActor in
                do {
                    for eventId in eventIds {
                        let predicate = #Predicate<AnalyticsEventEntity> { event in
                            event.id == eventId
                        }
                        let descriptor = FetchDescriptor<AnalyticsEventEntity>(predicate: predicate)
                        
                        if let event = try context.fetch(descriptor).first {
                            event.isSynced = true
                        }
                    }
                    
                    try context.save()
                    logger.info("📊 Marked \(eventIds.count) events as synced")
                    continuation.resume()
                } catch {
                    logger.error("❌ Failed to mark events as synced: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Session Management
    
    func startNewSession() {
        sessionId = UUID().uuidString
        logger.info("📊 New analytics session started: \(self.sessionId)")
        trackEvent(.sessionStarted)
    }
    
    func endSession() {
        trackEvent(.sessionEnded)
        logger.info("📊 Analytics session ended: \(self.sessionId)")
    }
}
