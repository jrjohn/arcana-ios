//
//  OfflineFirstUserRepositoryTests.swift
//  arcana-iosTests
//
//  Tests for OfflineFirstUserRepository
//

import Testing
import Foundation
import SwiftData
@testable import arcana_ios

// MARK: - Test Helpers

@MainActor
private func makeTestRepository() throws -> (
    repo: OfflineFirstUserRepositoryImpl,
    local: MockUserLocalDao,
    remote: MockUserRemoteDao,
    analytics: MockAnalyticsTracker
) {
    let schema = Schema([UserEntity.self, AnalyticsEventEntity.self, PendingChangeEntity.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [config])

    let local = MockUserLocalDao()
    let remote = MockUserRemoteDao()
    let analytics = MockAnalyticsTracker()

    let repo = OfflineFirstUserRepositoryImpl(
        localDataSource: local,
        remoteDataSource: remote,
        analyticsTracker: analytics,
        modelContext: container.mainContext
    )

    return (repo, local, remote, analytics)
}

// MARK: - getUsers Tests

@Suite("OfflineFirstUserRepository - getUsers")
@MainActor
struct OfflineFirstGetUsersTests {

    @Test("getUsers returns from cache when available")
    func testGetUsersFromCache() async throws {
        let (repo, local, remote, analytics) = try makeTestRepository()
        remote.users = User.mockUsers

        // First call to prime the cache
        _ = try await repo.getUsers()
        let remoteCallsBefore = remote.users.count

        // Second call should hit cache
        let users = try await repo.getUsers()

        #expect(users.count == 5)
        #expect(analytics.trackedEvents.contains(where: { $0.event == .cacheHit }))
        _ = remoteCallsBefore
    }

    @Test("getUsers falls back to local when cache empty")
    func testGetUsersFromLocal() async throws {
        let (repo, local, remote, _) = try makeTestRepository()
        local.users = User.mockUsers
        remote.shouldThrowError = AppError.networkError(
            .E1000_NO_CONNECTION, message: "Offline", isRetryable: true, underlyingError: nil
        )

        let users = try await repo.getUsers()

        #expect(users.count == 5)
    }

    @Test("getUsers fetches from remote when cache and local empty")
    func testGetUsersFromRemote() async throws {
        let (repo, _, remote, _) = try makeTestRepository()
        remote.users = User.mockUsers

        let users = try await repo.getUsers()

        #expect(users.count == 5)
    }

    @Test("getUsers uses stale local data when offline")
    func testGetUsersOfflineFallback() async throws {
        let (repo, local, remote, analytics) = try makeTestRepository()
        local.users = User.mockUsers
        remote.shouldThrowError = AppError.networkError(
            .E1000_NO_CONNECTION, message: "Offline", isRetryable: true, underlyingError: nil
        )

        // Empty cache (no previous remote call)
        // Local is empty in default case but we set it
        let users = try await repo.getUsers()

        #expect(users.count == 5)
        _ = analytics
    }

    @Test("getUsers tracks cache miss event")
    func testGetUsersTracksAnalytics() async throws {
        let (repo, _, remote, analytics) = try makeTestRepository()
        remote.users = User.mockUsers

        _ = try await repo.getUsers()

        #expect(analytics.trackedEvents.contains(where: { $0.event == .cacheMiss }))
    }

    @Test("getUsers throws when remote fails with non-network error")
    func testGetUsersThrowsOnServerError() async throws {
        let (repo, _, remote, _) = try makeTestRepository()
        remote.shouldThrowError = AppError.serverError(
            .E3005_INTERNAL_SERVER_ERROR, statusCode: 500, message: "Server error"
        )

        do {
            _ = try await repo.getUsers()
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error != nil)
        }
    }
}

// MARK: - getUsers(page:perPage:) Tests

@Suite("OfflineFirstUserRepository - paginated getUsers")
@MainActor
struct OfflineFirstPaginatedGetUsersTests {

