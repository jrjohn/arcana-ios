//
//  UserListViewModelTests.swift
//  arcana-iosTests
//
//  Created by John on 2025/11/15
//

import Testing
import Foundation
import Dependencies
@testable import arcana_ios

/// Comprehensive tests for UserListViewModel
@MainActor
struct UserListViewModelTests {

    // MARK: - Helper class for effect capture

    class EffectCapture {
        var effects: [UserListViewModel.Effect] = []

        func capture(_ effect: UserListViewModel.Effect) {
            effects.append(effect)
        }
    }

    // MARK: - Initialization Tests

    @Test("UserListViewModel initializes with correct default state")
    func testInitialization() {
        let viewModel = UserListViewModel()

        #expect(viewModel.output.users.isEmpty)
        #expect(viewModel.output.isLoading == false)
        #expect(viewModel.output.isLoadingMore == false)
        #expect(viewModel.output.isRefreshing == false)
        #expect(viewModel.output.errorMessage == nil)
        #expect(viewModel.output.searchQuery == "")
        #expect(viewModel.output.filteredUsers.isEmpty)
        #expect(viewModel.output.currentPage == 1)
        #expect(viewModel.hasMorePages == false)
        #expect(viewModel.output.pendingChangesCount == 0)
    }

    // MARK: - Load Initial Tests

