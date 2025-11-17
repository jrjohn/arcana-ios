//
//  UserListViewModel.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation
import Observation
import Dependencies

/// ViewModel for User List using Observation framework
@MainActor
@Observable
final class UserListViewModel {

    // MARK: - Input
    enum Input {
        case loadInitial
        case loadNextPage
        case refresh
        case selectUser(User)
        case deleteUser(User)
        case search(String)
        case retryLastOperation
        case syncOfflineChanges
        case updatePendingChangesCount(Int)
    }

    // MARK: - Effect
    enum Effect {
        case showError(AppError)
        case showSuccess(String)
        case navigateToDetail(User)
        case showDeleteConfirmation(User)
    }

    // MARK: - Output
    struct Output {
        var users: [User] = []
        var isLoading: Bool = false
        var isLoadingMore: Bool = false
        var isRefreshing: Bool = false
        var errorMessage: String?
        var searchQuery: String = ""
        var filteredUsers: [User] = []
        var pendingChangesCount: Int = 0
        var currentPage: Int = 1
        var totalPages: Int = 1
        var hasMorePages: Bool = false
    }

    // MARK: - Observable State
    private(set) var output = Output()
    private let perPage: Int = AppConstants.Pagination.defaultPageSize

    // MARK: - Dependencies (injected via swift-dependencies)
    @ObservationIgnored
    @Dependency(\.userService) var userService

    @ObservationIgnored
    @Dependency(\.analyticsTracker) var analyticsTracker

    @ObservationIgnored
    @Dependency(\.userRepository) var userRepository

    @ObservationIgnored
    private var lastFailedOperation: Input?

    @ObservationIgnored
    private var navGraph: NavGraph?

    // MARK: - Initialization
    init(navGraph: NavGraph? = nil) {
        self.navGraph = navGraph
    }

    // MARK: - Public Methods

    /// Process an input action and receive optional effect
    /// - Parameter action: The user action to process
    /// - Returns: Optional effect that the view should handle
    func input(_ action: Input) async -> Effect? {
        switch action {
        case .loadInitial:
            return await loadUsers()
        case .loadNextPage:
            return await loadNextPage()
        case .refresh:
            return await refreshUsers()
        case .selectUser(let user):
            return selectUser(user)
        case .deleteUser(let user):
            return await deleteUser(user)
        case .search(let query):
            output.searchQuery = query
            updateFilteredUsers()
            return await searchUsers(query: query)
        case .retryLastOperation:
            return await retryLastOperation()
        case .syncOfflineChanges:
            return await syncOfflineChanges()
        case .updatePendingChangesCount(let count):
            output.pendingChangesCount = count
            return nil
        }
    }

    // MARK: - Private Methods

    private func loadUsers() async -> Effect? {
        output.isLoading = true
        output.errorMessage = nil
        output.currentPage = 1

        analyticsTracker.trackScreen("User List")

        defer { output.isLoading = false }

        do {
            let result = try await userService.getUsers(page: output.currentPage, perPage: perPage)
            output.users = result.items
            output.currentPage = result.currentPage
            output.totalPages = result.totalPages
            output.hasMorePages = result.hasMore
            updateFilteredUsers()

            analyticsTracker.trackEvent(.pageLoaded, params: [
                "screen": "user_list",
                "count": result.items.count,
                "page": output.currentPage,
                "total_pages": output.totalPages
            ])

            return nil
        } catch {
            return handleError(AppError.from(error), operation: .loadInitial)
        }
    }

    private func loadNextPage() async -> Effect? {
        guard !output.isLoadingMore && output.hasMorePages else { return nil }

        output.isLoadingMore = true
        output.errorMessage = nil

        defer { output.isLoadingMore = false }

        let nextPage = output.currentPage + 1

        do {
            let result = try await userService.getUsers(page: nextPage, perPage: perPage)

            // Append new users
            output.users.append(contentsOf: result.items)
            output.currentPage = result.currentPage
            output.totalPages = result.totalPages
            output.hasMorePages = result.hasMore
            updateFilteredUsers()

            analyticsTracker.trackEvent(.pageLoaded, params: [
                "screen": "user_list",
                "count": result.items.count,
                "page": output.currentPage,
                "total_pages": output.totalPages
            ])

            return nil
        } catch {
            return handleError(AppError.from(error), operation: .loadNextPage)
        }
    }