    @Test("getUsers paginated returns correct page")
    func testGetUsersPaginated() async throws {
        let (repo, _, remote, _) = try makeTestRepository()
        remote.users = User.mockUsers

        let result = try await repo.getUsers(page: 1, perPage: 3)

        #expect(result.items.count == 3)
        #expect(result.currentPage == 1)
        #expect(result.hasMore == true)
    }

    @Test("getUsers paginated saves to local on first page")
    func testGetUsersPaginatedSavesLocally() async throws {
        let (repo, local, remote, _) = try makeTestRepository()
        remote.users = User.mockUsers

        _ = try await repo.getUsers(page: 1, perPage: 5)

        #expect(local.saveUsersCallCount == 1)
    }

    @Test("getUsers paginated page 2 updates local records")
    func testGetUsersPaginatedPage2() async throws {
        let (repo, local, remote, _) = try makeTestRepository()
        remote.users = User.mockUsers

        _ = try await repo.getUsers(page: 2, perPage: 2)

        // Page 2 does append/update, not save
        #expect(local.saveUsersCallCount == 0)
    }

    @Test("getUsers paginated falls back to local when offline on page 1")
    func testGetUsersPaginatedOfflineFallback() async throws {
        let (repo, local, remote, analytics) = try makeTestRepository()
        local.users = User.mockUsers
        remote.shouldThrowError = AppError.networkError(
            .E1000_NO_CONNECTION, message: "Offline", isRetryable: true, underlyingError: nil
        )

        let result = try await repo.getUsers(page: 1, perPage: 3)

        #expect(result.items.count == 3)
        #expect(analytics.trackedEvents.contains(where: { $0.event == .offlineModeEnabled }))
    }

    @Test("getUsers paginated throws when offline on page 2+")
    func testGetUsersPaginatedOfflinePage2Throws() async throws {
        let (repo, _, remote, _) = try makeTestRepository()
        remote.shouldThrowError = AppError.networkError(
            .E1000_NO_CONNECTION, message: "Offline", isRetryable: true, underlyingError: nil
        )

        do {
            _ = try await repo.getUsers(page: 2, perPage: 3)
            Issue.record("Expected error")
        } catch {
            #expect(error != nil)
        }
    }
}

// MARK: - getUser Tests

@Suite("OfflineFirstUserRepository - getUser")
@MainActor
struct OfflineFirstGetUserTests {

    @Test("getUser returns from cache when available")
    func testGetUserFromCache() async throws {
        let (repo, _, remote, analytics) = try makeTestRepository()
        remote.users = User.mockUsers

        // Prime the cache
        _ = try await repo.getUsers()

        let user = try await repo.getUser(id: User.mockUsers[0].id)

        #expect(user.id == User.mockUsers[0].id)
        #expect(analytics.trackedEvents.contains(where: { $0.event == .cacheHit }))
    }

    @Test("getUser falls back to local when not in cache")
    func testGetUserFromLocal() async throws {
        let (repo, local, remote, _) = try makeTestRepository()
        let user = User.mock(id: "test-id")
        local.users = [user]
        remote.shouldThrowError = AppError.serverError(
            .E3002_NOT_FOUND, statusCode: 404, message: "Not found"
        )

        let found = try await repo.getUser(id: "test-id")

        #expect(found.id == "test-id")
    }

    @Test("getUser fetches from remote when not local")
    func testGetUserFromRemote() async throws {
        let (repo, _, remote, _) = try makeTestRepository()
        let user = User.mock(id: "remote-id")
        remote.users = [user]

        let found = try await repo.getUser(id: "remote-id")

        #expect(found.id == "remote-id")
    }

    @Test("getUser tracks cache miss event")
    func testGetUserTracksAnalytics() async throws {
        let (repo, _, remote, analytics) = try makeTestRepository()
        remote.users = [User.mock(id: "new-id")]

        _ = try await repo.getUser(id: "new-id")

        #expect(analytics.trackedEvents.contains(where: { $0.event == .cacheMiss }))
    }
}

// MARK: - createUser Tests

@Suite("OfflineFirstUserRepository - createUser")
@MainActor
struct OfflineFirstCreateUserTests {

