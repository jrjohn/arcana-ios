//
//  Extensions.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation
import SwiftUI

// MARK: - Date Extensions
extension Date {
    /// Format date as relative time (e.g., "2 hours ago")
    var relativeFormat: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Format date as short string (e.g., "Nov 15, 2025")
    var shortFormat: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Format date with time (e.g., "Nov 15, 2025 at 3:45 PM")
    var fullFormat: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions
extension String {
    /// Check if string is a valid email
    var isValidEmail: Bool {
        let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Trim whitespace and newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Check if string is empty after trimming
    var isBlank: Bool {
        trimmed.isEmpty
    }
}

// MARK: - Array Extensions
extension Array where Element: Identifiable {
    /// Remove element by ID
    mutating func remove(id: Element.ID) {
        removeAll { $0.id == id }
    }
    
    /// Update element by ID
    mutating func update(_ element: Element) {
        if let index = firstIndex(where: { $0.id == element.id }) {
            self[index] = element
        }
    }
    
    /// Find element by ID
    func find(id: Element.ID) -> Element? {
        first { $0.id == id }
    }
}

// MARK: - Task Extensions
extension Task where Success == Never, Failure == Never {
    /// Sleep for a duration in seconds
    static func sleep(seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

// MARK: - View Extensions
extension View {
    /// Conditionally apply a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Apply a modifier if optional value is not nil
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Binding Extensions
extension Binding {
    /// Create a binding that ignores nil values
    func ignoreNil<T>(defaultValue: T) -> Binding<T> where Value == T? {
        Binding<T>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

// MARK: - Publisher Extensions (for Combine)
import Combine

extension Publisher {
    /// Async await wrapper for publishers
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = first()
                .sink { completion in
                    if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    continuation.resume(returning: value)
                }
        }
    }
}
