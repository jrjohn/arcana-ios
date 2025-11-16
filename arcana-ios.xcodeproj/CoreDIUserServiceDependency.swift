//
//  UserServiceDependency.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Dependencies
import Foundation

// MARK: - UserService Dependency Key

extension DependencyValues {
    var userService: UserService {
        get { self[UserServiceKey.self] }
        set { self[UserServiceKey.self] = newValue }
    }
}

private enum UserServiceKey: DependencyKey {
    static let liveValue: UserService = UserServiceImpl(
        repository: UserRepositoryKey.liveValue,
        analyticsTracker: AnalyticsTrackerKey.liveValue
    )
    
    static let testValue: UserService = MockUserService()
    
    static let previewValue: UserService = MockUserService()
}

// MARK: - Mock UserService

final class MockUserService: UserService {
    var getUsersResult: Result<[User], Error> = .success(User.mockUsers)
    var getUserResult: Result<User, Error> = .success(User.mock())
    var createUserResult: Result<User, Error> = .success(User.mock())
    var updateUserResult: Result<User, Error> = .success(User.mock())
    var deleteUserResult: Result<Void, Error> = .success(())
    var searchUsersResult: Result<[User], Error> = .success([])
    var refreshUsersResult: Result<[User], Error> = .success(User.mockUsers)
    
    func getUsers() async throws -> [User] {
        try getUsersResult.get()
    }
    
    func getUser(id: String) async throws -> User {
        try getUserResult.get()
    }
    
    func createUser(_ user: User) async throws -> User {
        try createUserResult.get()
    }
    
    func updateUser(_ user: User) async throws -> User {
        try updateUserResult.get()
    }
    
    func deleteUser(_ user: User) async throws {
        try deleteUserResult.get()
    }
    
    func searchUsers(query: String) async throws -> [User] {
        try searchUsersResult.get()
    }
    
    func refreshUsers() async throws -> [User] {
        try refreshUsersResult.get()
    }
}
