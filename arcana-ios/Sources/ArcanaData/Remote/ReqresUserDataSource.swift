//
//  ReqresUserDataSource.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation

/// Remote data source implementation using reqres.in API
final class ReqresUserDataSource: RemoteUserDataSource {
    
    // MARK: - Properties
    
    private let apiService: ApiService
    private let analyticsTracker: AnalyticsTracker
    
    // MARK: - Initialization
    
    init(
        apiService: ApiService = ApiService(),
        analyticsTracker: AnalyticsTracker
    ) {
        self.apiService = apiService
        self.analyticsTracker = analyticsTracker
    }
    
    // MARK: - RemoteUserDataSource Implementation
    
    func getUsers() async throws -> [User] {
        analyticsTracker.trackEvent(.apiRequestStarted, params: [
            "endpoint": "GET /users",
            "source": "reqres.in"
        ])

        do {
            // Fetch all pages of users
            var allUsers: [User] = []
            var currentPage = 1
            var hasMorePages = true

            while hasMorePages {
                let response = try await apiService.getUsers(page: currentPage)

                // Convert reqres users to app users
                let users = response.data.map { $0.toUser() }
                allUsers.append(contentsOf: users)

                // Check if there are more pages
                hasMorePages = currentPage < response.totalPages
                currentPage += 1
            }

            analyticsTracker.trackEvent(.apiRequestSucceeded, params: [
                "endpoint": "GET /users",
                "user_count": allUsers.count
            ])

            return allUsers

        } catch {
            analyticsTracker.trackError(error, context: [
                "endpoint": "GET /users",
                "operation": "getUsers"
            ])
            throw mapError(error)
        }
    }

    func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User> {
        analyticsTracker.trackEvent(.apiRequestStarted, params: [
            "endpoint": "GET /users",
            "page": page,
            "per_page": perPage,
            "source": "reqres.in"
        ])

        do {
            let response = try await apiService.getUsers(page: page, perPage: perPage)

            // Convert reqres users to app users
            let users = response.data.map { $0.toUser() }

            analyticsTracker.trackEvent(.apiRequestSucceeded, params: [
                "endpoint": "GET /users",
                "page": page,
                "user_count": users.count,
                "total_pages": response.totalPages
            ])

            return PaginatedResult(
                items: users,
                currentPage: page,
                totalPages: response.totalPages,
                hasMore: page < response.totalPages
            )

        } catch {
            analyticsTracker.trackError(error, context: [
                "endpoint": "GET /users",
                "operation": "getUsers",
                "page": page
            ])
            throw mapError(error)
        }
    }
    
    func getUser(id: String) async throws -> User {
        analyticsTracker.trackEvent(.apiRequestStarted, params: [
            "endpoint": "GET /users/\(id)",
            "user_id": id
        ])
        
        do {
            let response = try await apiService.getUser(id: id)
            let user = response.data.toUser()
            
            analyticsTracker.trackEvent(.apiRequestSucceeded, params: [
                "endpoint": "GET /users/\(id)",
                "user_id": id
            ])
            
            return user
            
        } catch {
            analyticsTracker.trackError(error, context: [
                "endpoint": "GET /users/\(id)",
                "operation": "getUser",
                "user_id": id
            ])
            throw mapError(error)
        }
    }
    
    func createUser(_ user: User) async throws -> User {
        analyticsTracker.trackEvent(.apiRequestStarted, params: [
            "endpoint": "POST /users",
            "operation": "create"
        ])
        
        do {
            let response = try await apiService.createUser(
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName
            )
            
            // Create a new user with the returned ID
            let newUser = User(
                id: response.id,
                email: response.email,
                firstName: response.firstName,
                lastName: response.lastName,
                avatar: user.avatar,
                createdAt: parseDate(response.createdAt) ?? Date(),
                updatedAt: Date()
            )
            
            analyticsTracker.trackEvent(.apiRequestSucceeded, params: [
                "endpoint": "POST /users",
                "operation": "create",
                "user_id": response.id
            ])
            
            return newUser
            
        } catch {
            analyticsTracker.trackError(error, context: [
                "endpoint": "POST /users",
                "operation": "createUser"
            ])
            throw mapError(error)
        }
    }
    
