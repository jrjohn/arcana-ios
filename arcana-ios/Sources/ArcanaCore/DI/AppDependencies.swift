//
//  AppDependencies.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation
import SwiftUI
import SwiftData
import Dependencies

// MARK: - Dependency Keys

extension DependencyValues {
    var userService: UserService {
        get { self[UserServiceKey.self] }
        set { self[UserServiceKey.self] = newValue }
    }

    var analyticsTracker: AnalyticsTracker {
        get { self[AnalyticsTrackerKey.self] }
        set { self[AnalyticsTrackerKey.self] = newValue }
    }

    var userRepository: UserRepository {
        get { self[UserRepositoryKey.self] }
        set { self[UserRepositoryKey.self] = newValue }
    }
}

// Storage for live dependency instances
private struct DependencyStorage {
    static var userService: UserService?
    static var analyticsTracker: AnalyticsTracker?
    static var userRepository: UserRepository?
}

private enum UserServiceKey: DependencyKey {
    static var liveValue: UserService {
        guard let instance = DependencyStorage.userService else {
            fatalError("UserService not configured. Call AppDependencies.setup() in your App init.")
        }
        return instance
    }
}

private enum AnalyticsTrackerKey: DependencyKey {
    static var liveValue: AnalyticsTracker {
        guard let instance = DependencyStorage.analyticsTracker else {
            fatalError("AnalyticsTracker not configured. Call AppDependencies.setup() in your App init.")
        }
        return instance
    }
}

private enum UserRepositoryKey: DependencyKey {
    static var liveValue: UserRepository {
        guard let instance = DependencyStorage.userRepository else {
            fatalError("UserRepository not configured. Call AppDependencies.setup() in your App init.")
        }
        return instance
    }
}

/// Configure live dependencies for the app
@MainActor
struct AppDependencies {
    
    /// Setup all live dependencies
    /// Call this in your App's init()
    static func setup(modelContainer: ModelContainer, useRealAPI: Bool = true) {
        // Create analytics tracker with real ModelContainer
        let analyticsTracker = PersistentAnalyticsTracker(
            modelContainer: modelContainer
        )
        
        // Create local data source
        let localDataSource = UserLocalDaoImpl(
            modelContainer: modelContainer,
            analyticsTracker: analyticsTracker
        )
        
        // Create remote data source
        let remoteDataSource: UserRemoteDao
        if useRealAPI {
            // Use real reqres.in API
            remoteDataSource = UserRemoteDaoImpl(
                apiService: ApiService(),
                analyticsTracker: analyticsTracker
            )
        } else {
            // Use mock for testing/development
            remoteDataSource = UserRemoteDaoMockImpl(
                simulateNetworkDelay: true,
                networkDelay: 0.5,
                shouldFailRequests: false
            )
        }
        
        // Get model context
        let modelContext = modelContainer.mainContext

        // Create repository
        let repository = OfflineFirstUserRepository(
            localDataSource: localDataSource,
            remoteDataSource: remoteDataSource,
            analyticsTracker: analyticsTracker,
            modelContext: modelContext
        )
        
        // Create service
        let userService = UserServiceImpl(
            repository: repository,
            analyticsTracker: analyticsTracker
        )

        // Register all live dependencies
        registerLiveDependencies(
            userService: userService,
            analyticsTracker: analyticsTracker,
            repository: repository
        )

        // Track app launch
        analyticsTracker.trackEvent(.appLaunched)
    }

    private static func registerLiveDependencies(
        userService: UserService,
        analyticsTracker: AnalyticsTracker,
        repository: UserRepository
    ) {
        // Store the live instances for dependency access
        DependencyStorage.userService = userService
        DependencyStorage.analyticsTracker = analyticsTracker
        DependencyStorage.userRepository = repository
    }
}

// MARK: - App Entry Point Extension

extension AppDependencies {
    
