//
//  LocalUserDataSource.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation

/// Protocol for local data access
protocol LocalUserDataSource {
    func getUsers() async throws -> [User]
    func getUser(id: String) async throws -> User
    func createUser(_ user: User) async throws
    func updateUser(_ user: User) async throws
    func deleteUser(_ user: User) async throws
    func saveUsers(_ users: [User]) async throws
    func searchUsers(query: String) async throws -> [User]
    func clearAll() async throws
}
