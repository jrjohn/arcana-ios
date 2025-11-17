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

    // MARK: - Observable State
    private(set) var users: [User] = []
    private(set) var isLoading: Bool = false
    private(set) var isLoadingMore: Bool = false
    private(set) var isRefreshing: Bool = false
    private(set) var errorMessage: String?
    var searchQuery: String = "" {
        didSet {
            updateFilteredUsers()
        }
    }
    private(set) var filteredUsers: [User] = []
    private(set) var pendingChangesCount: Int = 0

    // Pagination state
    private(set) var currentPage: Int = 1
    private(set) var totalPages: Int = 1
    private(set) var hasMorePages: Bool = false
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

    /// Send an input action and receive optional effect
    /// - Parameter input: The user action to process
    /// - Returns: Optional effect that the view should handle
    func send(_ input: Input) async -> Effect? {
        switch input {
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
            searchQuery = query
            return await searchUsers(query: query)
        case .retryLastOperation:
            return await retryLastOperation()
        case .syncOfflineChanges:
            return await syncOfflineChanges()
        case .updatePendingChangesCount(let count):
            pendingChangesCount = count
            return nil
        }
    }

    // MARK: - Private Methods

    private func loadUsers() async -> Effect? {
        isLoading = true
        errorMessage = nil
        currentPage = 1

        analyticsTracker.trackScreen("User List")

        defer { isLoading = false }

        do {
            let result = try await userService.getUsers(page: currentPage, perPage: perPage)
            users = result.items
            currentPage = result.currentPage
            totalPages = result.totalPages
            hasMorePages = result.hasMore
            updateFilteredUsers()

            analyticsTracker.trackEvent(.pageLoaded, params: [
                "screen": "user_list",
                "count": result.items.count,
                "page": currentPage,
                "total_pages": totalPages
            ])

            return nil
        } catch {
            return handleError(AppError.from(error), operation: .loadInitial)
        }
    }

    private func loadNextPage() async -> Effect? {
        guard !isLoadingMore && hasMorePages else { return nil }

        isLoadingMore = true
        errorMessage = nil

        defer { isLoadingMore = false }

        let nextPage = currentPage + 1

        do {
            let result = try await userService.getUsers(page: nextPage, perPage: perPage)

            // Append new users
            users.append(contentsOf: result.items)
            currentPage = result.currentPage
            totalPages = result.totalPages
            hasMorePages = result.hasMore
            updateFilteredUsers()

            analyticsTracker.trackEvent(.pageLoaded, params: [
                "screen": "user_list",
                "count": result.items.count,
                "page": currentPage,
                "total_pages": totalPages
            ])

            return nil
        } catch {
            return handleError(AppError.from(error), operation: .loadNextPage)
        }
    }

    private func refreshUsers() async -> Effect? {
        isRefreshing = true
        errorMessage = nil
        currentPage = 1

        defer { isRefreshing = false }

        do {
            // Load first page with pagination
            let result = try await userService.getUsers(page: 1, perPage: perPage)
            users = result.items
            currentPage = result.currentPage
            totalPages = result.totalPages
            hasMorePages = result.hasMore
            updateFilteredUsers()

            analyticsTracker.trackEvent(.listRefreshed, params: [
                "count": result.items.count,
                "page": currentPage,
                "total_pages": totalPages
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
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try await userService.deleteUser(user)

            // Remove from local state
            users.removeAll { $0.id == user.id }
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

        isLoading = true
        defer { isLoading = false }

        do {
            let results = try await userService.searchUsers(query: query)
            filteredUsers = results

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
        if searchQuery.isEmpty {
            filteredUsers = users
        } else {
            let lowercasedQuery = searchQuery.lowercased()
            filteredUsers = users.filter { user in
                user.firstName.lowercased().contains(lowercasedQuery) ||
                user.lastName.lowercased().contains(lowercasedQuery) ||
                user.email.lowercased().contains(lowercasedQuery)
            }
        }
    }

    private func retryLastOperation() async -> Effect? {
        guard let operation = lastFailedOperation else { return nil }
        lastFailedOperation = nil
        return await send(operation)
    }

    private func handleError(_ error: AppError, operation: Input) -> Effect {
        lastFailedOperation = operation
        errorMessage = error.message
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
        filteredUsers
    }

    var isSearching: Bool {
        !searchQuery.isEmpty
    }

    var emptyStateMessage: String {
        if isSearching {
            return "No users found matching '\(searchQuery)'"
        } else if users.isEmpty {
            return "No users available"
        } else {
            return ""
        }
    }

    var canRetry: Bool {
        lastFailedOperation != nil && !isLoading
    }
}
