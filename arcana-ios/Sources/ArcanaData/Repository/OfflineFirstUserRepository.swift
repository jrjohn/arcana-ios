//
//  OfflineFirstUserRepository.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation
import LRUCache
import SwiftData
import Combine

/// Offline-first repository implementation with caching and sync
final class OfflineFirstUserRepository: UserRepository {

    // MARK: - Dependencies
    private let localDataSource: LocalUserDataSource
    private let remoteDataSource: RemoteUserDataSource
    private let cache: LRUCache<String, User>
    private let analyticsTracker: AnalyticsTracker
    private let modelContext: ModelContext

    // MARK: - Constants
    private let cacheCapacity = 100

    // MARK: - Offline Queue
    private var isSyncing = false
    private var networkCancellable: AnyCancellable?

    init(
        localDataSource: LocalUserDataSource,
        remoteDataSource: RemoteUserDataSource,
        analyticsTracker: AnalyticsTracker,
        modelContext: ModelContext
    ) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
        self.cache = LRUCache()
        self.cache.countLimit = cacheCapacity
        self.analyticsTracker = analyticsTracker
        self.modelContext = modelContext

        // Start monitoring network connectivity
        setupNetworkMonitoring()
    }
    
    // MARK: - UserRepository Implementation
    
    func getUsers() async throws -> [User] {
        // 1. Try cache first
        let cachedUsers = Array(cache.values)
        if !cachedUsers.isEmpty {
            analyticsTracker.trackEvent(.cacheHit, params: [
                "operation": "getUsers",
                "count": cachedUsers.count
            ])

            // Sync in background
            Task.detached { [weak self] in
                try? await self?.syncUsersInBackground()
            }

            return cachedUsers
        }

        analyticsTracker.trackEvent(.cacheMiss, params: ["operation": "getUsers"])

        // 2. Try local database
        do {
            let localUsers = try await localDataSource.getUsers()
            if !localUsers.isEmpty {
                // Update cache
                for user in localUsers {
                    cache.setValue(user, forKey: user.id)
                }

                // Sync in background
                Task.detached { [weak self] in
                    try? await self?.syncUsersInBackground()
                }

                return localUsers
            }
        } catch {
            // Log but don't fail - we'll try remote
            analyticsTracker.trackError(error, context: [
                "operation": "getUsers",
                "source": "local"
            ])
        }

        // 3. Fetch from remote
        return try await fetchUsersFromRemote()
    }

    func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User> {
        // Fetch paginated data from remote
        do {
            let result = try await remoteDataSource.getUsers(page: page, perPage: perPage)

            // Cache the users from this page
            for user in result.items {
                cache.setValue(user, forKey: user.id)
            }

            // Save to local database
            if page == 1 {
                // First page - replace all
                try await localDataSource.saveUsers(result.items)
            } else {
                // Subsequent pages - append
                for user in result.items {
                    try? await localDataSource.updateUser(user)
                }
            }

            analyticsTracker.trackEvent(.pageLoaded, params: [
                "page": page,
                "per_page": perPage,
                "total_pages": result.totalPages
            ])

            return result
        } catch {
            let appError = AppError.from(error)

            // If offline and first page, try to use local data
            if case .networkError(.E1000_NO_CONNECTION, _, _, _) = appError, page == 1 {
                analyticsTracker.trackEvent(.offlineModeEnabled)

                let localUsers = try await localDataSource.getUsers()
                let pageUsers = Array(localUsers.prefix(perPage))

                return PaginatedResult(
                    items: pageUsers,
                    currentPage: 1,
                    totalPages: (localUsers.count + perPage - 1) / perPage,
                    hasMore: localUsers.count > perPage
                )
            }

            throw appError
        }
    }
    
    func getUser(id: String) async throws -> User {
        // 1. Try cache first
        if let cachedUser = cache.value(forKey: id) {
            analyticsTracker.trackEvent(.cacheHit, params: [
                "operation": "getUser",
                "userId": id
            ])
            return cachedUser
        }

        analyticsTracker.trackEvent(.cacheMiss, params: [
            "operation": "getUser",
            "userId": id
        ])

        // 2. Try local database
        do {
            let localUser = try await localDataSource.getUser(id: id)
            cache.setValue(localUser, forKey: id)
            return localUser
        } catch {
            // If not found locally, try remote
            analyticsTracker.trackError(error, context: [
                "operation": "getUser",
                "source": "local",
                "userId": id
            ])
        }

        // 3. Fetch from remote
        let remoteUser = try await remoteDataSource.getUser(id: id)

        // Save to local and cache
        try await localDataSource.updateUser(remoteUser)
        cache.setValue(remoteUser, forKey: id)

        return remoteUser
    }
    
    func createUser(_ user: User) async throws -> User {
        // 1. Optimistic update - save locally first
        try await localDataSource.createUser(user)
        cache.setValue(user, forKey: user.id)

        // 2. Try to sync with remote
        do {
            let createdUser = try await remoteDataSource.createUser(user)

            // Update local with server response
            try await localDataSource.updateUser(createdUser)
            cache.setValue(createdUser, forKey: createdUser.id)

            return createdUser
        } catch {
            let appError = AppError.from(error)

            // If offline, queue for later sync
            if case .networkError(.E1000_NO_CONNECTION, _, _, _) = appError {
                await queuePendingChange(userId: user.id, operation: .create, user: user)

                analyticsTracker.trackEvent(.offlineDataAccessed, params: [
                    "operation": "createUser",
                    "userId": user.id
                ])
                analyticsTracker.trackEvent(.pendingChangesQueued, params: [
                    "operation": "create",
                    "userId": user.id
                ])
                return user
            }

            // For other errors, rollback local changes
            try await localDataSource.deleteUser(user)
            cache.removeValue(forKey: user.id)

            throw appError
        }
    }
    
    func updateUser(_ user: User) async throws -> User {
        // 1. Save locally first
        try await localDataSource.updateUser(user)
        cache.setValue(user, forKey: user.id)

        // 2. Try to sync with remote
        do {
            let updatedUser = try await remoteDataSource.updateUser(user)

            // Update local with server response
            try await localDataSource.updateUser(updatedUser)
            cache.setValue(updatedUser, forKey: updatedUser.id)

            return updatedUser
        } catch {
            let appError = AppError.from(error)

            // If offline, queue for later sync
            if case .networkError(.E1000_NO_CONNECTION, _, _, _) = appError {
                await queuePendingChange(userId: user.id, operation: .update, user: user)

                analyticsTracker.trackEvent(.offlineDataAccessed, params: [
                    "operation": "updateUser",
                    "userId": user.id
                ])
                analyticsTracker.trackEvent(.pendingChangesQueued, params: [
                    "operation": "update",
                    "userId": user.id
                ])
                return user
            }

            throw appError
        }
    }
    
    func deleteUser(_ user: User) async throws {
        // 1. Delete locally first
        try await localDataSource.deleteUser(user)
        cache.removeValue(forKey: user.id)

        // 2. Try to sync with remote
        do {
            try await remoteDataSource.deleteUser(user)
        } catch {
            let appError = AppError.from(error)

            // If offline, queue for later sync
            if case .networkError(.E1000_NO_CONNECTION, _, _, _) = appError {
                await queuePendingChange(userId: user.id, operation: .delete, user: user)

                analyticsTracker.trackEvent(.offlineDataAccessed, params: [
                    "operation": "deleteUser",
                    "userId": user.id
                ])
                analyticsTracker.trackEvent(.pendingChangesQueued, params: [
                    "operation": "delete",
                    "userId": user.id
                ])
                return
            }

            // For other errors, restore locally
            try await localDataSource.createUser(user)
            cache.setValue(user, forKey: user.id)

            throw appError
        }
    }
    
    func searchUsers(query: String) async throws -> [User] {
        // Search locally first
        let localResults = try await localDataSource.searchUsers(query: query)
        
        // Update cache
        for user in localResults {
            cache.setValue(user, forKey: user.id)
        }
        
        return localResults
    }
    
    func refreshUsers() async throws -> [User] {
        analyticsTracker.trackEvent(.syncStarted)
        
        // Clear cache
        cache.removeAll()
        analyticsTracker.trackEvent(.cacheCleared)
        
        // Fetch from remote
        return try await fetchUsersFromRemote()
    }
    
    // MARK: - Private Methods
    
    private func fetchUsersFromRemote() async throws -> [User] {
        do {
            let remoteUsers = try await remoteDataSource.getUsers()
            
            // Save to local database
            try await localDataSource.saveUsers(remoteUsers)
            
            // Update cache
            for user in remoteUsers {
                cache.setValue(user, forKey: user.id)
            }
            
            return remoteUsers
        } catch {
            let appError = AppError.from(error)
            
            // If offline, try to use stale local data
            if case .networkError(.E1000_NO_CONNECTION, _, _, _) = appError {
                analyticsTracker.trackEvent(.offlineModeEnabled)
                
                let localUsers = try await localDataSource.getUsers()
                for user in localUsers {
                    cache.setValue(user, forKey: user.id)
                }
                return localUsers
            }
            
            throw appError
        }
    }
    
    private func syncUsersInBackground() async throws {
        do {
            let remoteUsers = try await remoteDataSource.getUsers()
            try await localDataSource.saveUsers(remoteUsers)

            // Update cache
            for user in remoteUsers {
                cache.setValue(user, forKey: user.id)
            }

            analyticsTracker.trackEvent(.backgroundSyncCompleted, params: [
                "count": remoteUsers.count
            ])
        } catch {
            analyticsTracker.trackError(error, context: ["operation": "backgroundSync"])
        }
    }

    // MARK: - Offline Queue Management

    /// Queue a change for later sync when offline
    private func queuePendingChange(userId: String, operation: PendingChangeOperation, user: User) async {
        let change = PendingChange(
            id: UUID().uuidString,
            userId: userId,
            operation: operation,
            user: user,
            timestamp: Date(),
            retryCount: 0,
            lastError: nil
        )

        guard let entity = PendingChangeEntity.from(change: change) else {
            return
        }

        await MainActor.run {
            modelContext.insert(entity)
            try? modelContext.save()
        }
    }

    /// Setup network monitoring to auto-sync when connection is restored
    private func setupNetworkMonitoring() {
        Task { @MainActor in
            networkCancellable = NetworkMonitor.shared.$isConnected
                .removeDuplicates()
                .sink { [weak self] isConnected in
                    if isConnected {
                        Task {
                            await self?.processOfflineChanges()
                        }
                    }
                }
        }
    }

    /// Process all pending offline changes
    @MainActor
    func processOfflineChanges() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        // Fetch all pending changes
        let descriptor = FetchDescriptor<PendingChangeEntity>(
            sortBy: [SortDescriptor(\.timestamp)]
        )

        guard let pendingEntities = try? modelContext.fetch(descriptor) else {
            return
        }

        guard !pendingEntities.isEmpty else {
            return
        }

        analyticsTracker.trackEvent(.syncStarted, params: [
            "pending_count": pendingEntities.count
        ])

        var successCount = 0
        var failedCount = 0

        for entity in pendingEntities {
            guard let change = entity.toPendingChange() else {
                modelContext.delete(entity)
                continue
            }

            do {
                // Process the change
                switch change.operation {
                case .create:
                    _ = try await remoteDataSource.createUser(change.user)
                case .update:
                    _ = try await remoteDataSource.updateUser(change.user)
                case .delete:
                    try await remoteDataSource.deleteUser(change.user)
                }

                // Success - remove from queue
                modelContext.delete(entity)
                successCount += 1

                analyticsTracker.trackEvent(.syncCompleted, params: [
                    "operation": change.operation.rawValue,
                    "userId": change.userId
                ])

            } catch {
                failedCount += 1
                let appError = AppError.from(error)

                // Update retry count and error
                entity.retryCount += 1
                entity.lastError = appError.message

                analyticsTracker.trackEvent(.syncFailed, params: [
                    "operation": change.operation.rawValue,
                    "userId": change.userId,
                    "retry_count": entity.retryCount,
                    "error": appError.errorCode.code
                ])

                // Remove from queue if max retries exceeded
                if entity.retryCount >= AppConstants.API.maxRetries {
                    modelContext.delete(entity)
                    analyticsTracker.trackEvent(.syncFailed, params: [
                        "operation": change.operation.rawValue,
                        "userId": change.userId,
                        "max_retries_exceeded": true
                    ])
                }
            }
        }

        // Save changes
        try? modelContext.save()

        if successCount > 0 || failedCount > 0 {
            analyticsTracker.trackEvent(.syncCompleted, params: [
                "success_count": successCount,
                "failed_count": failedCount
            ])
        }
    }

    /// Get count of pending changes
    @MainActor
    func getPendingChangesCount() -> Int {
        let descriptor = FetchDescriptor<PendingChangeEntity>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}