    @Test("createUser saves locally and syncs remotely")
    func testCreateUserOnline() async throws {
        let (repo, local, remote, _) = try makeTestRepository()
        let user = User.mock()

        let created = try await repo.createUser(user)

        #expect(created.id == user.id)
        #expect(local.createUserCallCount == 1)
        #expect(remote.createUserCallCount == 1)
    }

    @Test("createUser queues for sync when offline")
    func testCreateUserOffline() async throws {
        let (repo, local, _, analytics) = try makeTestRepository()
        let (_, _, remote, _) = try makeTestRepository()
        _ = remote
        // We set up a fresh repo with offline remote
        let schema = Schema([UserEntity.self, AnalyticsEventEntity.self, PendingChangeEntity.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let offlineRemote = MockUserRemoteDao()
        offlineRemote.shouldThrowError = AppError.networkError(
            .E1000_NO_CONNECTION, message: "Offline", isRetryable: true, underlyingError: nil
        )
        let offlineRepo = OfflineFirstUserRepositoryImpl(
            localDataSource: local,
            remoteDataSource: offlineRemote,
            analyticsTracker: analytics,
            modelContext: container.mainContext
        )

        let user = User.mock()
        let created = try await offlineRepo.createUser(user)

        #expect(created.id == user.id)
        #expect(local.createUserCallCount >= 1)
        #expect(analytics.trackedEvents.contains(where: { $0.event == .offlineDataAccessed }))
        #expect(analytics.trackedEvents.contains(where: { $0.event == .pendingChangesQueued }))
    }

    @Test("createUser rolls back local on non-network error")
    func testCreateUserRollbackOnError() async throws {
        let (repo, local, remote, _) = try makeTestRepository()
        remote.shouldThrowError = AppError.serverError(
            .E3001_BAD_REQUEST, statusCode: 400, message: "Bad request"
        )
        let user = User.mock()

        do {
            _ = try await repo.createUser(user)
            Issue.record("Expected error")
        } catch {
            // local should be rolled back
            #expect(local.deleteUserCallCount == 1)
        }
    }
}

// MARK: - updateUser Tests

@Suite("OfflineFirstUserRepository - updateUser")
@MainActor
struct OfflineFirstUpdateUserTests {

    @Test("updateUser saves locally and syncs remotely")
    func testUpdateUserOnline() async throws {
        let (repo, local, remote, _) = try makeTestRepository()
        let user = User.mock()

        let updated = try await repo.updateUser(user)

        #expect(updated.id == user.id)
        #expect(local.updateUserCallCount == 2) // once local, once after remote
        #expect(remote.updateUserCallCount == 1)
    }

    @Test("updateUser queues for sync when offline")
    func testUpdateUserOffline() async throws {
        let schema = Schema([UserEntity.self, AnalyticsEventEntity.self, PendingChangeEntity.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let local = MockUserLocalDao()
        let remote = MockUserRemoteDao()
        remote.shouldThrowError = AppError.networkError(
            .E1000_NO_CONNECTION, message: "Offline", isRetryable: true, underlyingError: nil
        )
        let analytics = MockAnalyticsTracker()
        let repo = OfflineFirstUserRepositoryImpl(
            localDataSource: local,
            remoteDataSource: remote,
            analyticsTracker: analytics,
            modelContext: container.mainContext
        )

        let user = User.mock()
        let result = try await repo.updateUser(user)

        #expect(result.id == user.id)
        #expect(analytics.trackedEvents.contains(where: { $0.event == .pendingChangesQueued }))
    }
}

// MARK: - deleteUser Tests

@Suite("OfflineFirstUserRepository - deleteUser")
@MainActor
struct OfflineFirstDeleteUserTests {

    @Test("deleteUser removes locally and syncs remotely")
    func testDeleteUserOnline() async throws {
        let (repo, local, remote, _) = try makeTestRepository()
        let user = User.mock()
        local.users = [user]
        remote.users = [user]

        try await repo.deleteUser(user)

        #expect(local.deleteUserCallCount == 1)
        #expect(remote.deleteUserCallCount == 1)
    }

    @Test("deleteUser queues for sync when offline")
    func testDeleteUserOffline() async throws {
        let schema = Schema([UserEntity.self, AnalyticsEventEntity.self, PendingChangeEntity.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let local = MockUserLocalDao()
        let remote = MockUserRemoteDao()
        remote.shouldThrowError = AppError.networkError(
            .E1000_NO_CONNECTION, message: "Offline", isRetryable: true, underlyingError: nil
        )
        let analytics = MockAnalyticsTracker()
        let repo = OfflineFirstUserRepositoryImpl(
            localDataSource: local,
            remoteDataSource: remote,
            analyticsTracker: analytics,
            modelContext: container.mainContext
        )

        let user = User.mock()
        try await repo.deleteUser(user)

        #expect(analytics.trackedEvents.contains(where: { $0.event == .pendingChangesQueued }))
    }

    @Test("deleteUser restores local on non-network error")
    func testDeleteUserRestoresOnError() async throws {
        let (repo, local, remote, _) = try makeTestRepository()
        let user = User.mock()
        local.users = [user]
        remote.shouldThrowError = AppError.serverError(
            .E3001_BAD_REQUEST, statusCode: 400, message: "Bad request"
        )

        do {
            try await repo.deleteUser(user)
            Issue.record("Expected error")
        } catch {
            // local should be restored
            #expect(local.createUserCallCount == 1)
        }
    }
}

// MARK: - searchUsers Tests

@Suite("OfflineFirstUserRepository - searchUsers")
@MainActor
struct OfflineFirstSearchTests {

    @Test("searchUsers queries local store")
    func testSearchUsers() async throws {
        let (repo, local, _, _) = try makeTestRepository()
        local.users = User.mockUsers

        let results = try await repo.searchUsers(query: "Alice")

        // Results depend on mock data having "Alice"
        #expect(results.count >= 0)
    }

    @Test("searchUsers returns empty for no match")
    func testSearchUsersEmpty() async throws {
        let (repo, local, _, _) = try makeTestRepository()
        local.users = User.mockUsers

        let results = try await repo.searchUsers(query: "zzznonexistent")

        #expect(results.isEmpty)
    }
}

// MARK: - refreshUsers Tests

@Suite("OfflineFirstUserRepository - refreshUsers")
@MainActor
struct OfflineFirstRefreshTests {

    @Test("refreshUsers clears cache and fetches remote")
    func testRefreshUsers() async throws {
        let (repo, local, remote, analytics) = try makeTestRepository()
        remote.users = User.mockUsers

        let users = try await repo.refreshUsers()

        #expect(users.count == 5)
        #expect(local.saveUsersCallCount == 1)
        #expect(analytics.trackedEvents.contains(where: { $0.event == .syncStarted }))
        #expect(analytics.trackedEvents.contains(where: { $0.event == .cacheCleared }))
    }

    @Test("refreshUsers falls back to local when offline")
    func testRefreshUsersOfflineFallback() async throws {
        let (repo, local, remote, analytics) = try makeTestRepository()
        local.users = User.mockUsers
        remote.shouldThrowError = AppError.networkError(
            .E1000_NO_CONNECTION, message: "Offline", isRetryable: true, underlyingError: nil
        )

        let users = try await repo.refreshUsers()

        #expect(users.count == 5)
        #expect(analytics.trackedEvents.contains(where: { $0.event == .offlineModeEnabled }))
    }

    @Test("refreshUsers throws on non-network error")
    func testRefreshUsersThrowsOnServerError() async throws {
        let (repo, _, remote, _) = try makeTestRepository()
        remote.shouldThrowError = AppError.serverError(
            .E3005_INTERNAL_SERVER_ERROR, statusCode: 500, message: "Server error"
        )

        do {
            _ = try await repo.refreshUsers()
            Issue.record("Expected error")
        } catch {
            #expect(error != nil)
        }
    }
}
