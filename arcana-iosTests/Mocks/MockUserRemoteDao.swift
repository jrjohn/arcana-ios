//
//  MockUserRemoteDao.swift
//  arcana-iosTests
//

import Foundation
@testable import arcana_ios

/// Mock remote data source for testing OfflineFirstUserRepository
final class MockUserRemoteDao: UserRemoteDao {
    var users: [User] = []
    var shouldThrowError: Error?
    var createUserCallCount = 0
    var updateUserCallCount = 0
    var deleteUserCallCount = 0

    func getUsers() async throws -> [User] {
        if let error = shouldThrowError { throw error }
        return users
    }

    func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User> {
        if let error = shouldThrowError { throw error }
        let startIndex = (page - 1) * perPage
        let endIndex = min(startIndex + perPage, users.count)
        guard startIndex < users.count else {
            return PaginatedResult(
                items: [],
                currentPage: page,
                totalPages: max(1, (users.count + perPage - 1) / perPage),
                hasMore: false
            )
        }
        let pageUsers = Array(users[startIndex..<endIndex])
        let totalPages = (users.count + perPage - 1) / perPage
        return PaginatedResult(
            items: pageUsers,
            currentPage: page,
            totalPages: totalPages,
            hasMore: page < totalPages
        )
    }

    func getUser(id: String) async throws -> User {
        if let error = shouldThrowError { throw error }
        guard let user = users.first(where: { $0.id == id }) else {
            throw AppError.serverError(.E3002_NOT_FOUND, statusCode: 404, message: "Not found")
        }
        return user
    }

    func createUser(_ user: User) async throws -> User {
        createUserCallCount += 1
        if let error = shouldThrowError { throw error }
        users.append(user)
        return user
    }

    func updateUser(_ user: User) async throws -> User {
        updateUserCallCount += 1
        if let error = shouldThrowError { throw error }
        if let idx = users.firstIndex(where: { $0.id == user.id }) {
            users[idx] = user
        }
        return user
    }

    func deleteUser(_ user: User) async throws {
        deleteUserCallCount += 1
        if let error = shouldThrowError { throw error }
        users.removeAll { $0.id == user.id }
    }

    func searchUsers(query: String) async throws -> [User] {
        if let error = shouldThrowError { throw error }
        let q = query.lowercased()
        return users.filter {
            $0.firstName.lowercased().contains(q) ||
            $0.email.lowercased().contains(q)
        }
    }

    func refreshUsers() async throws -> [User] {
        if let error = shouldThrowError { throw error }
        return users
    }
}
