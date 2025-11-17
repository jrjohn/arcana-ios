//
//  NetworkLogger.swift
//  arcana-ios
//
//  Created by John on 2025/11/17.
//

import Foundation
import Alamofire
import os.log

/// Log level for network requests
enum NetworkLogLevel: String {
    case verbose
    case info
    case error
    case none

    var shouldLog: Bool {
        self != .none
    }
}

/// Configuration for network logging
struct NetworkLoggerConfiguration {
    let enabled: Bool
    let logHeaders: Bool
    let logBody: Bool
    let logLevel: NetworkLogLevel

    static let `default` = NetworkLoggerConfiguration(
        enabled: true,
        logHeaders: true,
        logBody: true,
        logLevel: .verbose
    )

    static let production = NetworkLoggerConfiguration(
        enabled: false,
        logHeaders: false,
        logBody: false,
        logLevel: .error
    )
}

/// Network interceptor that logs requests and responses
final class NetworkLogger: EventMonitor {

    // MARK: - Properties

    private let configuration: NetworkLoggerConfiguration
    private let logger = Logger(subsystem: "com.arcana.ios", category: "Network")

    // MARK: - Initialization

    init(configuration: NetworkLoggerConfiguration) {
        self.configuration = configuration
    }

    // MARK: - EventMonitor

    let queue = DispatchQueue(label: "com.arcana.network.logger", qos: .utility)

    // MARK: - Request Logging

    func requestDidResume(_ request: Request) {
        guard configuration.enabled, configuration.logLevel.shouldLog else { return }

        guard let urlRequest = request.request else { return }

        logRequest(urlRequest)
    }

    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        guard configuration.enabled, configuration.logLevel.shouldLog else { return }

        logResponse(response)
    }

    // MARK: - Private Methods

    private func logRequest(_ request: URLRequest) {
        var logMessage = "\n🚀 REQUEST"
        logMessage += "\n├─ URL: \(request.url?.absoluteString ?? "N/A")"
        logMessage += "\n├─ Method: \(request.httpMethod ?? "N/A")"

        // Log headers
        if configuration.logHeaders, let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logMessage += "\n├─ Headers:"
            for (key, value) in headers {
                logMessage += "\n│  ├─ \(key): \(sanitizeHeaderValue(key: key, value: value))"
            }
        }

        // Log body
        if configuration.logBody, let body = request.httpBody {
            if let jsonObject = try? JSONSerialization.jsonObject(with: body),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                logMessage += "\n└─ Body:\n\(prettyString)"
            } else if let bodyString = String(data: body, encoding: .utf8) {
                logMessage += "\n└─ Body:\n\(bodyString)"
            } else {
                logMessage += "\n└─ Body: <\(body.count) bytes>"
            }
        } else {
            logMessage += "\n└─ Body: None"
        }

        log(logMessage, level: .info)
    }

    private func logResponse<Value>(_ response: DataResponse<Value, AFError>) {
        var logMessage = "\n📥 RESPONSE"

        if let urlResponse = response.response {
            logMessage += "\n├─ URL: \(urlResponse.url?.absoluteString ?? "N/A")"
            logMessage += "\n├─ Status Code: \(urlResponse.statusCode)"

            let statusEmoji: String
            switch urlResponse.statusCode {
            case 200...299:
                statusEmoji = "✅"
            case 300...399:
                statusEmoji = "↩️"
            case 400...499:
                statusEmoji = "⚠️"
            case 500...599:
                statusEmoji = "❌"
            default:
                statusEmoji = "❓"
            }
            logMessage += " \(statusEmoji)"

            // Log headers
            if configuration.logHeaders {
                logMessage += "\n├─ Headers:"
                for (key, value) in urlResponse.allHeaderFields {
                    logMessage += "\n│  ├─ \(key): \(value)"
                }
            }
        }

        // Log timing
        if let metrics = response.metrics {
            let duration = metrics.taskInterval.duration
            logMessage += "\n├─ Duration: \(String(format: "%.3f", duration))s"
        }

        // Log body
        if configuration.logBody, let data = response.data {
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                logMessage += "\n└─ Body:\n\(prettyString)"
            } else if let bodyString = String(data: data, encoding: .utf8) {
                logMessage += "\n└─ Body:\n\(bodyString)"
            } else {
                logMessage += "\n└─ Body: <\(data.count) bytes>"
            }
        }

        // Log error if present
        if let error = response.error {
            logMessage += "\n└─ Error: \(error.localizedDescription)"
        }

        // Determine log level based on status code
        let logLevel: OSLogType
        if let statusCode = response.response?.statusCode {
            switch statusCode {
            case 200...299:
                logLevel = .info
            case 400...499:
                logLevel = .error
            case 500...599:
                logLevel = .fault
            default:
                logLevel = .default
            }
        } else {
            logLevel = .error
        }

        log(logMessage, level: logLevel)
    }

    private func sanitizeHeaderValue(key: String, value: String) -> String {
        let sensitiveHeaders = ["Authorization", "Cookie", "Set-Cookie", "X-API-Key", "API-Key"]

        if sensitiveHeaders.contains(where: { key.caseInsensitiveCompare($0) == .orderedSame }) {
            return "***REDACTED***"
        }

        return value
    }

    private func log(_ message: String, level: OSLogType) {
        let shouldLog: Bool
        switch configuration.logLevel {
        case .verbose:
            shouldLog = true
        case .info:
            shouldLog = level != .debug && level != .default
        case .error:
            shouldLog = level == .error || level == .fault
        case .none:
            shouldLog = false
        }

        if shouldLog {
            logger.log(level: level, "\(message)")
        }

        // Also print to console in debug builds
        #if DEBUG
        if shouldLog {
            print(message)
        }
        #endif
    }
}

// MARK: - AppConfiguration Extension

extension NetworkLoggerConfiguration {
    init(from config: AppConfiguration) {
        self.enabled = config.logging.enabled
        self.logHeaders = config.logging.logHeaders
        self.logBody = config.logging.logBody

        switch config.logging.logLevel.lowercased() {
        case "verbose", "debug":
            self.logLevel = .verbose
        case "info":
            self.logLevel = .info
        case "error", "warning":
            self.logLevel = .error
        default:
            self.logLevel = .none
        }
    }
}
