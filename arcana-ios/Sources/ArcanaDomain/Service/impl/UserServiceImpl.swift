//
//  UserServiceImpl.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation

/// Implementation of UserService with validation and error handling
final class UserServiceImpl: UserService {

    private let repository: UserRepository
    private let validator: UserValidator.Type
    private let analyticsTracker: AnalyticsTracker

    init(
        repository: UserRepository,
        validator: UserValidator.Type = UserValidator.self,
        analyticsTracker: AnalyticsTracker
    ) {
        self.repository = repository
        self.validator = validator
        self.analyticsTracker = analyticsTracker
    }

    // MARK: - UserService Implementation

    func getUsers() async throws -> [User] {
        analyticsTracker.trackEvent(.networkRequestStarted, params: ["operation": "getUsers"])

        do {
            let users = try await repository.getUsers()
            analyticsTracker.trackEvent(.networkRequestSuccess, params: [
                "operation": "getUsers",
                "count": users.count
            ])
            return users
        } catch {
            let appError = AppError.from(error)
            analyticsTracker.trackAppError(appError, context: ["operation": "getUsers"])
            throw appError
        }
    }

    func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User> {
        analyticsTracker.trackEvent(.networkRequestStarted, params: [
            "operation": "getUsers",
            "page": page,
            "per_page": perPage
        ])

        do {
            let result = try await repository.getUsers(page: page, perPage: perPage)
            analyticsTracker.trackEvent(.networkRequestSuccess, params: [
                "operation": "getUsers",
                "page": page,
                "count": result.items.count,
                "total_pages": result.totalPages
            ])
            return result
        } catch {
            let appError = AppError.from(error)
            analyticsTracker.trackAppError(appError, context: [
                "operation": "getUsers",
                "page": page
            ])
            throw appError
        }
    }

    func getUser(id: String) async throws -> User {
        analyticsTracker.trackEvent(.networkRequestStarted, params: [
            "operation": "getUser",
            "userId": id
        ])

        do {
            let user = try await repository.getUser(id: id)
            analyticsTracker.trackEvent(.networkRequestSuccess, params: [
                "operation": "getUser",
                "userId": id
            ])
            return user
        } catch {
            let appError = AppError.from(error)
            analyticsTracker.trackAppError(appError, context: [
                "operation": "getUser",
                "userId": id
            ])
            throw appError
        }
    }

    func createUser(_ user: User) async throws -> User {
        // Validate user
        if case .failure(let validationError) = validator.validateForCreate(user) {
            let appError = validationError.appError
            analyticsTracker.trackAppError(appError, context: [
                "operation": "createUser",
                "validation": "failed"
            ])
            throw appError
        }

        analyticsTracker.trackEvent(.userCreateClicked, params: [
            "email": user.email
        ])

        do {
            // Create new user with updated timestamp
            let newUser = User(
                id: user.id,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                avatar: user.avatar,
                createdAt: Date(),
                updatedAt: Date()
            )

            let createdUser = try await repository.createUser(newUser)

            analyticsTracker.trackEvent(.userCreateSuccess, params: [
                "userId": createdUser.id,
                "email": createdUser.email
            ])

            return createdUser
        } catch {
            let appError = AppError.from(error)
            analyticsTracker.trackEvent(.userCreateFailed, params: [
                "error_code": appError.errorCode.code,
                "email": user.email
            ])
            analyticsTracker.trackAppError(appError, context: ["operation": "createUser"])
            throw appError
        }
    }

    func updateUser(_ user: User) async throws -> User {
        // Validate user
        if case .failure(let validationError) = validator.validateForUpdate(user) {
            let appError = validationError.appError
            analyticsTracker.trackAppError(appError, context: [
                "operation": "updateUser",
                "userId": user.id
            ])
            throw appError
        }

        analyticsTracker.trackEvent(.userUpdateClicked, params: [
            "userId": user.id,
            "email": user.email
        ])

        do {
            // Create updated user with new timestamp
            let updatedUser = User(
                id: user.id,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                avatar: user.avatar,
                createdAt: user.createdAt,  // Keep original
                updatedAt: Date()            // Update timestamp
            )

            let result = try await repository.updateUser(updatedUser)

            analyticsTracker.trackEvent(.userUpdateSuccess, params: [
                "userId": result.id,
                "email": result.email
            ])

            return result
        } catch {
            let appError = AppError.from(error)
            analyticsTracker.trackEvent(.userUpdateFailed, params: [
                "error_code": appError.errorCode.code,
                "userId": user.id
            ])
            analyticsTracker.trackAppError(appError, context: [
                "operation": "updateUser",
                "userId": user.id
            ])
            throw appError
        }
    }

    func deleteUser(_ user: User) async throws {
        analyticsTracker.trackEvent(.userDeleteClicked, params: [
            "userId": user.id,
            "email": user.email
        ])

        do {
            try await repository.deleteUser(user)

            analyticsTracker.trackEvent(.userDeleteSuccess, params: [
                "userId": user.id
            ])
        } catch {
            let appError = AppError.from(error)
            analyticsTracker.trackEvent(.userDeleteFailed, params: [
                "error_code": appError.errorCode.code,
                "userId": user.id
            ])
            analyticsTracker.trackAppError(appError, context: [
                "operation": "deleteUser",
                "userId": user.id
            ])
            throw appError
        }
    }

    func searchUsers(query: String) async throws -> [User] {
        analyticsTracker.trackEvent(.listSearched, params: ["query": query])

        do {
            let users = try await repository.searchUsers(query: query)
            return users
        } catch {
            let appError = AppError.from(error)
            analyticsTracker.trackAppError(appError, context: [
                "operation": "searchUsers",
                "query": query
            ])
            throw appError
        }
    }

    func refreshUsers() async throws -> [User] {
        analyticsTracker.trackEvent(.listRefreshed)

        do {
            let users = try await repository.refreshUsers()
            analyticsTracker.trackEvent(.syncCompleted, params: ["count": users.count])
            return users
        } catch {
            let appError = AppError.from(error)
            analyticsTracker.trackEvent(.syncFailed, params: [
                "error_code": appError.errorCode.code
            ])
            analyticsTracker.trackAppError(appError, context: ["operation": "refreshUsers"])
            throw appError
        }
    }
}
