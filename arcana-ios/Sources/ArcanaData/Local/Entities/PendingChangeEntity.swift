//
//  PendingChangeEntity.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation
import SwiftData

/// Tracks pending changes to be synced when network is available
@Model
final class PendingChangeEntity {
    @Attribute(.unique) var id: String
    var userId: String
    var operation: String // "create", "update", "delete"
    var userDataJSON: String // Serialized User object
    var timestamp: Date
    var retryCount: Int
    var lastError: String?

    init(
        id: String = UUID().uuidString,
        userId: String,
        operation: String,
        userDataJSON: String,
        timestamp: Date = Date(),
        retryCount: Int = 0,
        lastError: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.operation = operation
        self.userDataJSON = userDataJSON
        self.timestamp = timestamp
        self.retryCount = retryCount
        self.lastError = lastError
    }

    /// Convert to domain model
    func toPendingChange() -> PendingChange? {
        guard let data = userDataJSON.data(using: .utf8),
              let user = try? JSONDecoder().decode(User.self, from: data),
              let op = PendingChangeOperation(rawValue: operation) else {
            return nil
        }

        return PendingChange(
            id: id,
            userId: userId,
            operation: op,
            user: user,
            timestamp: timestamp,
            retryCount: retryCount,
            lastError: lastError
        )
    }

    /// Create from domain model
    static func from(change: PendingChange) -> PendingChangeEntity? {
        guard let data = try? JSONEncoder().encode(change.user),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }

        return PendingChangeEntity(
            id: change.id,
            userId: change.userId,
            operation: change.operation.rawValue,
            userDataJSON: json,
            timestamp: change.timestamp,
            retryCount: change.retryCount,
            lastError: change.lastError
        )
    }
}

/// Domain model for pending changes
struct PendingChange: Identifiable {
    let id: String
    let userId: String
    let operation: PendingChangeOperation
    let user: User
    let timestamp: Date
    var retryCount: Int
    var lastError: String?
}

/// Operations that can be queued for offline sync
enum PendingChangeOperation: String, Codable {
    case create
    case update
    case delete
}
