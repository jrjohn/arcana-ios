//
//  AnalyticsTests.swift
//  arcana-iosTests
//
//  Created by Claude Code
//

import Testing
import Foundation
@testable import arcana_ios

/// Comprehensive tests for Analytics components
struct AnalyticsEventTests {

    // MARK: - AnalyticsEvent Category Tests

    @Test("Screen events have correct category")
    func testScreenEventCategory() {
        #expect(AnalyticsEvent.screenHomeViewed.category == "Screen")
        #expect(AnalyticsEvent.screenUserListViewed.category == "Screen")
        #expect(AnalyticsEvent.screenUserDetailViewed.category == "Screen")
    }

    @Test("User action events have correct category")
    func testUserActionEventCategory() {
        #expect(AnalyticsEvent.userCreateClicked.category == "User Action")
        #expect(AnalyticsEvent.userUpdateClicked.category == "User Action")
        #expect(AnalyticsEvent.userDeleteClicked.category == "User Action")
    }

    @Test("Network events have correct category")
    func testNetworkEventCategory() {
        #expect(AnalyticsEvent.networkRequestStarted.category == "Network")
        #expect(AnalyticsEvent.networkRequestSuccess.category == "Network")
        #expect(AnalyticsEvent.networkRequestFailed.category == "Network")
    }

    @Test("Sync events have correct category")
    func testSyncEventCategory() {
        #expect(AnalyticsEvent.syncStarted.category == "Sync")
        #expect(AnalyticsEvent.syncCompleted.category == "Sync")
        #expect(AnalyticsEvent.syncFailed.category == "Sync")
    }

    @Test("Cache events have correct category")
    func testCacheEventCategory() {
        #expect(AnalyticsEvent.cacheHit.category == "Cache")
        #expect(AnalyticsEvent.cacheMiss.category == "Cache")
        #expect(AnalyticsEvent.cacheCleared.category == "Cache")
    }

    @Test("Error events have correct category")
    func testErrorEventCategory() {
        #expect(AnalyticsEvent.errorOccurred.category == "Error")
        #expect(AnalyticsEvent.validationError.category == "Error")
        #expect(AnalyticsEvent.networkError.category == "Error")
    }

    @Test("Offline events have correct category")
    func testOfflineEventCategory() {
        #expect(AnalyticsEvent.offlineModeEnabled.category == "Offline")
        #expect(AnalyticsEvent.offlineModeDisabled.category == "Offline")
    }

    @Test("Session events have correct category")
    func testSessionEventCategory() {
        #expect(AnalyticsEvent.appLaunched.category == "Session")
        #expect(AnalyticsEvent.sessionStarted.category == "Session")
        #expect(AnalyticsEvent.sessionEnded.category == "Session")
    }

    @Test("List events have correct category")
    func testListEventCategory() {
        #expect(AnalyticsEvent.listRefreshed.category == "List")
        #expect(AnalyticsEvent.listSearched.category == "List")
        #expect(AnalyticsEvent.listFiltered.category == "List")
    }

    @Test("Performance events have correct category")
    func testPerformanceEventCategory() {
        #expect(AnalyticsEvent.pageLoaded.category == "Performance")
        #expect(AnalyticsEvent.apiCallDuration.category == "Performance")
    }

    // MARK: - AnalyticsEventData Tests

    @Test("AnalyticsEventData initialization")
    func testAnalyticsEventDataInit() {
        let sessionId = "session-123"
        let eventData = AnalyticsEventData(
            eventType: .userCreateClicked,
            sessionId: sessionId,
            parameters: ["key": "value"]
        )

        #expect(!eventData.id.isEmpty)
        #expect(eventData.eventType == .userCreateClicked)
        #expect(eventData.sessionId == sessionId)
        #expect(eventData.parameters["key"] == "value")
    }

    @Test("AnalyticsEventData encodes to JSON")
    func testAnalyticsEventDataEncoding() throws {
        let eventData = AnalyticsEventData(
            eventType: .userCreateClicked,
            sessionId: "session-123",
            parameters: ["userId": "1"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(eventData)

        #expect(!data.isEmpty)
    }

    @Test("AnalyticsEventData decodes from JSON")
    func testAnalyticsEventDataDecoding() throws {
        let json = """
        {
            "id": "event-123",
            "eventType": "user_create_clicked",
            "timestamp": 0,
            "sessionId": "session-123",
            "parameters": {"key": "value"}
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let eventData = try decoder.decode(AnalyticsEventData.self, from: json)

        #expect(eventData.id == "event-123")
        #expect(eventData.eventType == .userCreateClicked)
        #expect(eventData.sessionId == "session-123")
        #expect(eventData.parameters["key"] == "value")
    }

    @Test("AnalyticsEventData handles unknown event types")
    func testAnalyticsEventDataUnknownType() throws {
        let json = """
        {
            "id": "event-123",
            "eventType": "unknown_event_type",
            "timestamp": 0,
            "sessionId": "session-123",
            "parameters": {}
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let eventData = try decoder.decode(AnalyticsEventData.self, from: json)

        #expect(eventData.eventType == .errorOccurred)
    }
}
