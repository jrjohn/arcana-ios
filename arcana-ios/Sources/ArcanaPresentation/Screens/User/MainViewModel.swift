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
    
    // MARK: - State
    private(set) var userCount: Int = 0
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    
    // MARK: - Dependencies
    @ObservationIgnored
    @Dependency(\.userService) var userService
    
    @ObservationIgnored
    @Dependency(\.analyticsTracker) var analyticsTracker
    
    private let navGraph: NavGraph
    
    // MARK: - Computed Properties
    
    var hasError: Bool {
        errorMessage != nil
    }
    
    var canNavigate: Bool {
        !isLoading
    }
    
    // MARK: - Initialization
    
    init(navGraph: NavGraph) {
        self.navGraph = navGraph
    }
    
    // MARK: - Input Handling
    
    func send(_ input: Input) {
        Task {
            await handle(input)
        }
    }
    
    private func handle(_ input: Input) async {
        switch input {
        case .loadData:
            await loadUserCount()
            
        case .navigateToUserList:
            navigateToUserList()
            
        case .navigateToSettings:
            navigateToSettings()
            
        case .retry:
            await loadUserCount()
        }
    }
    
    // MARK: - Business Logic
    
    private func loadUserCount() async {
        isLoading = true
        errorMessage = nil
        
        // Track screen view
        analyticsTracker.trackScreen("main_screen")
        
        // Simulate loading delay for smooth animation
        try? await Task.sleep(for: .milliseconds(500))
        
        do {
            let users = try await userService.getUsers()
            userCount = users.count
            
            // Track success
            analyticsTracker.trackEvent(
                .pageLoaded,
                params: ["user_count": userCount]
            )

        } catch let error as AppError {
            errorMessage = error.message
            analyticsTracker.trackAppError(error, context: ["action": "load_user_count"])

        } catch {
            let appError = AppError.unknownError(
                .E9000_UNKNOWN,
                message: "Failed to load user count",
                underlyingError: error
            )
            errorMessage = appError.message
            analyticsTracker.trackError(error, context: ["action": "load_user_count"])
        }
        
        isLoading = false
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
