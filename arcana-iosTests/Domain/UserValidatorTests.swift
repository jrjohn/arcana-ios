//
//  UserValidatorTests.swift
//  arcana-iosTests
//
//  Created by John on 2025/11/15
//

import Testing
import Foundation
@testable import arcana_ios

/// Comprehensive tests for UserValidator
struct UserValidatorTests {

    // MARK: - Email Validation Tests

    @Test("Valid email addresses pass validation")
    func testValidEmails() {
        let validEmails = [
            "test@example.com",
            "user.name@example.com",
            "user+tag@example.co.uk",
            "test123@test-domain.com",
            "a@b.co"
        ]

        for email in validEmails {
            let result = UserValidator.validateEmail(email)
            if case .failure = result {
                Issue.record("Expected success for valid email: \(email)")
            }
        }
    }

    @Test("Empty email fails validation")
    func testEmptyEmail() {
        let result = UserValidator.validateEmail("")

        if case .failure(let error) = result {
            #expect(error == .requiredField("email"))
        } else {
            Issue.record("Expected failure for empty email")
        }
    }

    @Test("Email too long fails validation")
    func testEmailTooLong() {
        let longEmail = String(repeating: "a", count: 256) + "@example.com"
        let result = UserValidator.validateEmail(longEmail)

        if case .failure(let error) = result {
            if case .fieldTooLong(let field, let maxLength) = error {
                #expect(field == "email")
                #expect(maxLength == 255)
            } else {
                Issue.record("Expected fieldTooLong error")
            }
        } else {
            Issue.record("Expected failure for too long email")
        }
    }

    @Test("Invalid email formats fail validation")
    func testInvalidEmailFormats() {
        let invalidEmails = [
            "notanemail",
            "@example.com",
            "user@",
            "user @example.com",
            "user@.com",
            "user..name@example.com"
        ]

        for email in invalidEmails {
            let result = UserValidator.validateEmail(email)

            if case .success = result {
                Issue.record("Expected failure for invalid email: \(email)")
            }
        }
    }

    // MARK: - Name Validation Tests

    @Test("Valid names pass validation")
    func testValidNames() {
        let validNames = [
            ("John", "firstName"),
            ("Mary-Jane", "firstName"),
            ("O'Brien", "lastName"),
            ("Jean Paul", "firstName"),
            ("A", "firstName")
        ]

        for (name, field) in validNames {
            let result = UserValidator.validateName(name, field: field)
            if case .failure = result {
                Issue.record("Expected success for valid name: \(name)")
            }
        }
    }

    @Test("Empty name fails validation")
    func testEmptyName() {
        let result = UserValidator.validateName("", field: "firstName")

        if case .failure(let error) = result {
            #expect(error == .requiredField("firstName"))
        } else {
            Issue.record("Expected failure for empty name")
        }
    }

    @Test("Whitespace-only name fails validation")
    func testWhitespaceOnlyName() {
        let result = UserValidator.validateName("   ", field: "firstName")

        if case .failure(let error) = result {
            #expect(error == .requiredField("firstName"))
        } else {
            Issue.record("Expected failure for whitespace-only name")
        }
    }

    @Test("Name too long fails validation")
    func testNameTooLong() {
        let longName = String(repeating: "a", count: 101)
        let result = UserValidator.validateName(longName, field: "firstName")

        if case .failure(let error) = result {
            if case .fieldTooLong(let field, let maxLength) = error {
                #expect(field == "firstName")
                #expect(maxLength == 100)
            } else {
                Issue.record("Expected fieldTooLong error")
            }
        } else {
            Issue.record("Expected failure for too long name")
        }
    }

    @Test("Name with invalid characters fails validation")
    func testInvalidNameCharacters() {
        let invalidNames = [
            "John123",
            "Jane@Doe",
            "Test#Name",
            "Name$",
            "User_Name"
        ]

        for name in invalidNames {
            let result = UserValidator.validateName(name, field: "firstName")

            if case .success = result {
                Issue.record("Expected failure for invalid name: \(name)")
            }
        }
    }

    // MARK: - Full User Validation Tests

