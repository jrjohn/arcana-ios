//
//  UserRemoteDaoMockImpl.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation

/// Mock implementation of UserRemoteDao for testing
final class UserRemoteDaoMockImpl: UserRemoteDao {
    
    // MARK: - Properties
    
    private var users: [User] = []
    private let simulateNetworkDelay: Bool
    private let networkDelay: TimeInterval
    private let shouldFailRequests: Bool
    
    // MARK: - Initialization
    
    init(
        simulateNetworkDelay: Bool = false,
        networkDelay: TimeInterval = 0.5,
        shouldFailRequests: Bool = false
    ) {
        self.simulateNetworkDelay = simulateNetworkDelay
        self.networkDelay = networkDelay
        self.shouldFailRequests = shouldFailRequests
        
        // Initialize with mock users
        self.users = User.mockUsers
    }
    
    // MARK: - UserRemoteDao Implementation
    
    func getUsers() async throws -> [User] {
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        }
        
        if shouldFailRequests {
            throw AppError.networkError(
                .E1003_NETWORK_IO,
                message: "Simulated network failure",
                isRetryable: true,
                underlyingError: nil
            )
        }
        
        return users
    }
    
    func getUser(id: String) async throws -> User {
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        }
        
        if shouldFailRequests {
            throw AppError.networkError(
                .E1003_NETWORK_IO,
                message: "Simulated network failure",
                isRetryable: true,
                underlyingError: nil
            )
        }
        
        guard let user = users.first(where: { $0.id == id }) else {
            throw AppError.serverError(
                .E3002_NOT_FOUND,
                statusCode: 404,
                message: "User not found"
            )
        }
        
        return user
    }
    
    func createUser(_ user: User) async throws -> User {
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        }
        
        if shouldFailRequests {
            throw AppError.networkError(
                .E1003_NETWORK_IO,
                message: "Simulated network failure",
                isRetryable: true,
                underlyingError: nil
            )
        }
        
        var newUser = user
        if newUser.id == "" || newUser.id == UUID().uuidString {
            newUser = User(
                id: UUID().uuidString,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                avatar: user.avatar,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        users.append(newUser)
        return newUser
    }
    
    func updateUser(_ user: User) async throws -> User {
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        }
        
        if shouldFailRequests {
            throw AppError.networkError(
                .E1003_NETWORK_IO,
                message: "Simulated network failure",
                isRetryable: true,
                underlyingError: nil
            )
        }
        
        guard let index = users.firstIndex(where: { $0.id == user.id }) else {
            throw AppError.serverError(
                .E3002_NOT_FOUND,
                statusCode: 404,
                message: "User not found"
            )
        }
        
        var updatedUser = user
        updatedUser = User(
            id: user.id,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            avatar: user.avatar,
            createdAt: users[index].createdAt,
            updatedAt: Date()
        )
        
        users[index] = updatedUser
        return updatedUser
    }
    
    func deleteUser(_ user: User) async throws {
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        }
        
        if shouldFailRequests {
            throw AppError.networkError(
                .E1003_NETWORK_IO,
                message: "Simulated network failure",
                isRetryable: true,
                underlyingError: nil
            )
        }
        
        guard let index = users.firstIndex(where: { $0.id == user.id }) else {
            throw AppError.serverError(
                .E3002_NOT_FOUND,
                statusCode: 404,
                message: "User not found"
            )
        }
        
        users.remove(at: index)
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        users = User.mockUsers
    }
    
    func setUsers(_ users: [User]) {
        self.users = users
    }
}
