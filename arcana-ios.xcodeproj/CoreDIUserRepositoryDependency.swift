//
//  UserRepositoryDependency.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Dependencies
import Foundation

// MARK: - UserRepository Dependency Key

extension DependencyValues {
    var userRepository: UserRepository {
        get { self[UserRepositoryKey.self] }
        set { self[UserRepositoryKey.self] = newValue }
    }
}

enum UserRepositoryKey: DependencyKey {
    static let liveValue: UserRepository = {
        // Note: This will be initialized in the app with actual data sources
        fatalError("UserRepository must be set at app launch")
    }()
    
    static let testValue: UserRepository = MockUserRepository()
    
    static let previewValue: UserRepository = MockUserRepository()
}

// MARK: - Mock UserRepository

final class MockUserRepository: UserRepository {
    var users: [User] = User.mockUsers
    
    func getUsers() async throws -> [User] {
        users
    }
    
    func getUser(id: String) async throws -> User {
        guard let user = users.first(where: { $0.id == id }) else {
            throw AppError.serverError(.E3002_NOT_FOUND, statusCode: 404, message: "User not found")
        }
        return user
    }
    
    func createUser(_ user: User) async throws -> User {
        users.append(user)
        return user
    }
    
    func updateUser(_ user: User) async throws -> User {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
        }
        return user
    }
    
    func deleteUser(_ user: User) async throws {
        users.removeAll { $0.id == user.id }
    }
    
    func searchUsers(query: String) async throws -> [User] {
        let lowercased = query.lowercased()
        return users.filter {
            $0.firstName.lowercased().contains(lowercased) ||
            $0.lastName.lowercased().contains(lowercased) ||
            $0.email.lowercased().contains(lowercased)
        }
    }
    
    func refreshUsers() async throws -> [User] {
        users
    }
}