    /// Use this in your @main App struct
    /// 
    /// Example:
    /// ```
    /// @main
    /// struct ArcanaApp: App {
    ///     let modelContainer: ModelContainer
    ///     
    ///     init() {
    ///         modelContainer = createModelContainer()
    ///         AppDependencies.setup(modelContainer: modelContainer)
    ///     }
    /// }
    /// ```
    static func createModelContainer() -> ModelContainer {
        let schema = Schema([
            UserEntity.self,
            AnalyticsEventEntity.self,
            PendingChangeEntity.self
        ])

        // Try persistent storage first
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            print("⚠️ Failed to create persistent ModelContainer: \(error)")

            // Delete old store and try again with a fresh database
            let url = modelConfiguration.url
            print("⚠️ Attempting to delete old database at: \(url.path)")
            try? FileManager.default.removeItem(at: url)

            // Try again with fresh database
            do {
                return try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
            } catch {
                print("⚠️ Still failed after deleting old database: \(error)")
            }

            print("⚠️ Falling back to in-memory storage...")

            // Fallback to in-memory storage
            let inMemoryConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )

            do {
                return try ModelContainer(
                    for: schema,
                    configurations: [inMemoryConfiguration]
                )
            } catch {
                fatalError("Could not create ModelContainer even with in-memory storage: \(error)")
            }
        }
    }
}

// MARK: - Dependency Override Helpers

extension AppDependencies {
    
    /// Override dependencies for testing
    /// 
    /// Example:
    /// ```
    /// func testSomething() {
    ///     let mockService = MockUserService()
    ///     
    ///     AppDependencies.withTestDependencies(
    ///         userService: mockService
    ///     ) {
    ///         // Run test
    ///         let viewModel = UserListViewModel()
    ///         // viewModel uses mockService
    ///     }
    /// }
    /// ```
    static func withTestDependencies<T>(
        userService: UserService? = nil,
        analyticsTracker: AnalyticsTracker? = nil,
        repository: UserRepository? = nil,
        operation: () throws -> T
    ) rethrows -> T {
        try withDependencies {
            if let userService = userService {
                $0.userService = userService
            }
            if let analyticsTracker = analyticsTracker {
                $0.analyticsTracker = analyticsTracker
            }
            if let repository = repository {
                $0.userRepository = repository
            }
        } operation: {
            try operation()
        }
    }

    /// Override dependencies for SwiftUI previews
    ///
    /// Example:
    /// ```
    /// #Preview {
    ///     AppDependencies.withPreviewDependencies(
    ///         mockUsers: User.mockUsers
    ///     ) {
    ///         UserListView()
    ///     }
    /// }
    /// ```
    static func withPreviewDependencies<T>(
        mockUsers: [User]? = nil,
        @ViewBuilder operation: () -> T
    ) -> T {
        withDependencies {
            let mockService = MockUserService()
            let now = Date()
            mockService.getUsersResult = .success(mockUsers ?? [
                User(id: "1", email: "alice.smith@reqres.in", firstName: "Alice", lastName: "Smith", avatar: "https://reqres.in/img/faces/1-image.jpg", createdAt: now, updatedAt: now),
                User(id: "2", email: "bob.johnson@reqres.in", firstName: "Bob", lastName: "Johnson", avatar: "https://reqres.in/img/faces/2-image.jpg", createdAt: now, updatedAt: now),
                User(id: "3", email: "carol.williams@reqres.in", firstName: "Carol", lastName: "Williams", avatar: "https://reqres.in/img/faces/3-image.jpg", createdAt: now, updatedAt: now),
                User(id: "4", email: "david.brown@reqres.in", firstName: "David", lastName: "Brown", avatar: "https://reqres.in/img/faces/4-image.jpg", createdAt: now, updatedAt: now),
                User(id: "5", email: "eve.davis@reqres.in", firstName: "Eve", lastName: "Davis", avatar: "https://reqres.in/img/faces/5-image.jpg", createdAt: now, updatedAt: now)
            ])
            $0.userService = mockService
            $0.analyticsTracker = MockAnalyticsTracker()
        } operation: {
            operation()
        }
    }
}

