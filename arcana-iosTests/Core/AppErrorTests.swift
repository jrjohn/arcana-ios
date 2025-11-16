//
//  AppErrorTests.swift
//  arcana-iosTests
//
//  Created by Claude Code
//

import Testing
import Foundation
@testable import arcana_ios

/// Comprehensive tests for AppError
struct AppErrorTests {

    // MARK: - Error Code Tests

    @Test("Network error has correct error code")
    func testNetworkErrorCode() {
        let error = AppError.networkError(.E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: nil)
        #expect(error.errorCode == .E1000_NO_CONNECTION)
    }

    @Test("Validation error has correct error code")
    func testValidationErrorCode() {
        let error = AppError.validationError(.E2001_INVALID_EMAIL, field: "email", message: "Invalid email")
        #expect(error.errorCode == .E2001_INVALID_EMAIL)
    }

    @Test("Server error has correct error code")
    func testServerErrorCode() {
        let error = AppError.serverError(.E3001_BAD_REQUEST, statusCode: 400, message: "Bad request")
        #expect(error.errorCode == .E3001_BAD_REQUEST)
    }

    // MARK: - Error Message Tests

    @Test("All error types return correct messages")
    func testErrorMessages() {
        let networkError = AppError.networkError(.E1000_NO_CONNECTION, message: "Network message", isRetryable: true, underlyingError: nil)
        #expect(networkError.message == "Network message")

        let validationError = AppError.validationError(.E2001_INVALID_EMAIL, field: "email", message: "Validation message")
        #expect(validationError.message == "Validation message")

        let serverError = AppError.serverError(.E3001_BAD_REQUEST, statusCode: 400, message: "Server message")
        #expect(serverError.message == "Server message")
    }

    // MARK: - Retryable Tests

    @Test("Network errors respect retryable flag")
    func testNetworkErrorRetryable() {
        let retryable = AppError.networkError(.E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: nil)
        #expect(retryable.isRetryable == true)

        let notRetryable = AppError.networkError(.E1004_SSL_ERROR, message: "SSL error", isRetryable: false, underlyingError: nil)
        #expect(notRetryable.isRetryable == false)
    }

    @Test("Server errors with retryable codes are retryable")
    func testServerErrorRetryable() {
        let error = AppError.serverError(.E3005_INTERNAL_SERVER_ERROR, statusCode: 500, message: "Server error")
        // Internal server errors should be retryable
        #expect(error.isRetryable == true)
    }

    @Test("Validation errors are not retryable")
    func testValidationErrorNotRetryable() {
        let error = AppError.validationError(.E2001_INVALID_EMAIL, field: "email", message: "Invalid")
        #expect(error.isRetryable == false)
    }

    @Test("Auth errors are not retryable")
    func testAuthErrorNotRetryable() {
        let error = AppError.authError(.E4001_UNAUTHORIZED, message: "Unauthorized")
        #expect(error.isRetryable == false)
    }

    @Test("Conflict errors are retryable")
    func testConflictErrorRetryable() {
        let error = AppError.conflictError(.E5000_DATA_CONFLICT, message: "Conflict")
        #expect(error.isRetryable == true)
    }

    // MARK: - Underlying Error Tests

    @Test("Network error preserves underlying error")
    func testNetworkErrorUnderlyingError() {
        let underlying = URLError(.notConnectedToInternet)
        let error = AppError.networkError(.E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: underlying)

        #expect(error.underlyingError != nil)
    }

    @Test("Validation error has no underlying error")
    func testValidationErrorNoUnderlyingError() {
        let error = AppError.validationError(.E2001_INVALID_EMAIL, field: "email", message: "Invalid")
        #expect(error.underlyingError == nil)
    }

    // MARK: - From Error Tests

    @Test("URLError converts to AppError correctly")
    func testFromURLError() {
        let urlError = URLError(.notConnectedToInternet)
        let appError = AppError.from(urlError)

        #expect(appError.errorCode == .E1000_NO_CONNECTION)
        #expect(appError.isRetryable == true)
    }

    @Test("Timeout URLError converts correctly")
    func testFromTimeoutError() {
        let urlError = URLError(.timedOut)
        let appError = AppError.from(urlError)

        #expect(appError.errorCode == .E1001_CONNECTION_TIMEOUT)
        #expect(appError.isRetryable == true)
    }

    @Test("DNS error converts correctly")
    func testFromDNSError() {
        let urlError = URLError(.cannotFindHost)
        let appError = AppError.from(urlError)

        #expect(appError.errorCode == .E1002_UNKNOWN_HOST)
        #expect(appError.isRetryable == true)
    }

    @Test("Cancelled error converts correctly")
    func testFromCancelledError() {
        let urlError = URLError(.cancelled)
        let appError = AppError.from(urlError)

        #expect(appError.errorCode == .E1006_REQUEST_CANCELLED)
        #expect(appError.isRetryable == false)
    }

