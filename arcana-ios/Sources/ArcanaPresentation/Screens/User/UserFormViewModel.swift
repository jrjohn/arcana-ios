//
//  UserFormViewModel.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation
import Combine
import Dependencies

/// ViewModel for User Form (Create/Edit) with Input/Output pattern
@MainActor
final class UserFormViewModel: ObservableObject {
    
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
        var firstName: String = ""
        var lastName: String = ""
        var email: String = ""
        var avatar: String = ""
        var firstNameError: String?
        var lastNameError: String?
        var emailError: String?
        var isLoading: Bool = false
        var isSaveEnabled: Bool = false
    }
    
    // MARK: - Effect
    enum Effect {
        case showError(AppError)
        case dismiss(User?)
    }
    
    // MARK: - Published State
    @Published private(set) var state = Output()
    
    // MARK: - Effects
    let effects = PassthroughSubject<Effect, Never>()

    // MARK: - Dependencies
    private let mode: Mode
    @Dependency(\.userService) var userService
    @Dependency(\.analyticsTracker) var analyticsTracker
    private let validator: UserValidator.Type
    private var cancellables = Set<AnyCancellable>()
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
        setupBindings()
    }
    
    // MARK: - Public Properties
    var formTitle: String {
        mode.title
    }
    
    var submitButtonTitle: String {
        mode.submitButtonTitle
    }
    
    // MARK: - Public Methods
    func send(_ input: Input) {
        Task {
            switch input {
            case .updateFirstName(let value):
                state.firstName = value
                validateFirstName()

            case .updateLastName(let value):
                state.lastName = value
                validateLastName()

            case .updateEmail(let value):
                state.email = value
                validateEmail()

            case .updateAvatar(let value):
                state.avatar = value

            case .submit:
                await submit()

            case .validateAll:
                validateAll()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialState() {
        if case .edit(let user) = mode {
            state.firstName = user.firstName
            state.lastName = user.lastName
            state.email = user.email
            state.avatar = user.avatar
        }

        analyticsTracker.trackScreen("User Form", params: [
            "mode": mode.title
        ])
    }
    
    private func setupBindings() {
        // Update save button state whenever fields change
        $state
            .debounce(for: .seconds(AppConstants.UI.debounceDelay), scheduler: DispatchQueue.main)
            .map { state in
                !state.firstName.isEmpty &&
                !state.lastName.isEmpty &&
                !state.email.isEmpty &&
                state.firstNameError == nil &&
                state.lastNameError == nil &&
                state.emailError == nil
            }
            .sink { [weak self] isEnabled in
                self?.state.isSaveEnabled = isEnabled
            }
            .store(in: &cancellables)
    }
    
    private func validateFirstName() {
        let result = validator.validateNameField(state.firstName, field: "firstName")
        state.firstNameError = result.isValid ? nil : result.errorMessage
    }
    
    private func validateLastName() {
        let result = validator.validateNameField(state.lastName, field: "lastName")
        state.lastNameError = result.isValid ? nil : result.errorMessage
    }
    
    private func validateEmail() {
        let result = validator.validateEmailField(state.email)
        state.emailError = result.isValid ? nil : result.errorMessage
    }
    
    private func validateAll() {
        validateFirstName()
        validateLastName()
        validateEmail()
    }
    
    private func submit() async {
        validateAll()
        
        guard state.isSaveEnabled else { return }
        
        state.isLoading = true
        defer { state.isLoading = false }
        
        do {
            let user: User
            
            switch mode {
            case .create:
                user = User(
                    email: state.email,
                    firstName: state.firstName,
                    lastName: state.lastName,
                    avatar: state.avatar
                )

                let createdUser = try await userService.createUser(user)

                analyticsTracker.trackEvent(.userCreateSuccess, params: [
                    "userId": createdUser.id,
                    "email": createdUser.email
                ])

                effects.send(.dismiss(createdUser))

            case .edit(let existingUser):
                user = User(
                    id: existingUser.id,
                    email: state.email,
                    firstName: state.firstName,
                    lastName: state.lastName,
                    avatar: state.avatar,
                    createdAt: existingUser.createdAt,
                    updatedAt: Date()
                )
                
                let updatedUser = try await userService.updateUser(user)
                
                analyticsTracker.trackEvent(.userUpdateSuccess, params: [
                    "userId": updatedUser.id,
                    "email": updatedUser.email
                ])
                
                effects.send(.dismiss(updatedUser))
            }
        } catch {
            let appError = AppError.from(error)
            effects.send(.showError(appError))
            analyticsTracker.trackAppError(appError, context: [
                "screen": "user_form",
                "mode": mode.title
            ])
        }
    }
}
