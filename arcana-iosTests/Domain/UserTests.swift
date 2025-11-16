//
//  UserTests.swift
//  arcana-iosTests
//
//  Created by Claude Code
//

import Testing
import Foundation
@testable import arcana_ios

/// Comprehensive tests for User domain model
struct UserTests {

    // MARK: - Initialization Tests

    @Test("User initialization with all parameters")
    func testUserInitialization() {
        let id = "123"
        let email = "test@example.com"
        let firstName = "John"
        let lastName = "Doe"
        let avatar = "https://example.com/avatar.jpg"
        let createdAt = Date()
        let updatedAt = Date()

        let user = User(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            avatar: avatar,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        #expect(user.id == id)
        #expect(user.email == email)
        #expect(user.firstName == firstName)
        #expect(user.lastName == lastName)
        #expect(user.avatar == avatar)
        #expect(user.createdAt == createdAt)
        #expect(user.updatedAt == updatedAt)
    }

    @Test("User initialization with default values")
    func testUserInitializationWithDefaults() {
        let user = User(
            email: "test@example.com",
            firstName: "John",
            lastName: "Doe"
        )

        #expect(!user.id.isEmpty)
        #expect(user.avatar.isEmpty)
        #expect(user.createdAt <= Date())
        #expect(user.updatedAt <= Date())
    }

    // MARK: - Computed Property Tests

    @Test("fullName returns correct concatenation")
    func testFullName() {
        let user = User(email: "test@example.com", firstName: "John", lastName: "Doe")
        #expect(user.fullName == "John Doe")
    }

    @Test("initials returns correct uppercase initials")
    func testInitials() {
        let user = User(email: "test@example.com", firstName: "John", lastName: "Doe")
        #expect(user.initials == "JD")
    }

    @Test("initials with single character names")
    func testInitialsSingleChar() {
        let user = User(email: "test@example.com", firstName: "A", lastName: "B")
        #expect(user.initials == "AB")
    }

    @Test("initials with lowercase names")
    func testInitialsLowercase() {
        let user = User(email: "test@example.com", firstName: "john", lastName: "doe")
        #expect(user.initials == "JD")
    }

    // MARK: - Equality Tests

    @Test("Users with same ID are equal")
    func testEqualityS ameId() {
        let id = "123"
        let user1 = User(id: id, email: "email1@example.com", firstName: "John", lastName: "Doe")
        let user2 = User(id: id, email: "email2@example.com", firstName: "Jane", lastName: "Smith")

        #expect(user1 == user2)
    }

    @Test("Users with different IDs are not equal")
    func testInequalityDifferentId() {
        let user1 = User(id: "1", email: "test@example.com", firstName: "John", lastName: "Doe")
        let user2 = User(id: "2", email: "test@example.com", firstName: "John", lastName: "Doe")

        #expect(user1 != user2)
    }

    // MARK: - Hashable Tests

    @Test("Users with same ID have same hash")
    func testHashSameId() {
        let id = "123"
        let user1 = User(id: id, email: "email1@example.com", firstName: "John", lastName: "Doe")
        let user2 = User(id: id, email: "email2@example.com", firstName: "Jane", lastName: "Smith")

        #expect(user1.hashValue == user2.hashValue)
    }

    @Test("Users can be used in Set")
    func testUsersInSet() {
        let user1 = User(id: "1", email: "test1@example.com", firstName: "John", lastName: "Doe")
        let user2 = User(id: "2", email: "test2@example.com", firstName: "Jane", lastName: "Smith")
        let user3 = User(id: "1", email: "test3@example.com", firstName: "Bob", lastName: "Johnson")

        let userSet: Set<User> = [user1, user2, user3]
        #expect(userSet.count == 2) // user1 and user3 have same ID
    }

    // MARK: - Codable Tests

    @Test("User can be encoded to JSON")
    func testEncoding() throws {
        let user = User(
            id: "123",
            email: "test@example.com",
            firstName: "John",
            lastName: "Doe",
            avatar: "https://example.com/avatar.jpg"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(user)

        #expect(!data.isEmpty)
    }

    @Test("User can be decoded from JSON")
    func testDecoding() throws {
        let json = """
        {
            "id": "123",
            "email": "test@example.com",
            "firstName": "John",
            "lastName": "Doe",
            "avatar": "https://example.com/avatar.jpg",
            "createdAt": 0,
            "updatedAt": 0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let user = try decoder.decode(User.self, from: json)

        #expect(user.id == "123")
        #expect(user.email == "test@example.com")
        #expect(user.firstName == "John")
        #expect(user.lastName == "Doe")
    }

    // MARK: - DTO Tests

    @Test("User converts to DTO correctly")
    func testToDTO() {
        let user = User(
            id: "123",
            email: "test@example.com",
            firstName: "John",
            lastName: "Doe",
            avatar: "https://example.com/avatar.jpg"
        )

        let dto = user.toDTO()

        #expect(dto.id == 123)
        #expect(dto.email == "test@example.com")
        #expect(dto.firstName == "John")
        #expect(dto.lastName == "Doe")
        #expect(dto.avatar == "https://example.com/avatar.jpg")
    }

    @Test("User with empty avatar converts to DTO with nil avatar")
    func testToDTOEmptyAvatar() {
        let user = User(
            id: "123",
            email: "test@example.com",
            firstName: "John",
            lastName: "Doe",
            avatar: ""
        )

        let dto = user.toDTO()
        #expect(dto.avatar == nil)
    }

    @Test("User created from DTO")
    func testFromDTO() throws {
        let dto = User.DTO(
            id: 123,
            email: "test@example.com",
            firstName: "John",
            lastName: "Doe",
            avatar: "https://example.com/avatar.jpg"
        )

        let user = try User.from(dto: dto)

        #expect(user.id == "123")
        #expect(user.email == "test@example.com")
        #expect(user.firstName == "John")
        #expect(user.lastName == "Doe")
        #expect(user.avatar == "https://example.com/avatar.jpg")
    }

    @Test("User created from DTO without ID generates UUID")
    func testFromDTOWithoutID() throws {
        let dto = User.DTO(
            id: nil,
            email: "test@example.com",
            firstName: "John",
            lastName: "Doe",
            avatar: nil
        )

        let user = try User.from(dto: dto)

        #expect(!user.id.isEmpty)
        #expect(user.email == "test@example.com")
        #expect(user.avatar.isEmpty)
    }

    // MARK: - Mock Data Tests

    @Test("Mock user has correct default values")
    func testMockUser() {
        let user = User.mock()

        #expect(!user.id.isEmpty)
        #expect(user.email == "john.doe@example.com")
        #expect(user.firstName == "John")
        #expect(user.lastName == "Doe")
        #expect(!user.avatar.isEmpty)
    }

    @Test("Mock user can be customized")
    func testMockUserCustom() {
        let customEmail = "custom@example.com"
        let user = User.mock(email: customEmail, firstName: "Alice")

        #expect(user.email == customEmail)
        #expect(user.firstName == "Alice")
    }

    @Test("Mock users returns array of users")
    func testMockUsers() {
        let users = User.mockUsers

        #expect(users.count == 5)
        #expect(users[0].firstName == "Alice")
        #expect(users[1].firstName == "Bob")
        #expect(users[2].firstName == "Carol")
        #expect(users[3].firstName == "David")
        #expect(users[4].firstName == "Eve")
    }

    // MARK: - Sendable Conformance Tests

    @Test("User is Sendable")
    func testSendableConformance() {
        let user = User.mock()

        Task {
            let _ = user // Should compile without warnings
        }
    }
}
