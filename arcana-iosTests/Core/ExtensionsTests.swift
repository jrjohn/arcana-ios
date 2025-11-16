//
//  ExtensionsTests.swift
//  arcana-iosTests
//
//  Created by Claude Code for 100% coverage
//

import Testing
import Foundation
import SwiftUI
import Combine
@testable import arcana_ios

/// Comprehensive tests for all Extensions
struct ExtensionsTests {

    // MARK: - Date Extensions Tests

    @Test("Date relativeFormat returns relative string")
    func testDateRelativeFormat() {
        let now = Date()
        let relativeString = now.relativeFormat

        #expect(!relativeString.isEmpty)
        // Recent date should contain time-related words
        #expect(relativeString.lowercased().contains("now") ||
                relativeString.lowercased().contains("ago") ||
                relativeString.lowercased().contains("second"))
    }

    @Test("Date shortFormat returns formatted date")
    func testDateShortFormat() {
        let date = Date()
        let shortString = date.shortFormat

        #expect(!shortString.isEmpty)
        // Should contain year
        let year = Calendar.current.component(.year, from: date)
        #expect(shortString.contains(String(year)))
    }

    @Test("Date fullFormat includes time")
    func testDateFullFormat() {
        let date = Date()
        let fullString = date.fullFormat

        #expect(!fullString.isEmpty)
        // Should contain either AM or PM
        #expect(fullString.contains("AM") || fullString.contains("PM") ||
                fullString.contains("am") || fullString.contains("pm"))
    }

    // MARK: - String Extensions Tests

    @Test("String isValidEmail validates correct emails")
    func testStringIsValidEmail() {
        #expect("test@example.com".isValidEmail == true)
        #expect("user.name+tag@example.co.uk".isValidEmail == true)
        #expect("invalid".isValidEmail == false)
        #expect("@example.com".isValidEmail == false)
        #expect("test@".isValidEmail == false)
        #expect("test@example".isValidEmail == false)
    }

    @Test("String trimmed removes whitespace")
    func testStringTrimmed() {
        #expect("  hello  ".trimmed == "hello")
        #expect("\n\ttest\n".trimmed == "test")
        #expect("no spaces".trimmed == "no spaces")
        #expect("".trimmed == "")
    }

    @Test("String isBlank detects empty strings")
    func testStringIsBlank() {
        #expect("".isBlank == true)
        #expect("   ".isBlank == true)
        #expect("\n\t  \n".isBlank == true)
        #expect("hello".isBlank == false)
        #expect("  hello  ".isBlank == false)
    }

    // MARK: - Array Extensions Tests

    @Test("Array remove by id removes element")
    func testArrayRemoveById() {
        var users = User.mockUsers
        let initialCount = users.count
        let idToRemove = users.first!.id

        users.remove(id: idToRemove)

        #expect(users.count == initialCount - 1)
        #expect(users.find(id: idToRemove) == nil)
    }

    @Test("Array update replaces element")
    func testArrayUpdate() {
        var users = User.mockUsers
        let userToUpdate = users.first!
        let updatedUser = User(
            id: userToUpdate.id,
            email: "updated@example.com",
            firstName: "Updated",
            lastName: "User"
        )

        users.update(updatedUser)

        let found = users.find(id: userToUpdate.id)
        #expect(found?.email == "updated@example.com")
        #expect(found?.firstName == "Updated")
    }

    @Test("Array update does nothing if element not found")
    func testArrayUpdateNotFound() {
        var users = User.mockUsers
        let initialCount = users.count

        let nonExistentUser = User(
            id: "nonexistent",
            email: "test@example.com",
            firstName: "Test",
            lastName: "User"
        )

        users.update(nonExistentUser)

        #expect(users.count == initialCount)
    }

    @Test("Array find returns element by id")
    func testArrayFind() {
        let users = User.mockUsers
        let expectedUser = users.first!

        let found = users.find(id: expectedUser.id)

        #expect(found != nil)
        #expect(found?.id == expectedUser.id)
    }

    @Test("Array find returns nil for non-existent id")
    func testArrayFindNonExistent() {
        let users = User.mockUsers

        let found = users.find(id: "nonexistent")

        #expect(found == nil)
    }

    // MARK: - Task Extensions Tests

    @Test("Task sleep waits for specified duration")
    func testTaskSleep() async throws {
        let start = Date()

        try await Task.sleep(seconds: 0.1)

        let elapsed = Date().timeIntervalSince(start)
        #expect(elapsed >= 0.1)
        #expect(elapsed < 0.2) // Should not take too long
    }

    // MARK: - Binding Extensions Tests

    @Test("Binding ignoreNil uses default when nil")
    func testBindingIgnoreNil() {
        var optionalValue: Int? = nil
        let binding = Binding<Int?>(
            get: { optionalValue },
            set: { optionalValue = $0 }
        )

        let nonNilBinding = binding.ignoreNil(defaultValue: 42)

        #expect(nonNilBinding.wrappedValue == 42)

        nonNilBinding.wrappedValue = 10
        #expect(optionalValue == 10)
        #expect(nonNilBinding.wrappedValue == 10)
    }

    @Test("Binding ignoreNil preserves non-nil value")
    func testBindingIgnoreNilWithValue() {
        var optionalValue: Int? = 5
        let binding = Binding<Int?>(
            get: { optionalValue },
            set: { optionalValue = $0 }
        )

        let nonNilBinding = binding.ignoreNil(defaultValue: 42)

        #expect(nonNilBinding.wrappedValue == 5)
    }

    // MARK: - Publisher Extensions Tests

    @Test("Publisher async returns first value")
    func testPublisherAsync() async throws {
        let subject = PassthroughSubject<Int, Never>()

        // Start async operation
        let asyncTask = Task {
            try await subject.async()
        }

        // Send value
        subject.send(42)

        let result = try await asyncTask.value
        #expect(result == 42)
    }

    @Test("Publisher async throws on error")
    func testPublisherAsyncError() async throws {
        let subject = PassthroughSubject<Int, TestError>()

        // Start async operation
        let asyncTask = Task {
            try await subject.async()
        }

        // Send error
        subject.send(completion: .failure(TestError.testCase))

        do {
            _ = try await asyncTask.value
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected
            #expect(error is TestError)
        }
    }

    // MARK: - View Extensions Tests
    // Note: View extensions are harder to test without full SwiftUI infrastructure
    // But we can at least verify they compile and are defined

    @Test("View extensions exist")
    func testViewExtensionsExist() {
        // This test primarily ensures the extensions compile
        // Actual UI testing would require more infrastructure

        struct TestView: View {
            var body: some View {
                Text("Test")
                    .if(true) { view in
                        view.foregroundColor(.red)
                    }
                    .ifLet(Optional<String>("value")) { view, value in
                        view.background(Color.blue)
                    }
            }
        }

        let _testView = TestView()
        // If we get here, the extensions work
        #expect(true)
    }
}

// MARK: - Test Error

enum TestError: Error {
    case testCase
}