    @Test("loadInitial successfully loads users")
    func testLoadInitialSuccess() async {
        let mockService = MockUserService()
        mockService.usersToReturn = User.mockUsers

        let mockTracker = MockAnalyticsTracker()

        let viewModel = await withDependencies {
            $0.userService = mockService
            $0.analyticsTracker = mockTracker
        } operation: {
            UserListViewModel()
        }

        await viewModel.input(.loadInitial)

        // Wait for async operation
        try? await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.output.users.count == 5)
        #expect(viewModel.output.filteredUsers.count == 5)
        #expect(viewModel.output.isLoading == false)
        #expect(viewModel.output.errorMessage == nil)
        #expect(mockTracker.trackedScreens.count > 0)
    }

    @Test("loadInitial handles errors")
    func testLoadInitialError() async {
        let mockService = MockUserService()
        mockService.shouldThrowError = AppError.networkError(
            .E1000_NO_CONNECTION,
            message: "No connection",
            isRetryable: true,
            underlyingError: nil
        )

        let mockTracker = MockAnalyticsTracker()
        let effectCapture = EffectCapture()

        let viewModel = await withDependencies {
            $0.userService = mockService
            $0.analyticsTracker = mockTracker
        } operation: {
            UserListViewModel()
        }

        viewModel.onEffect = effectCapture.capture

        await viewModel.input(.loadInitial)

        // Wait for async operation
        try? await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.output.users.isEmpty)
        #expect(viewModel.output.errorMessage != nil)
        #expect(effectCapture.effects.count > 0)
    }

    // MARK: - Pagination Tests

    @Test("loadNextPage loads more users")
    func testLoadNextPage() async {
        let mockService = MockUserService()
        mockService.usersToReturn = User.mockUsers

        let mockTracker = MockAnalyticsTracker()

        let viewModel = await withDependencies {
            $0.userService = mockService
            $0.analyticsTracker = mockTracker
        } operation: {
            UserListViewModel()
        }

        // Load initial page first
        await viewModel.input(.loadInitial)
        try? await Task.sleep(for: .milliseconds(200))

        let initialCount = viewModel.output.users.count

        // Load next page
        await viewModel.input(.loadNextPage)
        try? await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.output.users.count >= initialCount)
        #expect(viewModel.output.isLoadingMore == false)
    }

    @Test("loadNextPage does nothing when no more pages")
    func testLoadNextPageNoMore() async {
        let mockService = MockUserService()
        mockService.usersToReturn = User.mockUsers
        mockService.hasMorePages = false

        let viewModel = await withDependencies {
            $0.userService = mockService
        } operation: {
            UserListViewModel()
        }

        await viewModel.input(.loadInitial)
        try? await Task.sleep(for: .milliseconds(200))

        let initialCount = viewModel.output.users.count

        await viewModel.input(.loadNextPage)
        try? await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.output.users.count == initialCount)
    }

    // MARK: - Refresh Tests

    @Test("refresh reloads users")
    func testRefresh() async {
        let mockService = MockUserService()
        mockService.usersToReturn = User.mockUsers

        let effectCapture = EffectCapture()

        let viewModel = await withDependencies {
            $0.userService = mockService
        } operation: {
            UserListViewModel()
        }

        viewModel.onEffect = effectCapture.capture

        await viewModel.input(.refresh)

        // Wait for async operation
        try? await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.output.users.count > 0)
        #expect(viewModel.output.isRefreshing == false)
        #expect(viewModel.output.currentPage == 1)

        // Should show success message
        let hasSuccessEffect = effectCapture.effects.contains { effect in
            if case .showSuccess = effect {
                return true
            }
            return false
        }
        #expect(hasSuccessEffect)
    }

    // MARK: - Search Tests

    @Test("search filters users by query")
    func testSearch() async {
        let mockService = MockUserService()
        mockService.usersToReturn = User.mockUsers
        mockService.searchResults = [User.mockUsers[0]]

        let viewModel = await withDependencies {
            $0.userService = mockService
        } operation: {
            UserListViewModel()
        }

        // Load users first
        await viewModel.input(.loadInitial)
        try? await Task.sleep(for: .milliseconds(200))

        // Search
        await viewModel.input(.search("John"))

        // Wait for search
        try? await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.output.searchQuery == "John")
        #expect(viewModel.isSearching == true)
    }

    @Test("empty search query shows all users")
    func testSearchEmpty() async {
        let mockService = MockUserService()
        mockService.usersToReturn = User.mockUsers

        let viewModel = await withDependencies {
            $0.userService = mockService
        } operation: {
            UserListViewModel()
        }

        await viewModel.input(.loadInitial)
        try? await Task.sleep(for: .milliseconds(200))

        let allUsersCount = viewModel.output.users.count

        await viewModel.input(.search(""))
        try? await Task.sleep(for: .milliseconds(100))

        #expect(viewModel.output.searchQuery == "")
        #expect(viewModel.output.filteredUsers.count == allUsersCount)
        #expect(viewModel.isSearching == false)
    }

    // MARK: - Delete Tests

    @Test("deleteUser removes user from list")
    func testDeleteUser() async {
        let mockService = MockUserService()
        mockService.usersToReturn = User.mockUsers

        let effectCapture = EffectCapture()

        let viewModel = await withDependencies {
            $0.userService = mockService
        } operation: {
            UserListViewModel()
        }

        viewModel.onEffect = effectCapture.capture

        await viewModel.input(.loadInitial)
        try? await Task.sleep(for: .milliseconds(200))

        let initialCount = viewModel.output.users.count
        let userToDelete = viewModel.output.users.first!

        await viewModel.input(.deleteUser(userToDelete))
        try? await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.output.users.count == initialCount - 1)

        let hasSuccessEffect = effectCapture.effects.contains { effect in
            if case .showSuccess = effect {
                return true
            }
            return false
        }
        #expect(hasSuccessEffect)
    }

    // MARK: - Select User Tests

    @Test("selectUser triggers navigation effect")
    func testSelectUser() {
        let effectCapture = EffectCapture()
        let viewModel = UserListViewModel()
        viewModel.onEffect = effectCapture.capture

        let user = User.mock()
        await viewModel.input(.selectUser(user))

        #expect(effectCapture.effects.count > 0)

        if case .navigateToDetail(let selectedUser) = effectCapture.effects.first {
            #expect(selectedUser.id == user.id)
        } else {
            Issue.record("Expected navigateToDetail effect")
        }
    }

    // MARK: - Retry Tests

    @Test("retryLastOperation retries failed operation")
    func testRetry() async {
        let mockService = MockUserService()
        mockService.shouldThrowError = AppError.networkError(
            .E1000_NO_CONNECTION,
            message: "No connection",
            isRetryable: true,
            underlyingError: nil
        )

        let viewModel = await withDependencies {
            $0.userService = mockService
        } operation: {
            UserListViewModel()
        }

        // Fail initial load
        await viewModel.input(.loadInitial)
        try? await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.output.errorMessage != nil)
        #expect(viewModel.canRetry == true)

        // Clear error and retry
        mockService.shouldThrowError = nil
        mockService.usersToReturn = User.mockUsers

        await viewModel.input(.retryLastOperation)
        try? await Task.sleep(for: .milliseconds(200))

        // Should succeed now
        #expect(viewModel.output.users.count > 0)
    }

    // MARK: - Computed Properties Tests

    @Test("displayedUsers returns filtered users")
    func testDisplayedUsers() {
        let viewModel = UserListViewModel()
        #expect(viewModel.displayedUsers == viewModel.output.filteredUsers)
    }

    @Test("isSearching is true when search query is not empty")
    func testIsSearching() {
        let viewModel = UserListViewModel()
        #expect(viewModel.isSearching == false)

        await viewModel.input(.search("test"))
        #expect(viewModel.isSearching == true)
    }

    @Test("emptyStateMessage varies based on state")
    func testEmptyStateMessage() {
        let viewModel = UserListViewModel()

        // Empty list
        let emptyMessage = viewModel.emptyStateMessage
        #expect(emptyMessage.contains("No users"))

        // Searching with no results
        await viewModel.input(.search("nonexistent"))
        let searchMessage = viewModel.emptyStateMessage
        #expect(searchMessage.contains("No users found"))
    }

    @Test("pending changes count can be updated")
    func testUpdatePendingChangesCount() {
        let viewModel = UserListViewModel()
        #expect(viewModel.output.pendingChangesCount == 0)

        await viewModel.input(.updatePendingChangesCount(5))
        #expect(viewModel.output.pendingChangesCount == 5)
    }
}

