//
//  MainViewModel.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation
import Observation
import Dependencies

/// ViewModel for MainView using Observation framework
@MainActor
@Observable
final class MainViewModel {
    
    // MARK: - Input
    enum Input {
        case loadData
        case navigateToUserList
        case navigateToSettings
        case retry
    }

    // MARK: - Effect
    enum Effect {
        case showError(AppError)
    }

    // MARK: - Output
    struct Output {
        var userCount: Int = 0
        var isLoading: Bool = false
        var errorMessage: String?
    }

    // MARK: - Observable State
    private(set) var output = Output()
    
    // MARK: - Dependencies
    @ObservationIgnored
    @Dependency(\.userService) var userService
    
    @ObservationIgnored
    @Dependency(\.analyticsTracker) var analyticsTracker
    
    private let navGraph: NavGraph
    
    // MARK: - Computed Properties

    var hasError: Bool {
        output.errorMessage != nil
    }

    var canNavigate: Bool {
        !output.isLoading
    }
    
    // MARK: - Initialization
    
    init(navGraph: NavGraph) {
        self.navGraph = navGraph
    }
    
    // MARK: - Public Methods

    /// Process an input action and receive optional effect
    /// - Parameter action: The user action to process
    /// - Returns: Optional effect that the view should handle
    func input(_ action: Input) async -> Effect? {
        switch action {
        case .loadData:
            return await loadUserCount()

        case .navigateToUserList:
            navigateToUserList()
            return nil

        case .navigateToSettings:
            navigateToSettings()
            return nil

        case .retry:
            return await loadUserCount()
        }
    }
    
    // MARK: - Private Methods

    private func loadUserCount() async -> Effect? {
        output.isLoading = true
        output.errorMessage = nil

        // Track screen view
        analyticsTracker.trackScreen("main_screen")

        // Simulate loading delay for smooth animation
        try? await Task.sleep(for: .milliseconds(500))

        defer { output.isLoading = false }

        do {
            let users = try await userService.getUsers()
            output.userCount = users.count

            // Track success
            analyticsTracker.trackEvent(
                .pageLoaded,
                params: ["user_count": output.userCount]
            )

            return nil

        } catch let error as AppError {
            output.errorMessage = error.message
            analyticsTracker.trackAppError(error, context: ["action": "load_user_count"])
            return .showError(error)

        } catch {
            let appError = AppError.unknownError(
                .E9000_UNKNOWN,
                message: "Failed to load user count",
                underlyingError: error
            )
            output.errorMessage = appError.message
            analyticsTracker.trackError(error, context: ["action": "load_user_count"])
            return .showError(appError)
        }
    }
    
    private func navigateToUserList() {
        guard canNavigate else { return }

        analyticsTracker.trackEvent(
            .screenUserListViewed,
            params: ["source": "main_screen"]
        )

        navGraph.navigateToUserList()
    }

    private func navigateToSettings() {
        guard canNavigate else { return }

        analyticsTracker.trackScreen("settings_screen", params: ["source": "main_screen"])

        navGraph.navigateToSettings()
    }
}
