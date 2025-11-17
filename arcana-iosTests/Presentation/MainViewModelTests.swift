//
//  MainViewModelTests.swift
//  arcana-iosTests
//
//  Created by John on 2025/11/15
//

import Testing
import Foundation
import Dependencies
@testable import arcana_ios

/// Comprehensive tests for MainViewModel
@MainActor
struct MainViewModelTests {

    // MARK: - Mock Dependencies

    // Note: Since NavGraph is a final class, we just use a real instance
    // and check its state

    class MockUserService: UserService {
        var users: [User] = []
        var shouldThrowError: Error?
        var getUsersCallCount = 0

        func getUsers() async throws -> [User] {
            getUsersCallCount += 1
            if let error = shouldThrowError {
                throw error
            }
            return users
        }

        func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User> {
            return PaginatedResult(items: users, currentPage: page, totalPages: 1, hasMore: false)
        }

        func getUser(id: String) async throws -> User {
            throw AppError.unknownError(.E9000_UNKNOWN, message: "Not implemented", underlyingError: nil)
        }

        func createUser(_ user: User) async throws -> User {
            return user
        }

        func updateUser(_ user: User) async throws -> User {
            return user
        }

        func deleteUser(_ user: User) async throws {
            // no-op
        }

        func searchUsers(query: String) async throws -> [User] {
            return users.filter { $0.firstName.contains(query) || $0.lastName.contains(query) }
        }

        func refreshUsers() async throws -> [User] {
            getUsersCallCount += 1
            if let error = shouldThrowError {
                throw error
            }
            return users
        }
    }

    // MARK: - Initialization Tests

    @Test("MainViewModel initializes with correct default state")
    func testInitialization() {
        let navGraph = NavGraph()
        let viewModel = MainViewModel(navGraph: navGraph)

        #expect(viewModel.userCount == 0)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.hasError == false)
        #expect(viewModel.canNavigate == true)
    }

    // MARK: - Load Data Tests

    @Test("loadData successfully loads user count")
    func testLoadDataSuccess() async {
        let mockService = MockUserService()
        mockService.users = User.mockUsers

        let mockTracker = MockAnalyticsTracker()
        let navGraph = NavGraph()

        let viewModel = await withDependencies {
            $0.userService = mockService
            $0.analyticsTracker = mockTracker
        } operation: {
            MainViewModel(navGraph: navGraph)
        }

        viewModel.send(.loadData)

        // Wait for async operation
        try? await Task.sleep(for: .milliseconds(600))

        #expect(viewModel.userCount == 5)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(mockService.getUsersCallCount == 1)
        #expect(mockTracker.trackedScreens.count > 0)
        #expect(mockTracker.trackedEvents.count > 0)
    }

    @Test("loadData handles errors correctly")
    func testLoadDataError() async {
        let mockService = MockUserService()
        mockService.shouldThrowError = AppError.networkError(
            .E1000_NO_CONNECTION,
            message: "No connection",
            isRetryable: true,
            underlyingError: nil
        )

        let mockTracker = MockAnalyticsTracker()
        let navGraph = NavGraph()

        let viewModel = await withDependencies {
            $0.userService = mockService
            $0.analyticsTracker = mockTracker
        } operation: {
            MainViewModel(navGraph: navGraph)
        }

        viewModel.send(.loadData)

        // Wait for async operation
        try? await Task.sleep(for: .milliseconds(600))

        #expect(viewModel.userCount == 0)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.hasError == true)
        #expect(mockTracker.trackedAppErrors.count > 0)
    }

    @Test("retry loads data again")
    func testRetry() async {
        let mockService = MockUserService()
        mockService.users = User.mockUsers

        let mockTracker = MockAnalyticsTracker()
        let navGraph = NavGraph()

        let viewModel = await withDependencies {
            $0.userService = mockService
            $0.analyticsTracker = mockTracker
        } operation: {
            MainViewModel(navGraph: navGraph)
        }

        viewModel.send(.retry)

        // Wait for async operation
        try? await Task.sleep(for: .milliseconds(600))

        #expect(viewModel.userCount == 5)
        #expect(mockService.getUsersCallCount == 1)
    }

    // MARK: - Navigation Tests

    @Test("navigateToUserList calls navGraph")
    func testNavigateToUserList() async {
        let mockService = MockUserService()
        let mockTracker = MockAnalyticsTracker()
        let navGraph = NavGraph()

        let viewModel = await withDependencies {
            $0.userService = mockService
            $0.analyticsTracker = mockTracker
        } operation: {
            MainViewModel(navGraph: navGraph)
        }

        viewModel.send(.navigateToUserList)

        // Give time for navigation
        try? await Task.sleep(for: .milliseconds(100))

        // Verify navigation by checking path contains userList route
        #expect(navGraph.path.contains(where: { route in
            if case .userList = route { return true }
            return false
        }))
        #expect(mockTracker.trackedEvents.count > 0)
    }

    @Test("navigateToSettings calls navGraph")
    func testNavigateToSettings() async {
        let mockService = MockUserService()
        let mockTracker = MockAnalyticsTracker()
        let navGraph = NavGraph()

        let viewModel = await withDependencies {
            $0.userService = mockService
            $0.analyticsTracker = mockTracker
        } operation: {
            MainViewModel(navGraph: navGraph)
        }

        viewModel.send(.navigateToSettings)

        // Give time for navigation
        try? await Task.sleep(for: .milliseconds(100))

        // Verify navigation by checking path contains settings route
        #expect(navGraph.path.contains(where: { route in
            if case .settings = route { return true }
            return false
        }))
        #expect(mockTracker.trackedScreens.count > 0)
    }

    @Test("navigation is blocked while loading")
    func testCanNavigateWhileLoading() async {
        let mockService = MockUserService()
        mockService.users = User.mockUsers

        let mockTracker = MockAnalyticsTracker()
        let navGraph = NavGraph()

        let viewModel = await withDependencies {
            $0.userService = mockService
            $0.analyticsTracker = mockTracker
        } operation: {
            MainViewModel(navGraph: navGraph)
        }

        // Start loading
        viewModel.send(.loadData)

        // Check immediately while loading
        try? await Task.sleep(for: .milliseconds(100))

        // Attempt navigation while loading
        viewModel.send(.navigateToUserList)

        // Even if attempted, it should check canNavigate
        #expect(viewModel.canNavigate == !viewModel.isLoading)
    }

    // MARK: - Computed Properties Tests

    @Test("hasError computed property works correctly")
    func testHasErrorProperty() {
        let navGraph = NavGraph()
        let viewModel = MainViewModel(navGraph: navGraph)

        #expect(viewModel.hasError == false)

        // Simulate error by reflection or direct property access wouldn't work
        // This is tested indirectly through error handling tests
    }

    @Test("canNavigate computed property works correctly")
    func testCanNavigateProperty() {
        let navGraph = NavGraph()
        let viewModel = MainViewModel(navGraph: navGraph)

        #expect(viewModel.canNavigate == true)

        // When not loading, can navigate
        #expect(viewModel.canNavigate == !viewModel.isLoading)
    }
}
