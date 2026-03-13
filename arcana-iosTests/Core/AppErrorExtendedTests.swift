//
//  AppErrorExtendedTests.swift
//  arcana-iosTests
//
//  Extended tests for AppError coverage
//

import Testing
import Foundation
@testable import arcana_ios

/// Tests for AppError.fromHTTPResponse and additional error properties
struct AppErrorExtendedTests {

    // MARK: - fromHTTPResponse Tests

    @Test("fromHTTPResponse 400 returns bad request error")
    func testFromHTTP400() {
        let error = AppError.fromHTTPResponse(statusCode: 400, data: nil)
        if case .serverError(let code, let status, _) = error {
            #expect(code == .E3001_BAD_REQUEST)
            #expect(status == 400)
        } else {
            Issue.record("Expected serverError")
        }
    }

    @Test("fromHTTPResponse 401 returns unauthorized error")
    func testFromHTTP401() {
        let error = AppError.fromHTTPResponse(statusCode: 401, data: nil)
        if case .authError(let code, _) = error {
            #expect(code == .E4001_UNAUTHORIZED)
        } else {
            Issue.record("Expected authError")
        }
    }

    @Test("fromHTTPResponse 403 returns forbidden error")
    func testFromHTTP403() {
        let error = AppError.fromHTTPResponse(statusCode: 403, data: nil)
        if case .authError(let code, _) = error {
            #expect(code == .E4002_FORBIDDEN)
        } else {
            Issue.record("Expected authError")
        }
    }

    @Test("fromHTTPResponse 404 returns not found error")
    func testFromHTTP404() {
        let error = AppError.fromHTTPResponse(statusCode: 404, data: nil)
        if case .serverError(let code, let status, _) = error {
            #expect(code == .E3002_NOT_FOUND)
            #expect(status == 404)
        } else {
            Issue.record("Expected serverError")
        }
    }

    @Test("fromHTTPResponse 409 returns conflict error")
    func testFromHTTP409() {
        let error = AppError.fromHTTPResponse(statusCode: 409, data: nil)
        if case .conflictError(let code, _) = error {
            #expect(code == .E5000_DATA_CONFLICT)
        } else {
            Issue.record("Expected conflictError")
        }
    }

    @Test("fromHTTPResponse 429 returns rate limited error")
    func testFromHTTP429() {
        let error = AppError.fromHTTPResponse(statusCode: 429, data: nil)
        if case .serverError(let code, _, _) = error {
            #expect(code == .E3004_RATE_LIMITED)
        } else {
            Issue.record("Expected serverError")
        }
    }

    @Test("fromHTTPResponse 500 returns internal server error")
    func testFromHTTP500() {
        let error = AppError.fromHTTPResponse(statusCode: 500, data: nil)
        if case .serverError(let code, _, _) = error {
            #expect(code == .E3005_INTERNAL_SERVER_ERROR)
        } else {
            Issue.record("Expected serverError")
        }
    }

    @Test("fromHTTPResponse 503 returns internal server error")
    func testFromHTTP503() {
        let error = AppError.fromHTTPResponse(statusCode: 503, data: nil)
        if case .serverError(let code, _, _) = error {
            #expect(code == .E3005_INTERNAL_SERVER_ERROR)
        } else {
            Issue.record("Expected serverError")
        }
    }

    @Test("fromHTTPResponse unknown status returns generic server error")
    func testFromHTTPUnknown() {
        let error = AppError.fromHTTPResponse(statusCode: 418, data: nil)
        if case .serverError(let code, _, _) = error {
            #expect(code == .E3000_SERVER_ERROR)
        } else {
            Issue.record("Expected serverError")
        }
    }

    @Test("fromHTTPResponse includes message from data")
    func testFromHTTPWithData() {
        let data = "Custom error message".data(using: .utf8)
        let error = AppError.fromHTTPResponse(statusCode: 400, data: data)
        #expect(error.message == "Custom error message")
    }

    // MARK: - AppError.from URLError Tests

