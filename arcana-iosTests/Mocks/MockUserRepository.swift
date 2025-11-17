//
//  MockUserRepository.swift
//  arcana-iosTests
//
//  Created by John on 2025/11/15
//

import Foundation
@testable import arcana_ios

/// Mock implementation of UserRepository for testing
final class MockUserRepository: UserRepository {
    var users: [User] = []
    var shouldThrowError: AppError?
    var getUsersCallCount = 0
    var createUserCallCount = 0
    var updateUserCallCount = 0
    var deleteUserCallCount = 0

    func getUsers() async throws -> [User] {
        getUsersCallCount += 1
        if let error = shouldThrowError {
            throw error
        }
        return users
    }

    func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User> {
        getUsersCallCount += 1
        if let error = shouldThrowError {
            throw error
        }

        let startIndex = (page - 1) * perPage
        let endIndex = min(startIndex + perPage, users.count)

        guard startIndex < users.count else {
            return PaginatedResult(
                items: [],
                currentPage: page,
                totalPages: (users.count + perPage - 1) / perPage,
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
        getUsersCallCount += 1
        if let error = shouldThrowError {
            throw error
        }

        guard let user = users.first(where: { $0.id == id }) else {
            throw AppError.serverError(.E3002_NOT_FOUND, statusCode: 404, message: "User not found")
        }

        return user
    }

    func createUser(_ user: User) async throws -> User {
        createUserCallCount += 1
        if let error = shouldThrowError {
            throw error
        }

        users.append(user)
        return user
    }

    func updateUser(_ user: User) async throws -> User {
        updateUserCallCount += 1
        if let error = shouldThrowError {
            throw error
        }

        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
        }

        return user
    }

    func deleteUser(_ user: User) async throws {
        deleteUserCallCount += 1
        if let error = shouldThrowError {
            throw error
        }

        users.removeAll { $0.id == user.id }
    }

    func searchUsers(query: String) async throws -> [User] {
        if let error = shouldThrowError {
            throw error
        }

        return users.filter { user in
            user.fullName.localizedCaseInsensitiveContains(query) ||
            user.email.localizedCaseInsensitiveContains(query)
        }
    }

    func refreshUsers() async throws -> [User] {
        getUsersCallCount += 1
        if let error = shouldThrowError {
            throw error
        }
        return users
    }

    func reset() {
        users.removeAll()
        shouldThrowError = nil
        getUsersCallCount = 0
        createUserCallCount = 0
        updateUserCallCount = 0
        deleteUserCallCount = 0
    }
}