    @Test("Valid user passes validation")
    func testValidUserValidation() {
        let user = User(
            email: "test@example.com",
            firstName: "John",
            lastName: "Doe"
        )

        let result = UserValidator.validateUser(user)
        if case .failure = result {
            Issue.record("Expected success for valid user")
        }
    }

    @Test("User with invalid email fails validation")
    func testUserInvalidEmail() {
        let user = User(
            email: "invalid-email",
            firstName: "John",
            lastName: "Doe"
        )

        let result = UserValidator.validateUser(user)

        if case .success = result {
            Issue.record("Expected failure for invalid email")
        }
    }

    @Test("User with invalid first name fails validation")
    func testUserInvalidFirstName() {
        let user = User(
            email: "test@example.com",
            firstName: "John123",
            lastName: "Doe"
        )

        let result = UserValidator.validateUser(user)

        if case .success = result {
            Issue.record("Expected failure for invalid first name")
        }
    }

    @Test("User with invalid last name fails validation")
    func testUserInvalidLastName() {
        let user = User(
            email: "test@example.com",
            firstName: "John",
            lastName: ""
        )

        let result = UserValidator.validateUser(user)

        if case .success = result {
            Issue.record("Expected failure for empty last name")
        }
    }

    @Test("Validate for create delegates to validateUser")
    func testValidateForCreate() {
        let validUser = User(
            email: "test@example.com",
            firstName: "John",
            lastName: "Doe"
        )

        let result = UserValidator.validateForCreate(validUser)
        if case .failure = result {
            Issue.record("Expected success for create validation")
        }
    }

    @Test("Validate for update delegates to validateUser")
    func testValidateForUpdate() {
        let validUser = User(
            email: "test@example.com",
            firstName: "John",
            lastName: "Doe"
        )

        let result = UserValidator.validateForUpdate(validUser)
        if case .failure = result {
            Issue.record("Expected success for update validation")
        }
    }

    // MARK: - Field Validation Result Tests

    @Test("Valid email field returns valid result")
    func testValidateEmailFieldValid() {
        let result = UserValidator.validateEmailField("test@example.com")

        #expect(result.isValid == true)
        #expect(result.errorMessage == nil)
    }

    @Test("Invalid email field returns invalid result with message")
    func testValidateEmailFieldInvalid() {
        let result = UserValidator.validateEmailField("")

        #expect(result.isValid == false)
        #expect(result.errorMessage != nil)
    }

    @Test("Valid name field returns valid result")
    func testValidateNameFieldValid() {
        let result = UserValidator.validateNameField("John", field: "firstName")

        #expect(result.isValid == true)
        #expect(result.errorMessage == nil)
    }

    @Test("Invalid name field returns invalid result with message")
    func testValidateNameFieldInvalid() {
        let result = UserValidator.validateNameField("", field: "firstName")

        #expect(result.isValid == false)
        #expect(result.errorMessage != nil)
    }

    // MARK: - ValidationError to AppError Tests

    @Test("Validation errors convert to AppError correctly")
    func testValidationErrorToAppError() {
        let invalidEmailError = UserValidator.ValidationError.invalidEmail("email")
        let appError = invalidEmailError.appError

        #expect(appError.errorCode == .E2001_INVALID_EMAIL)
        #expect(appError.message == "Invalid email address format")
    }

    @Test("Required field error converts correctly")
    func testRequiredFieldErrorToAppError() {
        let requiredError = UserValidator.ValidationError.requiredField("firstName")
        let appError = requiredError.appError

        #expect(appError.errorCode == .E2003_REQUIRED_FIELD)
    }

    @Test("Field too long error converts correctly")
    func testFieldTooLongErrorToAppError() {
        let tooLongError = UserValidator.ValidationError.fieldTooLong("email", maxLength: 255)
        let appError = tooLongError.appError

        #expect(appError.errorCode == .E2004_FIELD_TOO_LONG)
        #expect(appError.message.contains("255"))
    }

    @Test("Invalid format error converts correctly")
    func testInvalidFormatErrorToAppError() {
        let formatError = UserValidator.ValidationError.invalidFormat("field", reason: "Custom reason")
        let appError = formatError.appError

        #expect(appError.errorCode == .E2006_INVALID_FORMAT)
        #expect(appError.message == "Custom reason")
    }
}
