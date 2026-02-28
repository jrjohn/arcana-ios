//
//  UserRemoteDao.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation

/// Protocol defining remote DAO operations for users
/// This is essentially the same as UserRepository for remote operations
protocol UserRemoteDao {
    /// Fetch all users from remote source
    func getUsers() async throws -> [User]

    /// Fetch users with pagination from remote source
    func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User>

    /// Fetch a specific user by ID from remote source
    func getUser(id: String) async throws -> User

    /// Create a new user on remote source
    func createUser(_ user: User) async throws -> User

    /// Update an existing user on remote source
    func updateUser(_ user: User) async throws -> User

    /// Delete a user from remote source
    func deleteUser(_ user: User) async throws

    /// Search users by query on remote source
    func searchUsers(query: String) async throws -> [User]

    /// Force refresh users from remote source
    func refreshUsers() async throws -> [User]
}
