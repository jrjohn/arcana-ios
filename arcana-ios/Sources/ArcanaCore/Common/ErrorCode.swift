//
//  ErrorCode.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation

/// Comprehensive error code system for Arcana iOS
/// Error codes follow the pattern: E####_DESCRIPTION or W####_DESCRIPTION
enum ErrorCode: CaseIterable {
    // MARK: - Network Errors (E1000-E1999)
    case E1000_NO_CONNECTION
    case E1001_CONNECTION_TIMEOUT
    case E1002_UNKNOWN_HOST
    case E1003_NETWORK_IO
    case E1004_SSL_ERROR
    case E1005_INVALID_RESPONSE
    case E1006_REQUEST_CANCELLED
    
    // MARK: - Validation Errors (E2000-E2999)
    case E2000_VALIDATION_FAILED
    case E2001_INVALID_EMAIL
    case E2002_INVALID_NAME
    case E2003_REQUIRED_FIELD
    case E2004_FIELD_TOO_LONG
    case E2005_FIELD_TOO_SHORT
    case E2006_INVALID_FORMAT
    case E2007_INVALID_RANGE
    
    // MARK: - Server Errors (E3000-E3999)
    case E3000_SERVER_ERROR
    case E3001_BAD_REQUEST
    case E3002_NOT_FOUND
    case E3003_SERVICE_UNAVAILABLE
    case E3004_RATE_LIMITED
    case E3005_INTERNAL_SERVER_ERROR
    case E3006_GATEWAY_TIMEOUT
    
    // MARK: - Auth Errors (E4000-E4999)
    case E4000_AUTH_REQUIRED
    case E4001_UNAUTHORIZED
    case E4002_FORBIDDEN
    case E4003_SESSION_EXPIRED
    case E4004_TOKEN_INVALID
    case E4005_TOKEN_EXPIRED
    
    // MARK: - Data Errors (E5000-E5999)
    case E5000_DATA_CONFLICT
    case E5001_STALE_DATA
    case E5002_DUPLICATE_ENTRY
    case E5003_CONSTRAINT_VIOLATION
    case E5004_DATA_NOT_FOUND
    case E5005_DATA_CORRUPTED
    
    // MARK: - Database Errors (E6000-E6999)
    case E6000_DATABASE_ERROR
    case E6001_QUERY_FAILED
    case E6002_TRANSACTION_FAILED
    case E6003_MIGRATION_FAILED
    case E6004_SAVE_FAILED
    case E6005_FETCH_FAILED
    
    // MARK: - System Errors (E9000-E9999)
    case E9000_UNKNOWN
    case E9001_UNEXPECTED_STATE
    case E9002_NULL_POINTER
    case E9003_SERIALIZATION_ERROR
    case E9004_DESERIALIZATION_ERROR
    case E9005_CONFIGURATION_ERROR
    
    // MARK: - Warnings (W1000-W3999)
    case W1000_SLOW_CONNECTION
    case W1001_OFFLINE_MODE
    case W1002_SYNC_PENDING
    case W2000_INCOMPLETE_DATA
    case W2001_DEPRECATED_FORMAT
    case W2002_PARTIAL_SUCCESS
    case W3000_STALE_CACHE
    case W3001_PARTIAL_SYNC
    case W3002_DATA_TRUNCATED
    
    /// Returns the error code string (e.g., "E1000")
    var code: String {
        return String(describing: self).components(separatedBy: "_").first ?? "E9000"
    }
    
