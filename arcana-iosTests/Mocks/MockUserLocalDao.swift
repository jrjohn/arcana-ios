//
//  MockUserLocalDao.swift
//  arcana-iosTests
//

import Foundation
@testable import arcana_ios

/// Mock local data source for testing OfflineFirstUserRepository
final class MockUserLocalDao: UserLocalDao {
    var users: [User] = []
    var shouldThrowError: Error?
    var saveUsersCallCount = 0
    var createUserCallCount = 0
    var updateUserCallCount = 0
    var deleteUserCallCount = 0

    func getUsers() async throws -> [User] {
        if let error = shouldThrowError { throw error }
        return users
    }

    func getUser(id: String) async throws -> User {
        if let error = shouldThrowError { throw error }
        guard let user = users.first(where: { $0.id == id }) else {
            throw AppError.serverError(.E3002_NOT_FOUND, statusCode: 404, message: "Not found locally")
        }
        return user
    }

    func createUser(_ user: User) async throws {
        createUserCallCount += 1
        if let error = shouldThrowError { throw error }
        users.append(user)
    }

    func updateUser(_ user: User) async throws {
        updateUserCallCount += 1
        if let error = shouldThrowError { throw error }
        if let idx = users.firstIndex(where: { $0.id == user.id }) {
            users[idx] = user
        } else {
            users.append(user)
        }
    }

    func deleteUser(_ user: User) async throws {
        deleteUserCallCount += 1
        if let error = shouldThrowError { throw error }
        users.removeAll { $0.id == user.id }
    }

    func saveUsers(_ users: [User]) async throws {
        saveUsersCallCount += 1
        if let error = shouldThrowError { throw error }
        self.users = users
    }

    func searchUsers(query: String) async throws -> [User] {
        if let error = shouldThrowError { throw error }
        let q = query.lowercased()
        return users.filter {
            $0.firstName.lowercased().contains(q) ||
            $0.lastName.lowercased().contains(q) ||
            $0.email.lowercased().contains(q)
        }
    }

    func clearAll() async throws {
        if let error = shouldThrowError { throw error }
        users.removeAll()
    }
}
