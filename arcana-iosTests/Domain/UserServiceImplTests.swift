//
//  UserServiceImplTests.swift
//  arcana-iosTests
//
//  Created by Claude Code
//

import Testing
import Foundation
@testable import arcana_ios

/// Comprehensive tests for UserServiceImpl
struct UserServiceImplTests {

    // MARK: - Test Setup

    func makeTestDependencies() -> (service: UserServiceImpl, repository: MockUserRepository, analytics: MockAnalyticsTracker) {
        let repository = MockUserRepository()
        let analytics = MockAnalyticsTracker()
        let service = UserServiceImpl(
            repository: repository,
            validator: UserValidator.self,
            analyticsTracker: analytics
        )
        return (service, repository, analytics)
    }

    // MARK: - GetUsers Tests

    @Test("getUsers returns users from repository")
    func testGetUsers() async throws {
        let (service, repository, _) = makeTestDependencies()
        repository.users = User.mockUsers

        let users = try await service.getUsers()

        #expect(users.count == 5)
        #expect(repository.getUsersCallCount == 1)
    }

    @Test("getUsers tracks analytics events")
    func testGetUsersAnalytics() async throws {
        let (service, repository, analytics) = makeTestDependencies()
        repository.users = User.mockUsers

        _ = try await service.getUsers()

        #expect(analytics.trackedEvents.count == 2)
        #expect(analytics.trackedEvents[0].event == .networkRequestStarted)
        #expect(analytics.trackedEvents[1].event == .networkRequestSuccess)
    }

    @Test("getUsers handles errors and tracks them")
    func testGetUsersError() async throws {
        let (service, repository, analytics) = makeTestDependencies()
        repository.shouldThrowError = AppError.networkError(.E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: nil)

        do {
            _ = try await service.getUsers()
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(analytics.trackedAppErrors.count == 1)
            #expect(analytics.trackedEvents[0].event == .networkRequestStarted)
        }
    }

    // MARK: - GetUsers Paginated Tests

    @Test("getUsers with pagination returns correct page")
    func testGetUsersPaginated() async throws {
        let (service, repository, _) = makeTestDependencies()
        repository.users = User.mockUsers

        let result = try await service.getUsers(page: 1, perPage: 2)

        #expect(result.items.count == 2)
        #expect(result.currentPage == 1)
        #expect(result.hasMore == true)
    }

    @Test("getUsers pagination tracks analytics")
    func testGetUsersPaginatedAnalytics() async throws {
        let (service, repository, analytics) = makeTestDependencies()
        repository.users = User.mockUsers

        _ = try await service.getUsers(page: 1, perPage: 2)

        #expect(analytics.trackedEvents.count == 2)
        let params = analytics.trackedEvents[0].params as? [String: Int]
        #expect(params?["page"] == 1)
        #expect(params?["per_page"] == 2)
    }

    // MARK: - GetUser By ID Tests

    @Test("getUser returns specific user")
    func testGetUser() async throws {
        let (service, repository, _) = makeTestDependencies()
        let user = User.mock(id: "123")
        repository.users = [user]

        let foundUser = try await service.getUser(id: "123")

        #expect(foundUser.id == "123")
    }

    @Test("getUser tracks analytics")
    func testGetUserAnalytics() async throws {
        let (service, repository, analytics) = makeTestDependencies()
        repository.users = [User.mock(id: "123")]

        _ = try await service.getUser(id: "123")

        #expect(analytics.trackedEvents.count == 2)
        #expect(analytics.trackedEvents[0].event == .networkRequestStarted)
        #expect(analytics.trackedEvents[1].event == .networkRequestSuccess)
    }

    // MARK: - CreateUser Tests

    @Test("createUser validates and creates user")
    func testCreateUser() async throws {
        let (service, repository, _) = makeTestDependencies()
        let user = User.mock(email: "test@example.com", firstName: "John", lastName: "Doe")

        let created = try await service.createUser(user)

        #expect(repository.createUserCallCount == 1)
        #expect(created.email == "test@example.com")
    }

    @Test("createUser fails with invalid email")
    func testCreateUserInvalidEmail() async throws {
        let (service, _, analytics) = makeTestDependencies()
        let user = User.mock(email: "invalid-email", firstName: "John", lastName: "Doe")

        do {
            _ = try await service.createUser(user)
            Issue.record("Expected validation error")
        } catch {
            #expect(analytics.trackedAppErrors.count == 1)
        }
    }

    @Test("createUser fails with invalid first name")
    func testCreateUserInvalidFirstName() async throws {
        let (service, _, analytics) = makeTestDependencies()
        let user = User.mock(email: "test@example.com", firstName: "John123", lastName: "Doe")

        do {
            _ = try await service.createUser(user)
            Issue.record("Expected validation error")
        } catch {
            #expect(analytics.trackedAppErrors.count == 1)
        }
    }

    @Test("createUser tracks success analytics")
    func testCreateUserSuccessAnalytics() async throws {
        let (service, repository, analytics) = makeTestDependencies()
        let user = User.mock()

        _ = try await service.createUser(user)

        #expect(analytics.trackedEvents.contains(where: { $0.event == .userCreateClicked }))
        #expect(analytics.trackedEvents.contains(where: { $0.event == .userCreateSuccess }))
    }

