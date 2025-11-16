//
//  UserValidator.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation

/// Validator for User input
struct UserValidator {
    
    // MARK: - Validation Errors
    enum ValidationError: Error, Equatable {
        case invalidEmail(String)
        case invalidName(String)
        case fieldTooLong(String, maxLength: Int)
        case fieldTooShort(String, minLength: Int)
        case requiredField(String)
        case invalidFormat(String, reason: String)
        
        var appError: AppError {
            switch self {
            case .invalidEmail(let field):
                return .validationError(
                    .E2001_INVALID_EMAIL,
                    field: field,
                    message: "Invalid email address format"
                )
            case .invalidName(let field):
                return .validationError(
                    .E2002_INVALID_NAME,
                    field: field,
                    message: "Invalid name format"
                )
            case .fieldTooLong(let field, let max):
                return .validationError(
                    .E2004_FIELD_TOO_LONG,
                    field: field,
                    message: "Maximum \(max) characters allowed"
                )
            case .fieldTooShort(let field, let min):
                return .validationError(
                    .E2005_FIELD_TOO_SHORT,
                    field: field,
                    message: "Minimum \(min) characters required"
                )
            case .requiredField(let field):
                return .validationError(
                    .E2003_REQUIRED_FIELD,
                    field: field,
                    message: "This field is required"
                )
            case .invalidFormat(let field, let reason):
                return .validationError(
                    .E2006_INVALID_FORMAT,
                    field: field,
                    message: reason
                )
            }
        }
    }
    
    // MARK: - Validation Rules
    private static let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
    private static let nameMinLength = 1
    private static let nameMaxLength = 100
    private static let emailMaxLength = 255
    
    // MARK: - Public Validation Methods
    
    /// Validate email address
    static func validateEmail(_ email: String) -> Result<Void, ValidationError> {
        // Check if empty
        guard !email.isEmpty else {
            return .failure(.requiredField("email"))
        }
        
        // Check length
        guard email.count <= emailMaxLength else {
            return .failure(.fieldTooLong("email", maxLength: emailMaxLength))
        }
        
        // Check format
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            return .failure(.invalidEmail("email"))
        }
        
        return .success(())
    }
    
    /// Validate name (first name, last name, etc.)
    static func validateName(_ name: String, field: String) -> Result<Void, ValidationError> {
        // Check if empty
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(.requiredField(field))
        }
        
        // Check minimum length
        guard name.count >= nameMinLength else {
            return .failure(.fieldTooShort(field, minLength: nameMinLength))
        }
        
        // Check maximum length
        guard name.count <= nameMaxLength else {
            return .failure(.fieldTooLong(field, maxLength: nameMaxLength))
        }
        
        // Check for invalid characters (only letters, spaces, hyphens, apostrophes)
        let allowedCharacters = CharacterSet.letters
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-'"))
        
        guard name.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            return .failure(.invalidName(field))
        }
        
        return .success(())
    }
    
    /// Validate entire User object
    static func validateUser(_ user: User) -> Result<Void, ValidationError> {
        // Validate first name
        if case .failure(let error) = validateName(user.firstName, field: "firstName") {
            return .failure(error)
        }
        
        // Validate last name
        if case .failure(let error) = validateName(user.lastName, field: "lastName") {
            return .failure(error)
        }
        
        // Validate email
        if case .failure(let error) = validateEmail(user.email) {
            return .failure(error)
        }
        
        return .success(())
    }
    
    /// Validate user for creation
    static func validateForCreate(_ user: User) -> Result<Void, ValidationError> {
        return validateUser(user)
    }
    
    /// Validate user for update
    static func validateForUpdate(_ user: User) -> Result<Void, ValidationError> {
        return validateUser(user)
    }
}

// MARK: - Field Validation Results
extension UserValidator {
    /// Validation result for a single field
    struct FieldValidationResult {
        let isValid: Bool
        let errorMessage: String?
        
        static var valid: FieldValidationResult {
            FieldValidationResult(isValid: true, errorMessage: nil)
        }
        
        static func invalid(_ message: String) -> FieldValidationResult {
            FieldValidationResult(isValid: false, errorMessage: message)
        }
    }
    
    /// Get validation result for email (returns user-friendly message)
    static func validateEmailField(_ email: String) -> FieldValidationResult {
        switch validateEmail(email) {
        case .success:
            return .valid
        case .failure(let error):
            return .invalid(error.appError.message)
        }
    }
    
    /// Get validation result for name (returns user-friendly message)
    static func validateNameField(_ name: String, field: String = "name") -> FieldValidationResult {
        switch validateName(name, field: field) {
        case .success:
            return .valid
        case .failure(let error):
            return .invalid(error.appError.message)
        }
    }
}
