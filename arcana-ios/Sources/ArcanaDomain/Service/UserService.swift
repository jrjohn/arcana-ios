//
//  UserService.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation

/// Protocol defining user business logic operations
protocol UserService {
    /// Get all users
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

    /// Search users by name or email
    func searchUsers(query: String) async throws -> [User]

    /// Refresh users from remote source
    func refreshUsers() async throws -> [User]
}
