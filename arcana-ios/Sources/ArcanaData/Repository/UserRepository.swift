//
//  UserRepository.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation

/// Result for paginated data
struct PaginatedResult<T> {
    let items: [T]
    let currentPage: Int
    let totalPages: Int
    let hasMore: Bool
}

/// Protocol defining data access operations for users
protocol UserRepository {
    /// Get all users (from cache, local DB, or remote)
    func getUsers() async throws -> [User]

    /// Get users with pagination
    func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User>

    /// Get a specific user by ID
    func getUser(id: String) async throws -> User

    /// Create a new user
    func createUser(_ user: User) async throws -> User

    /// Update an existing user
    func updateUser(_ user: User) async throws -> User

    /// Delete a user
    func deleteUser(_ user: User) async throws

    /// Search users by query
    func searchUsers(query: String) async throws -> [User]

    /// Force refresh from remote source
    func refreshUsers() async throws -> [User]
}
