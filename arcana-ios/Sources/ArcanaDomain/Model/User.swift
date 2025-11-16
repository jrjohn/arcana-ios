//
//  User.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation

/// Domain model for User matching reqres.in API structure
nonisolated struct User: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var email: String
    var firstName: String
    var lastName: String
    var avatar: String
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        email: String,
        firstName: String,
        lastName: String,
        avatar: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.avatar = avatar
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var initials: String {
        let first = firstName.prefix(1)
        let last = lastName.prefix(1)
        return "\(first)\(last)".uppercased()
    }
}

// MARK: - Hashable Conformance
// Custom implementation to avoid navigation issues with Date comparison
extension User: Hashable {
    nonisolated func hash(into hasher: inout Hasher) {
        // Only hash the id for navigation purposes
        // This prevents issues with Date comparison in NavigationStack
        hasher.combine(id)
    }

    nonisolated static func == (lhs: User, rhs: User) -> Bool {
        // For equality, we only compare the id
        // This ensures navigation works properly even if other fields change
        lhs.id == rhs.id
    }
}

// MARK: - Mock Data
extension User {
    static func mock(
        id: String = UUID().uuidString,
        email: String = "john.doe@example.com",
        firstName: String = "John",
        lastName: String = "Doe",
        avatar: String = "https://reqres.in/img/faces/1-image.jpg",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> User {
        User(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            avatar: avatar,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    static var mockUsers: [User] {
        let now = Date()
        return [
            User(id: "1", email: "alice.smith@reqres.in", firstName: "Alice", lastName: "Smith", avatar: "https://reqres.in/img/faces/1-image.jpg", createdAt: now, updatedAt: now),
            User(id: "2", email: "bob.johnson@reqres.in", firstName: "Bob", lastName: "Johnson", avatar: "https://reqres.in/img/faces/2-image.jpg", createdAt: now, updatedAt: now),
            User(id: "3", email: "carol.williams@reqres.in", firstName: "Carol", lastName: "Williams", avatar: "https://reqres.in/img/faces/3-image.jpg", createdAt: now, updatedAt: now),
            User(id: "4", email: "david.brown@reqres.in", firstName: "David", lastName: "Brown", avatar: "https://reqres.in/img/faces/4-image.jpg", createdAt: now, updatedAt: now),
            User(id: "5", email: "eve.davis@reqres.in", firstName: "Eve", lastName: "Davis", avatar: "https://reqres.in/img/faces/5-image.jpg", createdAt: now, updatedAt: now)
        ]
    }
}

// MARK: - DTO
extension User {
    /// Data Transfer Object for API communication (reqres.in format)
    struct DTO: Codable {
        let id: Int?
        let email: String
        let firstName: String
        let lastName: String
        let avatar: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case email
            case firstName = "first_name"
            case lastName = "last_name"
            case avatar
        }
    }
    
    /// Convert to DTO (for API requests)
    func toDTO() -> DTO {
        DTO(
            id: Int(id),
            email: email,
            firstName: firstName,
            lastName: lastName,
            avatar: avatar.isEmpty ? nil : avatar
        )
    }
    
    /// Create from DTO (from API responses)
    static func from(dto: DTO) throws -> User {
        User(
            id: dto.id.map(String.init) ?? UUID().uuidString,
            email: dto.email,
            firstName: dto.firstName,
            lastName: dto.lastName,
            avatar: dto.avatar ?? "",
            createdAt: Date(),  // API doesn't provide these, use current date
            updatedAt: Date()
        )
    }
}