// MARK: - Mock Implementations for Testing & Previews

private final class MockUserService: UserService {
    var getUsersResult: Result<[User], Error> = .success([])

    func getUsers() async throws -> [User] {
        try getUsersResult.get()
    }

    func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User> {
        let allUsers = try getUsersResult.get()
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
        let users = try getUsersResult.get()
        guard let user = users.first(where: { $0.id == id }) else {
            throw AppError.unknownError(.E3002_NOT_FOUND, message: "User not found", underlyingError: nil)
        }
        return user
    }

    func createUser(_ user: User) async throws -> User {
        user
    }

    func updateUser(_ user: User) async throws -> User {
        user
    }

    func deleteUser(_ user: User) async throws {
        // No-op for mock
    }

    func searchUsers(query: String) async throws -> [User] {
        try getUsersResult.get().filter { user in
            user.fullName.localizedCaseInsensitiveContains(query) ||
            user.email.localizedCaseInsensitiveContains(query)
        }
    }

    func refreshUsers() async throws -> [User] {
        try getUsersResult.get()
    }
}

private final class MockAnalyticsTracker: AnalyticsTracker {
    var sessionId: String = UUID().uuidString
    var trackedEvents: [AnalyticsEvent] = []

    func trackEvent(_ event: AnalyticsEvent, params: [String: Any] = [:]) {
        trackedEvents.append(event)
    }

    func trackScreen(_ screen: String, params: [String: Any] = [:]) {
        // No-op for mock
    }

    func trackError(_ error: Error, context: [String: Any] = [:]) {
        // No-op for mock
    }

    func trackAppError(_ appError: AppError, context: [String: Any] = [:]) {
        // No-op for mock
    }
}

private final class MockUserRepository: UserRepository {
    var getUsersResult: Result<[User], Error> = .success([])

    func getUsers() async throws -> [User] {
        try getUsersResult.get()
    }

    func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User> {
        let allUsers = try getUsersResult.get()
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
        let users = try getUsersResult.get()
        guard let user = users.first(where: { $0.id == id }) else {
            throw AppError.unknownError(.E3002_NOT_FOUND, message: "User not found", underlyingError: nil)
        }
        return user
    }

    func createUser(_ user: User) async throws -> User {
        user
    }

    func updateUser(_ user: User) async throws -> User {
        user
    }

    func deleteUser(_ user: User) async throws {
        // No-op for mock
    }

    func searchUsers(query: String) async throws -> [User] {
        try getUsersResult.get().filter { user in
            user.fullName.localizedCaseInsensitiveContains(query) ||
            user.email.localizedCaseInsensitiveContains(query)
        }
    }

    func refreshUsers() async throws -> [User] {
        try getUsersResult.get()
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension AppDependencies {

    /// Enable mock API for debugging
    static func setupWithMockAPI(modelContainer: ModelContainer) {
        let analyticsTracker = PersistentAnalyticsTracker(
            modelContainer: modelContainer
        )

        let mockService = MockUserService()
        mockService.getUsersResult = .success(User.mockUsers)
        
        let mockRepository = MockUserRepository()

        // Register mock dependencies
        DependencyStorage.userService = mockService
        DependencyStorage.analyticsTracker = analyticsTracker
        DependencyStorage.userRepository = mockRepository
    }

    /// Print current dependency configuration
    static func printDependencyInfo() {
        print("📦 Dependency Configuration:")
        print("  UserService: \(type(of: DependencyValues._current.userService))")
        print("  AnalyticsTracker: \(type(of: DependencyValues._current.analyticsTracker))")
        print("  UserRepository: \(type(of: DependencyValues._current.userRepository))")
    }
}
#endif