    @Test("AppError.from maps notConnectedToInternet")
    func testFromURLErrorNotConnected() {
        let urlError = URLError(.notConnectedToInternet)
        let error = AppError.from(urlError)
        if case .networkError(let code, _, let retryable, _) = error {
            #expect(code == .E1000_NO_CONNECTION)
            #expect(retryable == true)
        } else {
            Issue.record("Expected networkError")
        }
    }

    @Test("AppError.from maps connectionLost")
    func testFromURLErrorConnectionLost() {
        let urlError = URLError(.networkConnectionLost)
        let error = AppError.from(urlError)
        if case .networkError(let code, _, _, _) = error {
            #expect(code == .E1000_NO_CONNECTION)
        } else {
            Issue.record("Expected networkError")
        }
    }

    @Test("AppError.from maps timedOut")
    func testFromURLErrorTimeout() {
        let urlError = URLError(.timedOut)
        let error = AppError.from(urlError)
        if case .networkError(let code, _, let retryable, _) = error {
            #expect(code == .E1001_CONNECTION_TIMEOUT)
            #expect(retryable == true)
        } else {
            Issue.record("Expected networkError")
        }
    }

    @Test("AppError.from maps cannotFindHost")
    func testFromURLErrorCannotFindHost() {
        let urlError = URLError(.cannotFindHost)
        let error = AppError.from(urlError)
        if case .networkError(let code, _, _, _) = error {
            #expect(code == .E1002_UNKNOWN_HOST)
        } else {
            Issue.record("Expected networkError")
        }
    }

    @Test("AppError.from maps dnsLookupFailed")
    func testFromURLErrorDNSFailed() {
        let urlError = URLError(.dnsLookupFailed)
        let error = AppError.from(urlError)
        if case .networkError(let code, _, _, _) = error {
            #expect(code == .E1002_UNKNOWN_HOST)
        } else {
            Issue.record("Expected networkError")
        }
    }

    @Test("AppError.from maps cancelled")
    func testFromURLErrorCancelled() {
        let urlError = URLError(.cancelled)
        let error = AppError.from(urlError)
        if case .networkError(let code, _, let retryable, _) = error {
            #expect(code == .E1006_REQUEST_CANCELLED)
            #expect(retryable == false)
        } else {
            Issue.record("Expected networkError")
        }
    }

    @Test("AppError.from maps SSL error")
    func testFromURLErrorSSL() {
        let urlError = URLError(.secureConnectionFailed)
        let error = AppError.from(urlError)
        if case .networkError(let code, _, let retryable, _) = error {
            #expect(code == .E1004_SSL_ERROR)
            #expect(retryable == false)
        } else {
            Issue.record("Expected networkError")
        }
    }

    @Test("AppError.from maps generic URLError")
    func testFromURLErrorGeneric() {
        let urlError = URLError(.badServerResponse)
        let error = AppError.from(urlError)
        if case .networkError(let code, _, _, _) = error {
            #expect(code == .E1003_NETWORK_IO)
        } else {
            Issue.record("Expected networkError")
        }
    }

