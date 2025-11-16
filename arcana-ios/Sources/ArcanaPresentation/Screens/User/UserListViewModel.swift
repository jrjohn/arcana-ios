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
    private let perPage: Int = 10

    // MARK: - Effect Handler
    var onEffect: ((Effect) -> Void)?

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
    func send(_ input: Input) {
        Task {
            switch input {
            case .loadInitial:
                await loadUsers()
            case .loadNextPage:
                await loadNextPage()
            case .refresh:
                await refreshUsers()
            case .selectUser(let user):
                selectUser(user)
            case .deleteUser(let user):
                await deleteUser(user)
            case .search(let query):
                searchQuery = query
                await searchUsers(query: query)
            case .retryLastOperation:
                await retryLastOperation()
            case .syncOfflineChanges:
                await syncOfflineChanges()
            case .updatePendingChangesCount(let count):
                pendingChangesCount = count
            }
        }
    }

    // MARK: - Private Methods

    private func loadUsers() async {
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
        } catch {
            handleError(AppError.from(error), operation: .loadInitial)
        }
    }

    private func loadNextPage() async {
        guard !isLoadingMore && hasMorePages else { return }

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
        } catch {
            handleError(AppError.from(error), operation: .loadNextPage)
        }
    }

    private func refreshUsers() async {
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

            onEffect?(.showSuccess("Users refreshed successfully"))

            analyticsTracker.trackEvent(.listRefreshed, params: [
                "count": result.items.count,
                "page": currentPage,
                "total_pages": totalPages
            ])
        } catch {
            handleError(AppError.from(error), operation: .refresh)
        }
    }

    private func selectUser(_ user: User) {
        analyticsTracker.trackEvent(.userSelected, params: [
            "userId": user.id,
            "email": user.email
        ])

        // Use NavGraph if available, otherwise use effect handler
        if let navGraph = navGraph {
            navGraph.navigateToUserDetail(user)
        } else {
            onEffect?(.navigateToDetail(user))
        }
    }

    private func deleteUser(_ user: User) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try await userService.deleteUser(user)

            // Remove from local state
            users.removeAll { $0.id == user.id }
            updateFilteredUsers()

            onEffect?(.showSuccess("User deleted successfully"))

            analyticsTracker.trackEvent(.userDeleteSuccess, params: [
                "userId": user.id
            ])
        } catch {
            handleError(AppError.from(error), operation: .deleteUser(user))
        }
    }

    private func searchUsers(query: String) async {
        if query.isEmpty {
            updateFilteredUsers()
            return
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
        } catch {
            // For search errors, just show all users
            updateFilteredUsers()
            handleError(AppError.from(error), operation: .search(query))
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

    private func retryLastOperation() async {
        guard let operation = lastFailedOperation else { return }
        lastFailedOperation = nil
        send(operation)
    }

    private func handleError(_ error: AppError, operation: Input) {
        lastFailedOperation = operation
        errorMessage = error.message
        onEffect?(.showError(error))
        analyticsTracker.trackAppError(error, context: [
            "screen": "user_list",
            "operation": String(describing: operation)
        ])
    }

    private func syncOfflineChanges() async {
        guard let repository = userRepository as? OfflineFirstUserRepository else {
            return
        }

        await repository.processOfflineChanges()

        // Refresh the user list after sync
        await refreshUsers()

        onEffect?(.showSuccess("Sync completed successfully"))
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