    @Test("SSL error converts correctly")
    func testFromSSLError() {
        let urlError = URLError(.secureConnectionFailed)
        let appError = AppError.from(urlError)

        #expect(appError.errorCode == .E1004_SSL_ERROR)
        #expect(appError.isRetryable == false)
    }

    @Test("DecodingError converts correctly")
    func testFromDecodingError() {
        let decodingError = DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "test"))
        let appError = AppError.from(decodingError)

        #expect(appError.errorCode == .E9004_DESERIALIZATION_ERROR)
    }

    @Test("Generic error converts to unknown error")
    func testFromGenericError() {
        struct CustomError: Error {}
        let error = CustomError()
        let appError = AppError.from(error)

        #expect(appError.errorCode == .E9000_UNKNOWN)
    }

    @Test("AppError passed through unchanged")
    func testFromAppError() {
        let original = AppError.validationError(.E2001_INVALID_EMAIL, field: "email", message: "Invalid")
        let result = AppError.from(original)

        #expect(result.errorCode == original.errorCode)
    }

    // MARK: - From HTTP Response Tests

    @Test("400 status code creates bad request error")
    func testFromHTTPBadRequest() {
        let error = AppError.fromHTTPResponse(statusCode: 400, data: nil)
        #expect(error.errorCode == .E3001_BAD_REQUEST)
    }

    @Test("401 status code creates unauthorized error")
    func testFromHTTPUnauthorized() {
        let error = AppError.fromHTTPResponse(statusCode: 401, data: nil)
        #expect(error.errorCode == .E4001_UNAUTHORIZED)
    }

    @Test("403 status code creates forbidden error")
    func testFromHTTPForbidden() {
        let error = AppError.fromHTTPResponse(statusCode: 403, data: nil)
        #expect(error.errorCode == .E4002_FORBIDDEN)
    }

    @Test("404 status code creates not found error")
    func testFromHTTPNotFound() {
        let error = AppError.fromHTTPResponse(statusCode: 404, data: nil)
        #expect(error.errorCode == .E3002_NOT_FOUND)
    }

    @Test("409 status code creates conflict error")
    func testFromHTTPConflict() {
        let error = AppError.fromHTTPResponse(statusCode: 409, data: nil)
        #expect(error.errorCode == .E5000_DATA_CONFLICT)
    }

    @Test("429 status code creates rate limit error")
    func testFromHTTPRateLimit() {
        let error = AppError.fromHTTPResponse(statusCode: 429, data: nil)
        #expect(error.errorCode == .E3004_RATE_LIMITED)
    }

    @Test("500 status code creates server error")
    func testFromHTTPServerError() {
        let error = AppError.fromHTTPResponse(statusCode: 500, data: nil)
        #expect(error.errorCode == .E3005_INTERNAL_SERVER_ERROR)
    }

    @Test("Unknown status code creates generic server error")
    func testFromHTTPUnknownStatus() {
        let error = AppError.fromHTTPResponse(statusCode: 418, data: nil)
        #expect(error.errorCode == .E3000_SERVER_ERROR)
    }

    // MARK: - LocalizedError Tests

    @Test("Error description includes code and message")
    func testErrorDescription() {
        let error = AppError.networkError(.E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: nil)
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description!.contains("E1000"))
        #expect(description!.contains("No connection"))
    }

    @Test("Recovery suggestion for retryable errors")
    func testRecoverySuggestionRetryable() {
        let error = AppError.networkError(.E1001_CONNECTION_TIMEOUT, message: "Timeout", isRetryable: true, underlyingError: nil)
        let suggestion = error.recoverySuggestion

        #expect(suggestion != nil)
        #expect(suggestion!.contains("try again"))
    }

    @Test("Recovery suggestion for no connection")
    func testRecoverySuggestionNoConnection() {
        let error = AppError.networkError(.E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: nil)
        let suggestion = error.recoverySuggestion

        #expect(suggestion != nil)
        #expect(suggestion!.contains("internet connection"))
    }

    @Test("Recovery suggestion for validation errors")
    func testRecoverySuggestionValidation() {
        let error = AppError.validationError(.E2001_INVALID_EMAIL, field: "email", message: "Invalid")
        let suggestion = error.recoverySuggestion

        #expect(suggestion != nil)
        #expect(suggestion!.contains("correct"))
    }

    // MARK: - CustomStringConvertible Tests

    @Test("Description includes all error information")
    func testCustomStringDescription() {
        let error = AppError.networkError(.E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: nil)
        let description = error.description

        #expect(description.contains("E1000"))
        #expect(description.contains("No connection"))
    }

    @Test("Description includes underlying error when present")
    func testDescriptionWithUnderlyingError() {
        let underlying = URLError(.notConnectedToInternet)
        let error = AppError.networkError(.E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: underlying)
        let description = error.description

        #expect(description.contains("Underlying"))
    }
}