    @Test("createUser tracks failure analytics")
    func testCreateUserFailureAnalytics() async throws {
        let (service, repository, analytics) = makeTestDependencies()
        repository.shouldThrowError = AppError.networkError(.E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: nil)
        let user = User.mock()

        do {
            _ = try await service.createUser(user)
            Issue.record("Expected error")
        } catch {
            #expect(analytics.trackedEvents.contains(where: { $0.event == .userCreateFailed }))
        }
    }

    // MARK: - UpdateUser Tests

    @Test("updateUser validates and updates user")
    func testUpdateUser() async throws {
        let (service, repository, _) = makeTestDependencies()
        let user = User.mock(id: "123")
        repository.users = [user]

        let updated = try await service.updateUser(user)

        #expect(repository.updateUserCallCount == 1)
        #expect(updated.id == "123")
    }

    @Test("updateUser fails with invalid data")
    func testUpdateUserInvalid() async throws {
        let (service, _, analytics) = makeTestDependencies()
        let user = User.mock(email: "invalid", firstName: "John", lastName: "Doe")

        do {
            _ = try await service.updateUser(user)
            Issue.record("Expected validation error")
        } catch {
            #expect(analytics.trackedAppErrors.count == 1)
        }
    }

    @Test("updateUser tracks analytics")
    func testUpdateUserAnalytics() async throws {
        let (service, _, analytics) = makeTestDependencies()
        let user = User.mock()

        _ = try await service.updateUser(user)

        #expect(analytics.trackedEvents.contains(where: { $0.event == .userUpdateClicked }))
        #expect(analytics.trackedEvents.contains(where: { $0.event == .userUpdateSuccess }))
    }

    // MARK: - DeleteUser Tests

    @Test("deleteUser removes user")
    func testDeleteUser() async throws {
        let (service, repository, _) = makeTestDependencies()
        let user = User.mock(id: "123")
        repository.users = [user]

        try await service.deleteUser(user)

        #expect(repository.deleteUserCallCount == 1)
        #expect(repository.users.isEmpty)
    }

    @Test("deleteUser tracks analytics")
    func testDeleteUserAnalytics() async throws {
        let (service, _, analytics) = makeTestDependencies()
        let user = User.mock()

        try await service.deleteUser(user)

        #expect(analytics.trackedEvents.contains(where: { $0.event == .userDeleteClicked }))
        #expect(analytics.trackedEvents.contains(where: { $0.event == .userDeleteSuccess }))
    }

    @Test("deleteUser tracks failure")
    func testDeleteUserFailure() async throws {
        let (service, repository, analytics) = makeTestDependencies()
        repository.shouldThrowError = AppError.networkError(.E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: nil)
        let user = User.mock()

        do {
            try await service.deleteUser(user)
            Issue.record("Expected error")
        } catch {
            #expect(analytics.trackedEvents.contains(where: { $0.event == .userDeleteFailed }))
        }
    }

    // MARK: - SearchUsers Tests

    @Test("searchUsers filters users")
    func testSearchUsers() async throws {
        let (service, repository, _) = makeTestDependencies()
        repository.users = [
            User.mock(email: "alice@example.com", firstName: "Alice", lastName: "Smith"),
            User.mock(email: "bob@example.com", firstName: "Bob", lastName: "Jones")
        ]

        let results = try await service.searchUsers(query: "alice")

        #expect(results.count == 1)
        #expect(results[0].firstName == "Alice")
    }

    @Test("searchUsers tracks analytics")
    func testSearchUsersAnalytics() async throws {
        let (service, repository, analytics) = makeTestDependencies()
        repository.users = User.mockUsers

        _ = try await service.searchUsers(query: "test")

        #expect(analytics.trackedEvents.contains(where: { $0.event == .listSearched }))
    }

    // MARK: - RefreshUsers Tests

    @Test("refreshUsers returns fresh data")
    func testRefreshUsers() async throws {
        let (service, repository, _) = makeTestDependencies()
        repository.users = User.mockUsers

        let users = try await service.refreshUsers()

        #expect(users.count == 5)
        #expect(repository.getUsersCallCount == 1)
    }

    @Test("refreshUsers tracks analytics")
    func testRefreshUsersAnalytics() async throws {
        let (service, repository, analytics) = makeTestDependencies()
        repository.users = User.mockUsers

        _ = try await service.refreshUsers()

        #expect(analytics.trackedEvents.contains(where: { $0.event == .listRefreshed }))
        #expect(analytics.trackedEvents.contains(where: { $0.event == .syncCompleted }))
    }

    @Test("refreshUsers tracks failure")
    func testRefreshUsersFailure() async throws {
        let (service, repository, analytics) = makeTestDependencies()
        repository.shouldThrowError = AppError.networkError(.E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: nil)

        do {
            _ = try await service.refreshUsers()
            Issue.record("Expected error")
        } catch {
            #expect(analytics.trackedEvents.contains(where: { $0.event == .syncFailed }))
        }
    }
}
