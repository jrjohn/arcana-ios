//
//  UserRemoteDaoMockImpl.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation

/// Mock implementation of UserRemoteDao for development and testing
final class UserRemoteDaoMockImpl: UserRemoteDao {
    
    // MARK: - Configuration
    private let simulateNetworkDelay: Bool
    private let networkDelay: TimeInterval
    private let shouldFailRequests: Bool
    
    // MARK: - In-Memory Storage
    // Note: Not thread-safe, but acceptable for mock/testing purposes
    private var users: [String: User] = [:]
    
    init(
        simulateNetworkDelay: Bool = true,
        networkDelay: TimeInterval = 0.5,
        shouldFailRequests: Bool = false
    ) {
        self.simulateNetworkDelay = simulateNetworkDelay
        self.networkDelay = networkDelay
        self.shouldFailRequests = shouldFailRequests
        
        // Seed with mock data
        seedMockData()
    }
    
    // MARK: - UserRemoteDao Implementation
    
    func getUsers() async throws -> [User] {
        try await simulateDelay()

        if shouldFailRequests {
            throw AppError.networkError(
                .E1000_NO_CONNECTION,
                message: "Simulated network error",
                isRetryable: true,
                underlyingError: nil
            )
        }

        return Array(users.values).sorted { $0.createdAt > $1.createdAt }
    }

    func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User> {
        try await simulateDelay()

        if shouldFailRequests {
            throw AppError.networkError(
                .E1000_NO_CONNECTION,
                message: "Simulated network error",
                isRetryable: true,
                underlyingError: nil
            )
        }

        let allUsers = Array(users.values).sorted { $0.createdAt > $1.createdAt }
        let totalUsers = allUsers.count
        let totalPages = (totalUsers + perPage - 1) / perPage

        let startIndex = (page - 1) * perPage
        let endIndex = min(startIndex + perPage, totalUsers)

        guard startIndex < totalUsers else {
            return PaginatedResult(
                items: [],
                currentPage: page,
                totalPages: totalPages,
                hasMore: false
            )
        }

        let pageUsers = Array(allUsers[startIndex..<endIndex])

        return PaginatedResult(
            items: pageUsers,
            currentPage: page,
            totalPages: totalPages,
            hasMore: page < totalPages
        )
    }
    
    func getUser(id: String) async throws -> User {
        try await simulateDelay()
        
        
        if shouldFailRequests {
            throw AppError.networkError(
                .E1000_NO_CONNECTION,
                message: "Simulated network error",
                isRetryable: true,
                underlyingError: nil
            )
        }
        
        guard let user = users[id] else {
            throw AppError.serverError(
                .E3002_NOT_FOUND,
                statusCode: 404,
                message: "User not found"
            )
        }
        
        return user
    }
    
    func createUser(_ user: User) async throws -> User {
        try await simulateDelay()
        
        
        if shouldFailRequests {
            throw AppError.networkError(
                .E1000_NO_CONNECTION,
                message: "Simulated network error",
                isRetryable: true,
                underlyingError: nil
            )
        }
        
        // Check for duplicate email
        if users.values.contains(where: { $0.email == user.email }) {
            throw AppError.conflictError(
                .E5002_DUPLICATE_ENTRY,
                message: "User with this email already exists"
            )
        }
        
        users[user.id] = user
        return user
    }
    
    func updateUser(_ user: User) async throws -> User {
        try await simulateDelay()
        
        
        if shouldFailRequests {
            throw AppError.networkError(
                .E1000_NO_CONNECTION,
                message: "Simulated network error",
                isRetryable: true,
                underlyingError: nil
            )
        }
        
        guard users[user.id] != nil else {
            throw AppError.serverError(
                .E3002_NOT_FOUND,
                statusCode: 404,
                message: "User not found"
            )
        }
        
        users[user.id] = user
        return user
    }
    
    func deleteUser(_ user: User) async throws {
        try await simulateDelay()
        
        
        if shouldFailRequests {
            throw AppError.networkError(
                .E1000_NO_CONNECTION,
                message: "Simulated network error",
                isRetryable: true,
                underlyingError: nil
            )
        }
        
        guard users[user.id] != nil else {
            throw AppError.serverError(
                .E3002_NOT_FOUND,
                statusCode: 404,
                message: "User not found"
            )
        }
        
        users.removeValue(forKey: user.id)
    }

    func searchUsers(query: String) async throws -> [User] {
        try await simulateDelay()

        if shouldFailRequests {
            throw AppError.networkError(
                .E1000_NO_CONNECTION,
                message: "Simulated network error",
                isRetryable: true,
                underlyingError: nil
            )
        }

        let lowercasedQuery = query.lowercased()
        return users.values.filter { user in
            user.firstName.lowercased().contains(lowercasedQuery) ||
            user.lastName.lowercased().contains(lowercasedQuery) ||
            user.email.lowercased().contains(lowercasedQuery)
        }.sorted { $0.createdAt > $1.createdAt }
    }

    func refreshUsers() async throws -> [User] {
        // For mock data source, refresh is same as getUsers
        return try await getUsers()
    }

    // MARK: - Private Methods
    
    private func simulateDelay() async throws {
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        }
    }
    
    private func seedMockData() {
        let mockUsers = User.mockUsers
        for user in mockUsers {
            users[user.id] = user
        }
    }
    
    // MARK: - Testing Helpers
    
    func clearAllData() {
        users.removeAll()
    }
    
    func setUsers(_ newUsers: [User]) {
        users.removeAll()
        for user in newUsers {
            users[user.id] = user
        }
    }
}