    private func refreshUsers() async -> Effect? {
        output.isRefreshing = true
        output.errorMessage = nil
        output.currentPage = 1

        defer { output.isRefreshing = false }

        do {
            // Load first page with pagination
            let result = try await userService.getUsers(page: 1, perPage: perPage)
            output.users = result.items
            output.currentPage = result.currentPage
            output.totalPages = result.totalPages
            output.hasMorePages = result.hasMore
            updateFilteredUsers()

            analyticsTracker.trackEvent(.listRefreshed, params: [
                "count": result.items.count,
                "page": output.currentPage,
                "total_pages": output.totalPages
            ])

            return .showSuccess("Users refreshed successfully")
        } catch {
            return handleError(AppError.from(error), operation: .refresh)
        }
    }

    private func selectUser(_ user: User) -> Effect? {
        analyticsTracker.trackEvent(.userSelected, params: [
            "userId": user.id,
            "email": user.email
        ])

        // Use NavGraph if available, otherwise return navigation effect
        if let navGraph = navGraph {
            navGraph.navigateToUserDetail(user)
            return nil
        } else {
            return .navigateToDetail(user)
        }
    }

    private func deleteUser(_ user: User) async -> Effect? {
        output.isLoading = true
        output.errorMessage = nil

        defer { output.isLoading = false }

        do {
            try await userService.deleteUser(user)

            // Remove from local state
            output.users.removeAll { $0.id == user.id }
            updateFilteredUsers()

            analyticsTracker.trackEvent(.userDeleteSuccess, params: [
                "userId": user.id
            ])

            return .showSuccess("User deleted successfully")
        } catch {
            return handleError(AppError.from(error), operation: .deleteUser(user))
        }
    }

    private func searchUsers(query: String) async -> Effect? {
        if query.isEmpty {
            updateFilteredUsers()
            return nil
        }

        output.isLoading = true
        defer { output.isLoading = false }

        do {
            let results = try await userService.searchUsers(query: query)
            output.filteredUsers = results

            analyticsTracker.trackEvent(.listSearched, params: [
                "query": query,
                "results": results.count
            ])

            return nil
        } catch {
            // For search errors, just show all users
            updateFilteredUsers()
            return handleError(AppError.from(error), operation: .search(query))
        }
    }

    private func updateFilteredUsers() {
        if output.searchQuery.isEmpty {
            output.filteredUsers = output.users
        } else {
            let lowercasedQuery = output.searchQuery.lowercased()
            output.filteredUsers = output.users.filter { user in
                user.firstName.lowercased().contains(lowercasedQuery) ||
                user.lastName.lowercased().contains(lowercasedQuery) ||
                user.email.lowercased().contains(lowercasedQuery)
            }
        }
    }

    private func retryLastOperation() async -> Effect? {
        guard let operation = lastFailedOperation else { return nil }
        lastFailedOperation = nil
        return await input(operation)
    }

    private func handleError(_ error: AppError, operation: Input) -> Effect {
        lastFailedOperation = operation
        output.errorMessage = error.message
        analyticsTracker.trackAppError(error, context: [
            "screen": "user_list",
            "operation": String(describing: operation)
        ])
        return .showError(error)
    }

    private func syncOfflineChanges() async -> Effect? {
        guard let repository = userRepository as? OfflineFirstUserRepository else {
            return nil
        }

        await repository.processOfflineChanges()

        // Refresh the user list after sync
        _ = await refreshUsers()

        return .showSuccess("Sync completed successfully")
    }
}

// MARK: - Computed Properties
extension UserListViewModel {
    var displayedUsers: [User] {
        output.filteredUsers
    }

    var isSearching: Bool {
        !output.searchQuery.isEmpty
    }

    var emptyStateMessage: String {
        if isSearching {
            return "No users found matching '\(output.searchQuery)'"
        } else if output.users.isEmpty {
            return "No users available"
        } else {
            return ""
        }
    }

    var canRetry: Bool {
        lastFailedOperation != nil && !output.isLoading
    }
}
