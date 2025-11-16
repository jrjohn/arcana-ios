//
//  UserEntity.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation
import SwiftData

/// SwiftData model for persisting User data
@Model
final class UserEntity {
    @Attribute(.unique) var id: String
    var firstName: String
    var lastName: String
    var email: String
    var avatar: String
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String,
        firstName: String,
        lastName: String,
        email: String,
        avatar: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.avatar = avatar
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Convert to domain model
    func toDomain() -> User {
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
    
    /// Create from domain model
    static func from(user: User) -> UserEntity {
        UserEntity(
            id: user.id,
            firstName: user.firstName,
            lastName: user.lastName,
            email: user.email,
            avatar: user.avatar,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt
        )
    }
    
    /// Update from domain model
    func update(from user: User) {
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.email = user.email
        self.avatar = user.avatar
        self.updatedAt = user.updatedAt
    }
}
