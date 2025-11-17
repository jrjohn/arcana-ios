//
//  UserFormViewModelTests.swift
//  arcana-iosTests
//
//  Created by John on 2025/11/15
//

import Testing
import Foundation
import Combine
import Dependencies
@testable import arcana_ios

/// Comprehensive tests for UserFormViewModel
@MainActor
struct UserFormViewModelTests {

    // MARK: - Initialization Tests

    @Test("UserFormViewModel initializes in create mode with empty fields")
    func testInitializationCreateMode() {
        let viewModel = UserFormViewModel(mode: .create)

        #expect(viewModel.state.firstName == "")
        #expect(viewModel.state.lastName == "")
        #expect(viewModel.state.email == "")
        #expect(viewModel.state.avatar == "")
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.isSaveEnabled == false)
        #expect(viewModel.formTitle == "Create User")
        #expect(viewModel.submitButtonTitle == "Create")
    }

    @Test("UserFormViewModel initializes in edit mode with user data")
    func testInitializationEditMode() {
        let user = User(
            id: "123",
            email: "test@example.com",
            firstName: "John",
            lastName: "Doe",
            avatar: "https://example.com/avatar.jpg"
        )

        let viewModel = UserFormViewModel(mode: .edit(user))

        #expect(viewModel.state.firstName == "John")
        #expect(viewModel.state.lastName == "Doe")
        #expect(viewModel.state.email == "test@example.com")
        #expect(viewModel.state.avatar == "https://example.com/avatar.jpg")
        #expect(viewModel.formTitle == "Edit User")
        #expect(viewModel.submitButtonTitle == "Save")
    }

    // MARK: - Field Update Tests

    @Test("updateFirstName updates state")
    func testUpdateFirstName() async {
        let viewModel = UserFormViewModel(mode: .create)

        // Use continuation to wait for state change
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = viewModel.$state
                .dropFirst() // Skip initial value
                .sink { state in
                    if state.firstName == "John" {
                        cancellable?.cancel()
                        continuation.resume()
                    }
                }

            viewModel.send(.updateFirstName("John"))
        }

        #expect(viewModel.state.firstName == "John")
    }

    @Test("updateFirstName validates immediately")
    func testUpdateFirstNameValidation() async {
        let viewModel = UserFormViewModel(mode: .create)

        viewModel.send(.updateFirstName(""))

        // Give time for validation debounce
        try? await Task.sleep(for: .milliseconds(400))

        #expect(viewModel.state.firstName == "")
        #expect(viewModel.state.firstNameError != nil)
    }

    @Test("updateLastName updates state")
    func testUpdateLastName() async {
        let viewModel = UserFormViewModel(mode: .create)

        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = viewModel.$state
                .dropFirst()
                .sink { state in
                    if state.lastName == "Doe" {
                        cancellable?.cancel()
                        continuation.resume()
                    }
                }

            viewModel.send(.updateLastName("Doe"))
        }

        #expect(viewModel.state.lastName == "Doe")
    }

    @Test("updateEmail updates state")
    func testUpdateEmail() async {
        let viewModel = UserFormViewModel(mode: .create)

        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = viewModel.$state
                .dropFirst()
                .sink { state in
                    if state.email == "test@example.com" {
                        cancellable?.cancel()
                        continuation.resume()
                    }
                }

            viewModel.send(.updateEmail("test@example.com"))
        }

        #expect(viewModel.state.email == "test@example.com")
    }

    @Test("updateEmail validates format")
    func testUpdateEmailValidation() async {
        let viewModel = UserFormViewModel(mode: .create)

        viewModel.send(.updateEmail("invalid-email"))

        // Give time for validation debounce
        try? await Task.sleep(for: .milliseconds(400))

        #expect(viewModel.state.email == "invalid-email")
        #expect(viewModel.state.emailError != nil)
    }

    @Test("updateAvatar updates state")
    func testUpdateAvatar() async {
        let viewModel = UserFormViewModel(mode: .create)

        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = viewModel.$state
                .dropFirst()
                .sink { state in
                    if state.avatar == "https://example.com/avatar.jpg" {
                        cancellable?.cancel()
                        continuation.resume()
                    }
                }

            viewModel.send(.updateAvatar("https://example.com/avatar.jpg"))
        }

        #expect(viewModel.state.avatar == "https://example.com/avatar.jpg")
    }

    // MARK: - Validation Tests

    @Test("validateAll validates all fields")
    func testValidateAll() async {
        let viewModel = UserFormViewModel(mode: .create)

        viewModel.send(.validateAll)

        // Give time for validation
        try? await Task.sleep(for: .milliseconds(200))

        // All fields empty, so should have errors
        #expect(viewModel.state.firstNameError != nil)
        #expect(viewModel.state.lastNameError != nil)
        #expect(viewModel.state.emailError != nil)
    }

    @Test("isSaveEnabled is true when all fields valid")
    func testIsSaveEnabled() async {
        let viewModel = UserFormViewModel(mode: .create)

        // Set valid values
        viewModel.send(.updateFirstName("John"))
        viewModel.send(.updateLastName("Doe"))
        viewModel.send(.updateEmail("john.doe@example.com"))

        // Wait for debounce and validation (300ms debounce + buffer)
        try? await Task.sleep(for: .milliseconds(500))

        #expect(viewModel.state.isSaveEnabled == true)
    }

    @Test("isSaveEnabled is false when fields invalid")
    func testIsSaveEnabledInvalid() async {
        let viewModel = UserFormViewModel(mode: .create)

        // Set invalid email
        viewModel.send(.updateFirstName("John"))
        viewModel.send(.updateLastName("Doe"))
        viewModel.send(.updateEmail("invalid"))

        // Wait for debounce and validation
        try? await Task.sleep(for: .milliseconds(500))

        #expect(viewModel.state.isSaveEnabled == false)
    }

    // MARK: - Submit Tests

    @Test("submit creates user in create mode")
    func testSubmitCreate() async {
        let mockService = MockUserService()
        let mockTracker = MockAnalyticsTracker()

        let viewModel = await withDependencies {
            $0.userService = mockService
            $0.analyticsTracker = mockTracker
        } operation: {
            UserFormViewModel(mode: .create)
        }

        var effectReceived: UserFormViewModel.Effect?

        // Subscribe to effects
        let cancellable = viewModel.effects.sink { effect in
            effectReceived = effect
        }

        // Set valid data
        viewModel.send(.updateFirstName("John"))
        viewModel.send(.updateLastName("Doe"))
        viewModel.send(.updateEmail("john.doe@example.com"))

        // Wait for validation
        try? await Task.sleep(for: .milliseconds(500))

        // Submit
        viewModel.send(.submit)

        // Wait for submission
        try? await Task.sleep(for: .milliseconds(300))

        #expect(viewModel.state.isLoading == false)
        #expect(mockTracker.trackedEvents.count > 0)

        // Check effect
        if let effect = effectReceived {
            if case .dismiss(let user) = effect {
                #expect(user != nil)
            } else {
                Issue.record("Expected dismiss effect, got \(effect)")
            }
        }

        cancellable.cancel()
    }

    @Test("submit updates user in edit mode")
    func testSubmitEdit() async {
        let existingUser = User(
            id: "123",
            email: "old@example.com",
            firstName: "Old",
            lastName: "Name"
        )

        let mockService = MockUserService()
        let mockTracker = MockAnalyticsTracker()

        let viewModel = await withDependencies {
            $0.userService = mockService
            $0.analyticsTracker = mockTracker
        } operation: {
            UserFormViewModel(mode: .edit(existingUser))
        }

        var effectReceived: UserFormViewModel.Effect?

        // Subscribe to effects
        let cancellable = viewModel.effects.sink { effect in
            effectReceived = effect
        }

        // Update data
        viewModel.send(.updateFirstName("New"))
        viewModel.send(.updateLastName("Name"))
        viewModel.send(.updateEmail("new@example.com"))

        // Wait for validation
        try? await Task.sleep(for: .milliseconds(500))

        // Submit
        viewModel.send(.submit)

        // Wait for submission
        try? await Task.sleep(for: .milliseconds(300))

        #expect(viewModel.state.isLoading == false)
        #expect(mockTracker.trackedEvents.count > 0)

        cancellable.cancel()
    }

    @Test("submit handles errors")
    func testSubmitError() async {
        let mockService = MockUserService()
        mockService.shouldThrowError = AppError.networkError(
            .E1000_NO_CONNECTION,
            message: "No connection",
            isRetryable: true,
            underlyingError: nil
        )

        let mockTracker = MockAnalyticsTracker()

        let viewModel = await withDependencies {
            $0.userService = mockService
            $0.analyticsTracker = mockTracker
        } operation: {
            UserFormViewModel(mode: .create)
        }

        var effectReceived: UserFormViewModel.Effect?

        // Subscribe to effects
        let cancellable = viewModel.effects.sink { effect in
            effectReceived = effect
        }

        // Set valid data
        viewModel.send(.updateFirstName("John"))
        viewModel.send(.updateLastName("Doe"))
        viewModel.send(.updateEmail("john.doe@example.com"))

        // Wait for validation
        try? await Task.sleep(for: .milliseconds(500))

        // Submit
        viewModel.send(.submit)

        // Wait for submission
        try? await Task.sleep(for: .milliseconds(300))

        #expect(viewModel.state.isLoading == false)

        // Should show error effect
        if let effect = effectReceived {
            if case .showError = effect {
                // Success
            } else {
                Issue.record("Expected showError effect, got \(effect)")
            }
        }

        #expect(mockTracker.trackedAppErrors.count > 0)

        cancellable.cancel()
    }

    @Test("submit does not proceed when form invalid")
    func testSubmitInvalid() async {
        let mockService = MockUserService()

        let viewModel = await withDependencies {
            $0.userService = mockService
        } operation: {
            UserFormViewModel(mode: .create)
        }

        // Set invalid data
        viewModel.send(.updateFirstName(""))
        viewModel.send(.updateLastName(""))
        viewModel.send(.updateEmail("invalid"))

        // Wait for validation
        try? await Task.sleep(for: .milliseconds(500))

        #expect(viewModel.state.isSaveEnabled == false)

        // Attempt submit
        viewModel.send(.submit)

        // Wait
        try? await Task.sleep(for: .milliseconds(200))

        // Should still be invalid
        #expect(viewModel.state.isSaveEnabled == false)
    }

    // MARK: - Mode Tests

    @Test("Mode enum provides correct titles")
    func testModeProperties() {
        let createMode: UserFormViewModel.Mode = .create
        #expect(createMode.title == "Create User")
        #expect(createMode.submitButtonTitle == "Create")

        let user = User.mock()
        let editMode: UserFormViewModel.Mode = .edit(user)
        #expect(editMode.title == "Edit User")
        #expect(editMode.submitButtonTitle == "Save")
    }
}
