//
//  AppRoute.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import Foundation

/// All possible routes/destinations in the app
enum AppRoute: Hashable, Identifiable {
    case main
    case userList
    case userDetail(User)
    case userForm(mode: UserFormMode)
    case settings
    
    var id: String {
        switch self {
        case .main:
            return "main"
        case .userList:
            return "userList"
        case .userDetail(let user):
            return "userDetail_\(user.id)"
        case .userForm(let mode):
            return "userForm_\(mode.id)"
        case .settings:
            return "settings"
        }
    }
}

/// User form modes
enum UserFormMode: Hashable, Identifiable {
    case create
    case edit(User)
    
    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let user):
            return "edit_\(user.id)"
        }
    }
}

// MARK: - Route Extensions

extension AppRoute {
    /// Human-readable title for the route
    var title: String {
        switch self {
        case .main:
            return "Home"
        case .userList:
            return "Users"
        case .userDetail:
            return "User Details"
        case .userForm(let mode):
            switch mode {
            case .create:
                return "Create User"
            case .edit:
                return "Edit User"
            }
        case .settings:
            return "Settings"
        }
    }
    
    /// Analytics screen name
    var analyticsName: String {
        switch self {
        case .main:
            return "main_screen"
        case .userList:
            return "user_list_screen"
        case .userDetail:
            return "user_detail_screen"
        case .userForm(let mode):
            switch mode {
            case .create:
                return "user_create_screen"
            case .edit:
                return "user_edit_screen"
            }
        case .settings:
            return "settings_screen"
        }
    }
}