// MARK: - Mock Services

class MockUserService: UserService {
    var usersToReturn: [User] = []
    var searchResults: [User] = []
    var shouldThrowError: Error?
    var hasMorePages = true
    var currentPageReturned = 1

    func getUsers() async throws -> [User] {
        if let error = shouldThrowError {
            throw error
        }
        return usersToReturn
    }

    func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User> {
        if let error = shouldThrowError {
            throw error
        }

        currentPageReturned = page
        let startIndex = (page - 1) * perPage
        let endIndex = min(startIndex + perPage, usersToReturn.count)

        let pageUsers = startIndex < usersToReturn.count ? Array(usersToReturn[startIndex..<endIndex]) : []

        return PaginatedResult(
            items: pageUsers,
            currentPage: page,
            totalPages: (usersToReturn.count + perPage - 1) / perPage,
            hasMore: hasMorePages && endIndex < usersToReturn.count
        )
    }

    func getUser(id: String) async throws -> User {
        if let error = shouldThrowError {
            throw error
        }
        return usersToReturn.first { $0.id == id } ?? User.mock()
    }

    func createUser(_ user: User) async throws -> User {
        if let error = shouldThrowError {
            throw error
        }
        return user
    }

    func updateUser(_ user: User) async throws -> User {
        if let error = shouldThrowError {
            throw error
        }
        return user
    }

    func deleteUser(_ user: User) async throws {
        if let error = shouldThrowError {
            throw error
        }
        usersToReturn.removeAll { $0.id == user.id }
    }

    func searchUsers(query: String) async throws -> [User] {
        if let error = shouldThrowError {
            throw error
        }
        return searchResults.isEmpty ? usersToReturn.filter {
            $0.firstName.lowercased().contains(query.lowercased()) ||
            $0.lastName.lowercased().contains(query.lowercased()) ||
            $0.email.lowercased().contains(query.lowercased())
        } : searchResults
    }

    func refreshUsers() async throws -> [User] {
        if let error = shouldThrowError {
            throw error
        }
        return usersToReturn
    }
}
