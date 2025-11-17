//
//  UserFormViewModel.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation
import Observation
import Dependencies

/// ViewModel for User Form (Create/Edit) with Input/Output/Effect pattern
@MainActor
@Observable
final class UserFormViewModel {
    
    // MARK: - Mode
    enum Mode {
        case create
        case edit(User)
        
        var title: String {
            switch self {
            case .create: return "Create User"
            case .edit: return "Edit User"
            }
        }
        
        var submitButtonTitle: String {
            switch self {
            case .create: return "Create"
            case .edit: return "Save"
            }
        }
    }
    
    // MARK: - Input
    enum Input {
        case updateFirstName(String)
        case updateLastName(String)
        case updateEmail(String)
        case updateAvatar(String)
        case submit
        case validateAll
    }

    // MARK: - Output
    struct Output {
        // User data - modularized as a single object
        var user: User

        // Validation errors - separate from user data
        var validationErrors: ValidationErrors

        // UI state - separate from user data
        var isLoading: Bool = false
        var isSaveEnabled: Bool = false

        init(user: User = User(email: "", firstName: "", lastName: "", avatar: "")) {
            self.user = user
            self.validationErrors = ValidationErrors()
        }
    }

    // MARK: - Validation Errors
    struct ValidationErrors {
        var firstNameError: String?
        var lastNameError: String?
        var emailError: String?

        var hasErrors: Bool {
            firstNameError != nil || lastNameError != nil || emailError != nil
        }
    }

    // MARK: - Effect
    enum Effect {
        case showError(AppError)
        case dismiss(User?)
    }

    // MARK: - Observable State
    private(set) var output = Output()

    // MARK: - Dependencies
    @ObservationIgnored
    private let mode: Mode

    @ObservationIgnored
    @Dependency(\.userService) var userService

    @ObservationIgnored
    @Dependency(\.analyticsTracker) var analyticsTracker

    @ObservationIgnored
    private let validator: UserValidator.Type

    @ObservationIgnored
    private var navGraph: NavGraph?

    // MARK: - Initialization
    init(
        mode: Mode,
        validator: UserValidator.Type = UserValidator.self,
        navGraph: NavGraph? = nil
    ) {
        self.mode = mode
        self.validator = validator
        self.navGraph = navGraph

        setupInitialState()
    }
    
    // MARK: - Public Properties
    var formTitle: String {
        mode.title
    }
    
    var submitButtonTitle: String {
        mode.submitButtonTitle
    }
    
    // MARK: - Public Methods

    /// Process an input action and receive optional effect
    /// - Parameter action: The user action to process
    /// - Returns: Optional effect that the view should handle
    func input(_ action: Input) async -> Effect? {
        switch action {
        case .updateFirstName(let value):
            output.user = User(
                id: output.user.id,
                email: output.user.email,
                firstName: value,
                lastName: output.user.lastName,
                avatar: output.user.avatar,
                createdAt: output.user.createdAt,
                updatedAt: output.user.updatedAt
            )
            validateFirstName()
            updateSaveButtonState()
            return nil

        case .updateLastName(let value):
            output.user = User(
                id: output.user.id,
                email: output.user.email,
                firstName: output.user.firstName,
                lastName: value,
                avatar: output.user.avatar,
                createdAt: output.user.createdAt,
                updatedAt: output.user.updatedAt
            )
            validateLastName()
            updateSaveButtonState()
            return nil

        case .updateEmail(let value):
            output.user = User(
                id: output.user.id,
                email: value,
                firstName: output.user.firstName,
                lastName: output.user.lastName,
                avatar: output.user.avatar,
                createdAt: output.user.createdAt,
                updatedAt: output.user.updatedAt
            )
            validateEmail()
            updateSaveButtonState()
            return nil

        case .updateAvatar(let value):
            output.user = User(
                id: output.user.id,
                email: output.user.email,
                firstName: output.user.firstName,
                lastName: output.user.lastName,
                avatar: value,
                createdAt: output.user.createdAt,
                updatedAt: output.user.updatedAt
            )
            return nil

        case .submit:
            return await submit()

        case .validateAll:
            validateAll()
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialState() {
        if case .edit(let user) = mode {
            output.user = user
        }

        analyticsTracker.trackScreen("User Form", params: [
            "mode": mode.title
        ])

        updateSaveButtonState()
    }

    private func updateSaveButtonState() {
        output.isSaveEnabled = !output.user.firstName.isEmpty &&
                               !output.user.lastName.isEmpty &&
                               !output.user.email.isEmpty &&
                               !output.validationErrors.hasErrors
    }

    private func validateFirstName() {
        let result = validator.validateNameField(output.user.firstName, field: "firstName")
        output.validationErrors.firstNameError = result.isValid ? nil : result.errorMessage
    }

    private func validateLastName() {
        let result = validator.validateNameField(output.user.lastName, field: "lastName")
        output.validationErrors.lastNameError = result.isValid ? nil : result.errorMessage
    }

    private func validateEmail() {
        let result = validator.validateEmailField(output.user.email)
        output.validationErrors.emailError = result.isValid ? nil : result.errorMessage
    }

    private func validateAll() {
        validateFirstName()
        validateLastName()
        validateEmail()
        updateSaveButtonState()
    }
    
    private func submit() async -> Effect? {
        validateAll()

        guard output.isSaveEnabled else { return nil }

        output.isLoading = true
        defer { output.isLoading = false }

        do {
            let userToSubmit: User

            switch mode {
            case .create:
                // Use the user object directly from output
                userToSubmit = output.user

                let createdUser = try await userService.createUser(userToSubmit)

                analyticsTracker.trackEvent(.userCreateSuccess, params: [
                    "userId": createdUser.id,
                    "email": createdUser.email
                ])

                return .dismiss(createdUser)

            case .edit(let existingUser):
                // Merge output.user with existing user's metadata
                userToSubmit = User(
                    id: existingUser.id,
                    email: output.user.email,
                    firstName: output.user.firstName,
                    lastName: output.user.lastName,
                    avatar: output.user.avatar,
                    createdAt: existingUser.createdAt,
                    updatedAt: Date()
                )

                let updatedUser = try await userService.updateUser(userToSubmit)

                analyticsTracker.trackEvent(.userUpdateSuccess, params: [
                    "userId": updatedUser.id,
                    "email": updatedUser.email
                ])

                return .dismiss(updatedUser)
            }
        } catch {
            let appError = AppError.from(error)
            analyticsTracker.trackAppError(appError, context: [
                "screen": "user_form",
                "mode": mode.title
            ])
            return .showError(appError)
        }
    }
}
