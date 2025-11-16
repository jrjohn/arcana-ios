//
//  AppError.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation

/// Application-level error types with associated error codes
enum AppError: Error {
    case networkError(ErrorCode, message: String, isRetryable: Bool, underlyingError: Error?)
    case validationError(ErrorCode, field: String, message: String)
    case serverError(ErrorCode, statusCode: Int, message: String)
    case authError(ErrorCode, message: String)
    case conflictError(ErrorCode, message: String)
    case databaseError(ErrorCode, message: String, underlyingError: Error?)
    case unknownError(ErrorCode, message: String, underlyingError: Error?)
    
    /// The error code associated with this error
    var errorCode: ErrorCode {
        switch self {
        case .networkError(let code, _, _, _):
            return code
        case .validationError(let code, _, _):
            return code
        case .serverError(let code, _, _):
            return code
        case .authError(let code, _):
            return code
        case .conflictError(let code, _):
            return code
        case .databaseError(let code, _, _):
            return code
        case .unknownError(let code, _, _):
            return code
        }
    }
    
    /// User-friendly error message
    var message: String {
        switch self {
        case .networkError(_, let message, _, _),
             .validationError(_, _, let message),
             .serverError(_, _, let message),
             .authError(_, let message),
             .conflictError(_, let message),
             .databaseError(_, let message, _),
             .unknownError(_, let message, _):
            return message
        }
    }
    
    /// Whether the operation can be retried
    var isRetryable: Bool {
        switch self {
        case .networkError(_, _, let retryable, _):
            return retryable
        case .serverError(let code, _, _):
            return code.isRetryable
        case .conflictError:
            return true
        case .validationError, .authError, .databaseError, .unknownError:
            return false
        }
    }
    
    /// The underlying system error if available
    var underlyingError: Error? {
        switch self {
        case .networkError(_, _, _, let error),
             .databaseError(_, _, let error),
             .unknownError(_, _, let error):
            return error
        default:
            return nil
        }
    }
    
    /// Convert any error to an AppError
    static func from(_ error: Error) -> AppError {
        // Already an AppError
        if let appError = error as? AppError {
            return appError
        }
        
        // URLError (network errors)
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError(
                    .E1000_NO_CONNECTION,
                    message: "No internet connection available",
                    isRetryable: true,
                    underlyingError: urlError
                )
            case .timedOut:
                return .networkError(
                    .E1001_CONNECTION_TIMEOUT,
                    message: "Connection attempt timed out",
                    isRetryable: true,
                    underlyingError: urlError
                )
            case .cannotFindHost, .dnsLookupFailed:
                return .networkError(
                    .E1002_UNKNOWN_HOST,
                    message: "Unable to resolve host address",
                    isRetryable: true,
                    underlyingError: urlError
                )
            case .cancelled:
                return .networkError(
                    .E1006_REQUEST_CANCELLED,
                    message: "Request was cancelled",
                    isRetryable: false,
                    underlyingError: urlError
                )
            case .secureConnectionFailed, .serverCertificateHasBadDate,
                 .serverCertificateUntrusted, .serverCertificateHasUnknownRoot:
                return .networkError(
                    .E1004_SSL_ERROR,
                    message: "Secure connection failed",
                    isRetryable: false,
                    underlyingError: urlError
                )
            default:
                return .networkError(
                    .E1003_NETWORK_IO,
                    message: "Network error occurred",
                    isRetryable: true,
                    underlyingError: urlError
                )
            }
        }
        
        // DecodingError (JSON parsing)
        if let decodingError = error as? DecodingError {
            return .unknownError(
                .E9004_DESERIALIZATION_ERROR,
                message: "Failed to parse server response",
                underlyingError: decodingError
            )
        }
        
        // EncodingError
        if let encodingError = error as? EncodingError {
            return .unknownError(
                .E9003_SERIALIZATION_ERROR,
                message: "Failed to encode data",
                underlyingError: encodingError
            )
        }
        
        // Generic error
        return .unknownError(
            .E9000_UNKNOWN,
            message: error.localizedDescription,
            underlyingError: error
        )
    }
    
    /// Create an AppError from HTTP response
    static func fromHTTPResponse(statusCode: Int, data: Data?) -> AppError {
        let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
        
        switch statusCode {
        case 400:
            return .serverError(.E3001_BAD_REQUEST, statusCode: statusCode, message: message)
        case 401:
            return .authError(.E4001_UNAUTHORIZED, message: message)
        case 403:
            return .authError(.E4002_FORBIDDEN, message: message)
        case 404:
            return .serverError(.E3002_NOT_FOUND, statusCode: statusCode, message: message)
        case 409:
            return .conflictError(.E5000_DATA_CONFLICT, message: message)
        case 429:
            return .serverError(.E3004_RATE_LIMITED, statusCode: statusCode, message: message)
        case 500...599:
            return .serverError(.E3005_INTERNAL_SERVER_ERROR, statusCode: statusCode, message: message)
        default:
            return .serverError(.E3000_SERVER_ERROR, statusCode: statusCode, message: message)
        }
    }
}

// MARK: - LocalizedError Conformance
extension AppError: LocalizedError {
    var errorDescription: String? {
        return "[\(errorCode.code)] \(message)"
    }
    
    var failureReason: String? {
        return errorCode.description
    }
    
    var recoverySuggestion: String? {
        if isRetryable {
            return "Please try again"
        }
        
        switch self {
        case .networkError(.E1000_NO_CONNECTION, _, _, _):
            return "Check your internet connection and try again"
        case .validationError:
            return "Please correct the highlighted fields"
        case .authError(.E4003_SESSION_EXPIRED, _):
            return "Please sign in again"
        default:
            return nil
        }
    }
}

// MARK: - CustomStringConvertible
extension AppError: CustomStringConvertible {
    var description: String {
        var desc = "[\(errorCode.code)] \(errorCode.category): \(message)"
        
        if let underlying = underlyingError {
            desc += " | Underlying: \(underlying.localizedDescription)"
        }
        
        return desc
    }
}