    /// Returns a human-readable description of the error
    var description: String {
        switch self {
        // Network Errors
        case .E1000_NO_CONNECTION:
            return "No internet connection available"
        case .E1001_CONNECTION_TIMEOUT:
            return "Connection attempt timed out"
        case .E1002_UNKNOWN_HOST:
            return "Unable to resolve host address"
        case .E1003_NETWORK_IO:
            return "Network I/O error occurred"
        case .E1004_SSL_ERROR:
            return "SSL/TLS connection error"
        case .E1005_INVALID_RESPONSE:
            return "Invalid response from server"
        case .E1006_REQUEST_CANCELLED:
            return "Request was cancelled"
            
        // Validation Errors
        case .E2000_VALIDATION_FAILED:
            return "Validation failed"
        case .E2001_INVALID_EMAIL:
            return "Invalid email address format"
        case .E2002_INVALID_NAME:
            return "Invalid name format"
        case .E2003_REQUIRED_FIELD:
            return "Required field is missing"
        case .E2004_FIELD_TOO_LONG:
            return "Field exceeds maximum length"
        case .E2005_FIELD_TOO_SHORT:
            return "Field is below minimum length"
        case .E2006_INVALID_FORMAT:
            return "Invalid field format"
        case .E2007_INVALID_RANGE:
            return "Value is out of valid range"
            
        // Server Errors
        case .E3000_SERVER_ERROR:
            return "Server error occurred"
        case .E3001_BAD_REQUEST:
            return "Invalid request to server"
        case .E3002_NOT_FOUND:
            return "Resource not found"
        case .E3003_SERVICE_UNAVAILABLE:
            return "Service temporarily unavailable"
        case .E3004_RATE_LIMITED:
            return "Too many requests, please try again later"
        case .E3005_INTERNAL_SERVER_ERROR:
            return "Internal server error"
        case .E3006_GATEWAY_TIMEOUT:
            return "Gateway timeout"
            
        // Auth Errors
        case .E4000_AUTH_REQUIRED:
            return "Authentication required"
        case .E4001_UNAUTHORIZED:
            return "Unauthorized access"
        case .E4002_FORBIDDEN:
            return "Access forbidden"
        case .E4003_SESSION_EXPIRED:
            return "Session has expired"
        case .E4004_TOKEN_INVALID:
            return "Authentication token is invalid"
        case .E4005_TOKEN_EXPIRED:
            return "Authentication token has expired"
            
        // Data Errors
        case .E5000_DATA_CONFLICT:
            return "Data conflict detected"
        case .E5001_STALE_DATA:
            return "Data is stale and needs refresh"
        case .E5002_DUPLICATE_ENTRY:
            return "Duplicate entry detected"
        case .E5003_CONSTRAINT_VIOLATION:
            return "Data constraint violation"
        case .E5004_DATA_NOT_FOUND:
            return "Requested data not found"
        case .E5005_DATA_CORRUPTED:
            return "Data corruption detected"
            
        // Database Errors
        case .E6000_DATABASE_ERROR:
            return "Database error occurred"
        case .E6001_QUERY_FAILED:
            return "Database query failed"
        case .E6002_TRANSACTION_FAILED:
            return "Database transaction failed"
        case .E6003_MIGRATION_FAILED:
            return "Database migration failed"
        case .E6004_SAVE_FAILED:
            return "Failed to save data"
        case .E6005_FETCH_FAILED:
            return "Failed to fetch data"
            
        // System Errors
        case .E9000_UNKNOWN:
            return "Unknown error occurred"
        case .E9001_UNEXPECTED_STATE:
            return "Unexpected application state"
        case .E9002_NULL_POINTER:
            return "Unexpected nil value"
        case .E9003_SERIALIZATION_ERROR:
            return "Failed to serialize data"
        case .E9004_DESERIALIZATION_ERROR:
            return "Failed to deserialize data"
        case .E9005_CONFIGURATION_ERROR:
            return "Configuration error"
            
        // Warnings
        case .W1000_SLOW_CONNECTION:
            return "Slow connection detected"
        case .W1001_OFFLINE_MODE:
            return "Operating in offline mode"
        case .W1002_SYNC_PENDING:
            return "Synchronization pending"
        case .W2000_INCOMPLETE_DATA:
            return "Data is incomplete"
        case .W2001_DEPRECATED_FORMAT:
            return "Data format is deprecated"
        case .W2002_PARTIAL_SUCCESS:
            return "Operation partially succeeded"
        case .W3000_STALE_CACHE:
            return "Cache data is stale"
        case .W3001_PARTIAL_SYNC:
            return "Partial synchronization completed"
        case .W3002_DATA_TRUNCATED:
            return "Data was truncated"
        }
    }
    
    /// Returns the error category based on the code prefix
    var category: String {
        let codeString = code
        guard codeString.count > 1,
              let firstChar = codeString.first,
              let secondChar = codeString.dropFirst().first,
              secondChar.isNumber else {
            return "Unknown"
        }
        
        let categoryCode = Int(String(secondChar))
        
        if firstChar == "W" {
            return "Warning"
        }
        
        switch categoryCode {
        case 1: return "Network"
        case 2: return "Validation"
        case 3: return "Server"
        case 4: return "Authentication"
        case 5: return "Data"
        case 6: return "Database"
        case 9: return "System"
        default: return "Unknown"
        }
    }
    
    /// Returns whether this error type is typically retryable
    var isRetryable: Bool {
        switch self {
        case .E1000_NO_CONNECTION,
             .E1001_CONNECTION_TIMEOUT,
             .E1003_NETWORK_IO,
             .E3003_SERVICE_UNAVAILABLE,
             .E3004_RATE_LIMITED,
             .E3005_INTERNAL_SERVER_ERROR,
             .E3006_GATEWAY_TIMEOUT,
             .E5000_DATA_CONFLICT,
             .E5001_STALE_DATA:
            return true
        default:
            return false
        }
    }
}
