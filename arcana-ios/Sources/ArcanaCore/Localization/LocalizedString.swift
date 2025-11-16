//
//  LocalizedString.swift
//  arcana-ios
//
//  Internationalization infrastructure for localized strings
//

import SwiftUI

/// Extension to String for convenient localization
extension String {
    /// Returns the localized version of this string
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Returns the localized version with interpolated arguments
    func localized(_ args: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: args)
    }
}

/// Centralized localization keys for type-safe access
enum L10n {
    // MARK: - Common
    enum Common {
        static let ok = "common.ok"
        static let cancel = "common.cancel"
        static let save = "common.save"
        static let delete = "common.delete"
        static let edit = "common.edit"
        static let add = "common.add"
        static let create = "common.create"
        static let update = "common.update"
        static let refresh = "common.refresh"
        static let loading = "common.loading"
        static let error = "common.error"
        static let retry = "common.retry"
        static let close = "common.close"
        static let done = "common.done"
        static let back = "common.back"
    }

    // MARK: - Main Screen
    enum Main {
        static let title = "main.title"
        static let subtitle = "main.subtitle"
        static let manageUsers = "main.manage_users"
        static let welcomeMessage = "main.welcome_message"
    }

    // MARK: - User List
    enum UserList {
        static let title = "user_list.title"
        static let searchPlaceholder = "user_list.search_placeholder"
        static let emptyState = "user_list.empty_state"
        static let emptyStateMessage = "user_list.empty_state_message"
        static let offlineMode = "user_list.offline_mode"
        static let syncPending = "user_list.sync_pending"
        static let syncNow = "user_list.sync_now"
        static let deleteConfirmTitle = "user_list.delete_confirm_title"
        static let deleteConfirmMessage = "user_list.delete_confirm_message"
        static let totalUsers = "user_list.total_users"
        static let page = "user_list.page"
    }

    // MARK: - User Form
    enum UserForm {
        static let createTitle = "user_form.create_title"
        static let editTitle = "user_form.edit_title"
        static let createButton = "user_form.create_button"
        static let saveButton = "user_form.save_button"

        static let firstNameLabel = "user_form.first_name_label"
        static let firstNamePlaceholder = "user_form.first_name_placeholder"

        static let lastNameLabel = "user_form.last_name_label"
        static let lastNamePlaceholder = "user_form.last_name_placeholder"

        static let emailLabel = "user_form.email_label"
        static let emailPlaceholder = "user_form.email_placeholder"

        static let avatarLabel = "user_form.avatar_label"
        static let avatarPlaceholder = "user_form.avatar_placeholder"
    }

    // MARK: - Validation Errors
    enum Validation {
        static let firstNameRequired = "validation.first_name_required"
        static let lastNameRequired = "validation.last_name_required"
        static let emailRequired = "validation.email_required"
        static let emailInvalid = "validation.email_invalid"
    }

    // MARK: - Network Errors
    enum NetworkError {
        static let noConnection = "network_error.no_connection"
        static let timeout = "network_error.timeout"
        static let serverError = "network_error.server_error"
        static let notFound = "network_error.not_found"
        static let unauthorized = "network_error.unauthorized"
        static let unknown = "network_error.unknown"
    }

    // MARK: - Analytics Events
    enum Analytics {
        static let userCreated = "analytics.user_created"
        static let userUpdated = "analytics.user_updated"
        static let userDeleted = "analytics.user_deleted"
        static let screenViewed = "analytics.screen_viewed"
    }
}

/// Helper to get localized string with type-safe keys
func localizedString(_ key: String, comment: String = "") -> String {
    NSLocalizedString(key, comment: comment)
}

/// Helper for localized strings with arguments
func localizedString(_ key: String, _ args: CVarArg..., comment: String = "") -> String {
    String(format: NSLocalizedString(key, comment: comment), arguments: args)
}
