//
//  UserFormViewModelTests.swift
//  arcana-iosTests
//
//  Created by John on 2025/11/15
//  Rewritten to use @Observable output pattern (removed Combine @Published dependency)
//

import Testing
import Foundation
import Dependencies
@testable import arcana_ios

/// Comprehensive tests for UserFormViewModel
@MainActor
struct UserFormViewModelTests {

    // MARK: - Initialization Tests

    @Test("UserFormViewModel initializes in create mode with empty fields")
    func testInitializationCreateMode() {
        let viewModel = UserFormViewModel(mode: .create)

        #expect(viewModel.output.user.firstName == "")
        #expect(viewModel.output.user.lastName == "")
        #expect(viewModel.output.user.email == "")
        #expect(viewModel.output.user.avatar == "")
        #expect(viewModel.output.isLoading == false)
        #expect(viewModel.output.isSaveEnabled == false)
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

        #expect(viewModel.output.user.firstName == "John")
        #expect(viewModel.output.user.lastName == "Doe")
        #expect(viewModel.output.user.email == "test@example.com")
        #expect(viewModel.output.user.avatar == "https://example.com/avatar.jpg")
        #expect(viewModel.formTitle == "Edit User")
        #expect(viewModel.submitButtonTitle == "Save")
    }

    // MARK: - Field Update Tests

    @Test("updateFirstName updates output")
    func testUpdateFirstName() async {
        let viewModel = UserFormViewModel(mode: .create)

        await viewModel.input(.updateFirstName("John"))
        try? await Task.sleep(for: .milliseconds(100))

        #expect(viewModel.output.user.firstName == "John")
    }

    @Test("updateFirstName validates immediately")
    func testUpdateFirstNameValidation() async {
        let viewModel = UserFormViewModel(mode: .create)

        await viewModel.input(.updateFirstName(""))
        try? await Task.sleep(for: .milliseconds(400))

        #expect(viewModel.output.user.firstName == "")
        #expect(viewModel.output.validationErrors.firstNameError != nil)
    }

    @Test("updateLastName updates output")
    func testUpdateLastName() async {
        let viewModel = UserFormViewModel(mode: .create)

        await viewModel.input(.updateLastName("Doe"))
        try? await Task.sleep(for: .milliseconds(100))

        #expect(viewModel.output.user.lastName == "Doe")
    }

    @Test("updateEmail updates output")
    func testUpdateEmail() async {
        let viewModel = UserFormViewModel(mode: .create)

        await viewModel.input(.updateEmail("test@example.com"))
        try? await Task.sleep(for: .milliseconds(100))

        #expect(viewModel.output.user.email == "test@example.com")
    }

    @Test("updateEmail validates format")
    func testUpdateEmailValidation() async {
        let viewModel = UserFormViewModel(mode: .create)

        await viewModel.input(.updateEmail("invalid-email"))
        try? await Task.sleep(for: .milliseconds(400))

        #expect(viewModel.output.user.email == "invalid-email")
        #expect(viewModel.output.validationErrors.emailError != nil)
    }

    @Test("updateAvatar updates output")
    func testUpdateAvatar() async {
        let viewModel = UserFormViewModel(mode: .create)

        await viewModel.input(.updateAvatar("https://example.com/avatar.jpg"))
        try? await Task.sleep(for: .milliseconds(100))

        #expect(viewModel.output.user.avatar == "https://example.com/avatar.jpg")
    }

    // MARK: - Validation Tests

    @Test("validateAll validates all fields")
    func testValidateAll() async {
        let viewModel = UserFormViewModel(mode: .create)

        await viewModel.input(.validateAll)
        try? await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.output.validationErrors.firstNameError != nil)
        #expect(viewModel.output.validationErrors.lastNameError != nil)
        #expect(viewModel.output.validationErrors.emailError != nil)
    }

    @Test("isSaveEnabled is true when all fields valid")
    func testIsSaveEnabled() async {
        let viewModel = UserFormViewModel(mode: .create)

        await viewModel.input(.updateFirstName("John"))
        await viewModel.input(.updateLastName("Doe"))
        await viewModel.input(.updateEmail("john.doe@example.com"))
        try? await Task.sleep(for: .milliseconds(500))

        #expect(viewModel.output.isSaveEnabled == true)
    }

    @Test("isSaveEnabled is false when fields invalid")
    func testIsSaveEnabledInvalid() async {
        let viewModel = UserFormViewModel(mode: .create)

        await viewModel.input(.updateFirstName("John"))
        await viewModel.input(.updateLastName("Doe"))
        await viewModel.input(.updateEmail("invalid"))
        try? await Task.sleep(for: .milliseconds(500))

        #expect(viewModel.output.isSaveEnabled == false)
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

        await viewModel.input(.updateFirstName("John"))
        await viewModel.input(.updateLastName("Doe"))
        await viewModel.input(.updateEmail("john.doe@example.com"))
        try? await Task.sleep(for: .milliseconds(500))

        let effect = await viewModel.input(.submit)
        try? await Task.sleep(for: .milliseconds(300))

        #expect(viewModel.output.isLoading == false)
        #expect(mockTracker.trackedEvents.count > 0)

        if let effect = effect {
            if case .dismiss = effect {
                // Expected success
            } else {
                Issue.record("Expected dismiss effect, got \(effect)")
            }
        }
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

        await viewModel.input(.updateFirstName("New"))
        await viewModel.input(.updateLastName("Name"))
        await viewModel.input(.updateEmail("new@example.com"))
        try? await Task.sleep(for: .milliseconds(500))

        _ = await viewModel.input(.submit)
        try? await Task.sleep(for: .milliseconds(300))

        #expect(viewModel.output.isLoading == false)
        #expect(mockTracker.trackedEvents.count > 0)
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

        await viewModel.input(.updateFirstName("John"))
        await viewModel.input(.updateLastName("Doe"))
        await viewModel.input(.updateEmail("john.doe@example.com"))
        try? await Task.sleep(for: .milliseconds(500))

        let effect = await viewModel.input(.submit)
        try? await Task.sleep(for: .milliseconds(300))

        #expect(viewModel.output.isLoading == false)

        if let effect = effect {
            if case .showError = effect {
                // Expected error effect
            } else {
                Issue.record("Expected showError effect, got \(effect)")
            }
        }

        #expect(mockTracker.trackedAppErrors.count > 0)
    }

    @Test("submit does not proceed when form invalid")
    func testSubmitInvalid() async {
        let mockService = MockUserService()

        let viewModel = await withDependencies {
            $0.userService = mockService
        } operation: {
            UserFormViewModel(mode: .create)
        }

        await viewModel.input(.updateFirstName(""))
        await viewModel.input(.updateLastName(""))
        await viewModel.input(.updateEmail("invalid"))
        try? await Task.sleep(for: .milliseconds(500))

        #expect(viewModel.output.isSaveEnabled == false)

        _ = await viewModel.input(.submit)
        try? await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.output.isSaveEnabled == false)
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