    @Test("AppError.from maps DecodingError")
    func testFromDecodingError() {
        let decodingError = DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Test")
        )
        let error = AppError.from(decodingError)
        if case .unknownError(let code, _, _) = error {
            #expect(code == .E9004_DESERIALIZATION_ERROR)
        } else {
            Issue.record("Expected unknownError")
        }
    }

    @Test("AppError.from returns same AppError when input is AppError")
    func testFromAppError() {
        let original = AppError.authError(.E4001_UNAUTHORIZED, message: "Unauthorized")
        let result = AppError.from(original)
        if case .authError(let code, let msg) = result {
            #expect(code == .E4001_UNAUTHORIZED)
            #expect(msg == "Unauthorized")
        } else {
            Issue.record("Expected authError")
        }
    }

    @Test("AppError.from maps generic error to unknown")
    func testFromGenericError() {
        struct TestError: Error {}
        let error = AppError.from(TestError())
        if case .unknownError(let code, _, _) = error {
            #expect(code == .E9000_UNKNOWN)
        } else {
            Issue.record("Expected unknownError")
        }
    }

    // MARK: - AppError Properties Tests

    @Test("AppError.isRetryable is true for conflict errors")
    func testIsRetryableConflict() {
        let error = AppError.conflictError(.E5000_DATA_CONFLICT, message: "Conflict")
        #expect(error.isRetryable == true)
    }

    @Test("AppError.isRetryable is false for validation errors")
    func testIsRetryableValidation() {
        let error = AppError.validationError(.E2001_INVALID_EMAIL, field: "email", message: "Invalid")
        #expect(error.isRetryable == false)
    }

    @Test("AppError.isRetryable is false for auth errors")
    func testIsRetryableAuth() {
        let error = AppError.authError(.E4001_UNAUTHORIZED, message: "Unauthorized")
        #expect(error.isRetryable == false)
    }

    @Test("AppError.isRetryable is false for database errors")
    func testIsRetryableDatabase() {
        let error = AppError.databaseError(.E9000_UNKNOWN, message: "DB error", underlyingError: nil)
        #expect(error.isRetryable == false)
    }

    @Test("AppError.underlyingError is nil for non-wrapping errors")
    func testUnderlyingErrorNil() {
        let error = AppError.validationError(.E2001_INVALID_EMAIL, field: "email", message: "Invalid")
        #expect(error.underlyingError == nil)
    }

    @Test("AppError.underlyingError is set for database error")
    func testUnderlyingErrorSet() {
        struct InnerError: Error {}
        let inner = InnerError()
        let error = AppError.databaseError(.E9000_UNKNOWN, message: "DB error", underlyingError: inner)
        #expect(error.underlyingError != nil)
    }

    // MARK: - LocalizedError Tests

    @Test("AppError errorDescription is non-empty")
    func testErrorDescription() {
        let error = AppError.networkError(
            .E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: nil
        )
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("E1000"))
    }

    @Test("AppError failureReason is non-empty")
    func testFailureReason() {
        let error = AppError.networkError(
            .E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: nil
        )
        #expect(error.failureReason != nil)
        #expect(!error.failureReason!.isEmpty)
    }

    @Test("AppError recoverySuggestion is set for retryable errors")
    func testRecoverySuggestionRetryable() {
        let error = AppError.networkError(
            .E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: nil
        )
        #expect(error.recoverySuggestion != nil)
    }

    @Test("AppError recoverySuggestion includes internet guidance for E1000")
    func testRecoverySuggestionE1000() {
        let error = AppError.networkError(
            .E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: nil
        )
        #expect(error.recoverySuggestion?.contains("internet") == true)
    }

    @Test("AppError recoverySuggestion for validation error")
    func testRecoverySuggestionValidation() {
        let error = AppError.validationError(.E2001_INVALID_EMAIL, field: "email", message: "Invalid")
        #expect(error.recoverySuggestion != nil)
    }

    @Test("AppError recoverySuggestion for session expired")
    func testRecoverySuggestionSessionExpired() {
        let error = AppError.authError(.E4003_SESSION_EXPIRED, message: "Session expired")
        #expect(error.recoverySuggestion != nil)
    }

    @Test("AppError recoverySuggestion is nil for unknown errors")
    func testRecoverySuggestionNilForUnknown() {
        let error = AppError.unknownError(.E9000_UNKNOWN, message: "Unknown", underlyingError: nil)
        #expect(error.recoverySuggestion == nil)
    }

    // MARK: - CustomStringConvertible Tests

    @Test("AppError description contains error code")
    func testDescriptionContainsCode() {
        let error = AppError.networkError(
            .E1000_NO_CONNECTION, message: "No connection", isRetryable: true, underlyingError: nil
        )
        #expect(error.description.contains("E1000"))
    }

    @Test("AppError description includes underlying error when present")
    func testDescriptionWithUnderlying() {
        let urlError = URLError(.timedOut)
        let error = AppError.networkError(
            .E1001_CONNECTION_TIMEOUT, message: "Timeout", isRetryable: true, underlyingError: urlError
        )
        #expect(error.description.contains("Underlying"))
    }
}