    func updateUser(_ user: User) async throws -> User {
        analyticsTracker.trackEvent(.apiRequestStarted, params: [
            "endpoint": "PUT /users/\(user.id)",
            "operation": "update",
            "user_id": user.id
        ])
        
        do {
            let response = try await apiService.updateUser(
                id: user.id,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName
            )
            
            // Create updated user with response data
            let updatedUser = User(
                id: user.id,
                email: response.email ?? user.email,
                firstName: response.firstName ?? user.firstName,
                lastName: response.lastName ?? user.lastName,
                avatar: user.avatar,
                createdAt: user.createdAt,
                updatedAt: parseDate(response.updatedAt) ?? Date()
            )
            
            analyticsTracker.trackEvent(.apiRequestSucceeded, params: [
                "endpoint": "PUT /users/\(user.id)",
                "operation": "update",
                "user_id": user.id
            ])
            
            return updatedUser
            
        } catch {
            analyticsTracker.trackError(error, context: [
                "endpoint": "PUT /users/\(user.id)",
                "operation": "updateUser",
                "user_id": user.id
            ])
            throw mapError(error)
        }
    }
    
    func deleteUser(_ user: User) async throws {
        analyticsTracker.trackEvent(.apiRequestStarted, params: [
            "endpoint": "DELETE /users/\(user.id)",
            "operation": "delete",
            "user_id": user.id
        ])
        
        do {
            try await apiService.deleteUser(id: user.id)
            
            analyticsTracker.trackEvent(.apiRequestSucceeded, params: [
                "endpoint": "DELETE /users/\(user.id)",
                "operation": "delete",
                "user_id": user.id
            ])
            
        } catch {
            analyticsTracker.trackError(error, context: [
                "endpoint": "DELETE /users/\(user.id)",
                "operation": "deleteUser",
                "user_id": user.id
            ])
            throw mapError(error)
        }
    }
    
    func searchUsers(query: String) async throws -> [User] {
        // For reqres.in, we fetch all users and filter locally
        let allUsers = try await getUsers()
        let lowercasedQuery = query.lowercased()
        
        return allUsers.filter { user in
            user.firstName.lowercased().contains(lowercasedQuery) ||
            user.lastName.lowercased().contains(lowercasedQuery) ||
            user.email.lowercased().contains(lowercasedQuery) ||
            user.fullName.lowercased().contains(lowercasedQuery)
        }
    }
    
    func refreshUsers() async throws -> [User] {
        // For this data source, refresh is the same as getUsers
        return try await getUsers()
    }
    
    // MARK: - Helper Methods
    
    private func mapError(_ error: Error) -> AppError {
        if let apiError = error as? ApiError {
            switch apiError {
            case .networkError:
                return .networkError(.E1003_NETWORK_IO, message: "Network connection failed", isRetryable: true, underlyingError: error)
            case .decodingError:
                return .unknownError(.E9004_DESERIALIZATION_ERROR, message: "Failed to parse response", underlyingError: error)
            case .unexpectedStatusCode(let code):
                if code == 404 {
                    return .serverError(.E3002_NOT_FOUND, statusCode: code, message: "User not found")
                } else {
                    return .serverError(.E3000_SERVER_ERROR, statusCode: code, message: "Server error: \(code)")
                }
            case .invalidResponse:
                return .unknownError(.E9004_DESERIALIZATION_ERROR, message: "Invalid response format", underlyingError: error)
            case .userNotFound:
                return .serverError(.E3002_NOT_FOUND, statusCode: 404, message: "User not found")
            }
        }
        
        return .unknownError(.E9000_UNKNOWN, message: "An unexpected error occurred", underlyingError: error)
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}
