//
//  SwiftDataUserDataSource.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation
import SwiftData

/// SwiftData implementation of LocalUserDataSource
final class SwiftDataUserDataSource: LocalUserDataSource {
    
    private let modelContainer: ModelContainer
    private let analyticsTracker: AnalyticsTracker
    
    init(modelContainer: ModelContainer, analyticsTracker: AnalyticsTracker) {
        self.modelContainer = modelContainer
        self.analyticsTracker = analyticsTracker
    }
    
    @MainActor
    private var context: ModelContext {
        modelContainer.mainContext
    }
    
    // MARK: - LocalUserDataSource Implementation
    
    func getUsers() async throws -> [User] {
        return try performQuery {
            let descriptor = FetchDescriptor<UserEntity>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let entities = try context.fetch(descriptor)
            return entities.map { $0.toDomain() }
        }
    }

    func getUser(id: String) async throws -> User {
        return try performQuery {
            let predicate = #Predicate<UserEntity> { entity in
                entity.id == id
            }
            let descriptor = FetchDescriptor<UserEntity>(predicate: predicate)
            
            guard let entity = try context.fetch(descriptor).first else {
                throw AppError.serverError(
                    .E3002_NOT_FOUND,
                    statusCode: 404,
                    message: "User not found"
                )
            }
            
            return entity.toDomain()
        }
    }
    
    func createUser(_ user: User) async throws {
        try performWrite {
            let entity = UserEntity.from(user: user)
            context.insert(entity)
            try context.save()
        }
    }
    
    func updateUser(_ user: User) async throws {
        try performWrite {
            let predicate = #Predicate<UserEntity> { entity in
                entity.id == user.id
            }
            let descriptor = FetchDescriptor<UserEntity>(predicate: predicate)
            
            if let entity = try context.fetch(descriptor).first {
                entity.update(from: user)
                try context.save()
            } else {
                // If doesn't exist, create it
                let entity = UserEntity.from(user: user)
                context.insert(entity)
                try context.save()
            }
        }
    }
    
    func deleteUser(_ user: User) async throws {
        try performWrite {
            let predicate = #Predicate<UserEntity> { entity in
                entity.id == user.id
            }
            let descriptor = FetchDescriptor<UserEntity>(predicate: predicate)
            
            if let entity = try context.fetch(descriptor).first {
                context.delete(entity)
                try context.save()
            }
        }
    }
    
    func saveUsers(_ users: [User]) async throws {
        try performWrite {
            // Delete all existing users
            try context.delete(model: UserEntity.self)
            
            // Insert new users
            for user in users {
                let entity = UserEntity.from(user: user)
                context.insert(entity)
            }
            
            try context.save()
        }
    }
    
    func searchUsers(query: String) async throws -> [User] {
        return try performQuery {
            let lowercasedQuery = query.lowercased()
            
            let predicate = #Predicate<UserEntity> { entity in
                entity.firstName.localizedStandardContains(lowercasedQuery) ||
                entity.lastName.localizedStandardContains(lowercasedQuery) ||
                entity.email.localizedStandardContains(lowercasedQuery)
            }
            
            let descriptor = FetchDescriptor<UserEntity>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.firstName)]
            )
            
            let entities = try context.fetch(descriptor)
            return entities.map { $0.toDomain() }
        }
    }
    
    func clearAll() async throws {
        try performWrite {
            try context.delete(model: UserEntity.self)
            try context.save()
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func performQuery<T>(_ operation: () throws -> T) throws -> T {
        let startTime = Date()
        defer {
            let duration = Date().timeIntervalSince(startTime)
            analyticsTracker.trackEvent(.databaseQueryDuration, params: [
                "duration_ms": Int(duration * 1000)
            ])
        }
        
        do {
            return try operation()
        } catch {
            let appError = AppError.databaseError(
                .E6005_FETCH_FAILED,
                message: "Failed to fetch from database",
                underlyingError: error
            )
            analyticsTracker.trackAppError(appError)
            throw appError
        }
    }
    
    @MainActor
    private func performWrite(_ operation: () throws -> Void) throws {
        let startTime = Date()
        defer {
            let duration = Date().timeIntervalSince(startTime)
            analyticsTracker.trackEvent(.databaseQueryDuration, params: [
                "duration_ms": Int(duration * 1000),
                "operation": "write"
            ])
        }
        
        do {
            try operation()
        } catch {
            let appError = AppError.databaseError(
                .E6004_SAVE_FAILED,
                message: "Failed to save to database",
                underlyingError: error
            )
            analyticsTracker.trackAppError(appError)
            throw appError
        }
    }
}
