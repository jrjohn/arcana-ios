//
//  UserFormView.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import SwiftUI

/// User Form View for creating and editing users
struct UserFormView: View {
    @State private var viewModel: UserFormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingError = false
    @State private var errorToShow: AppError?

    let onSave: (User) -> Void

    init(viewModel: UserFormViewModel, onSave: @escaping (User) -> Void = { _ in }) {
        _viewModel = State(wrappedValue: viewModel)
        self.onSave = onSave
    }
    
    var body: some View {
        ZStack {
            // Background
            ArcanaTheme.Colors.backgroundLight
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: ArcanaTheme.Spacing.lg) {
                    // Header
                    headerView
                    
                    // Form fields
                    VStack(spacing: ArcanaTheme.Spacing.md) {
                        // First Name
                        FormField(
                            title: "First Name",
                            text: Binding(
                                get: { viewModel.output.user.firstName },
                                set: { newValue in
                                    Task {
                                        _ = await viewModel.input(.updateFirstName(newValue))
                                    }
                                }
                            ),
                            error: viewModel.output.validationErrors.firstNameError,
                            placeholder: "Enter first name",
                            keyboardType: .default
                        )
                        .accessibilityIdentifier("FirstNameField")

                        // Last Name
                        FormField(
                            title: "Last Name",
                            text: Binding(
                                get: { viewModel.output.user.lastName },
                                set: { newValue in
                                    Task {
                                        _ = await viewModel.input(.updateLastName(newValue))
                                    }
                                }
                            ),
                            error: viewModel.output.validationErrors.lastNameError,
                            placeholder: "Enter last name",
                            keyboardType: .default
                        )
                        .accessibilityIdentifier("LastNameField")

                        // Email
                        FormField(
                            title: "Email",
                            text: Binding(
                                get: { viewModel.output.user.email },
                                set: { newValue in
                                    Task {
                                        _ = await viewModel.input(.updateEmail(newValue))
                                    }
                                }
                            ),
                            error: viewModel.output.validationErrors.emailError,
                            placeholder: "Enter email address",
                            keyboardType: .emailAddress
                        )
                        .accessibilityIdentifier("EmailField")

                        // Avatar URL (Optional)
                        FormField(
                            title: "Avatar URL (Optional)",
                            text: Binding(
                                get: { viewModel.output.user.avatar },
                                set: { newValue in
                                    Task {
                                        _ = await viewModel.input(.updateAvatar(newValue))
                                    }
                                }
                            ),
                            error: nil,
                            placeholder: "https://example.com/avatar.jpg",
                            keyboardType: .URL
                        )
                        .accessibilityIdentifier("AvatarField")
                    }
                    .padding(.horizontal, ArcanaTheme.Spacing.md)
                    
                    // Submit button
                    Button(action: {
                        Task {
                            if let effect = await viewModel.input(.submit) {
                                handleEffect(effect)
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.output.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }

                            Text(viewModel.submitButtonTitle)
                                .font(ArcanaTheme.Typography.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            viewModel.output.isSaveEnabled && !viewModel.output.isLoading
                                ? ArcanaTheme.Colors.primaryGradient
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(ArcanaTheme.CornerRadius.medium)
                    }
                    .accessibilityIdentifier("SubmitButton")
                    .accessibilityLabel(viewModel.submitButtonTitle)
                    .disabled(!viewModel.output.isSaveEnabled || viewModel.output.isLoading)
                    .padding(.horizontal, ArcanaTheme.Spacing.md)
                    .padding(.top, ArcanaTheme.Spacing.md)
                }
                .padding(.vertical, ArcanaTheme.Spacing.lg)
            }
        }
        .navigationTitle(viewModel.formTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .accessibilityIdentifier("CancelButton")
            }
        }
        .alert("Error", isPresented: $showingError, presenting: errorToShow) { error in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: ArcanaTheme.Spacing.sm) {
            // Show avatar preview
            if let previewUser = createPreviewUser() {
                AvatarView(user: previewUser, size: 80)
            } else {
                Circle()
                    .fill(ArcanaTheme.Colors.primaryGradient)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
            }

            Text(viewModel.formTitle)
                .font(ArcanaTheme.Typography.title2)
                .foregroundColor(ArcanaTheme.Colors.textPrimary)
        }
        .padding(.top, ArcanaTheme.Spacing.md)
    }

    private func createPreviewUser() -> User? {
        guard !viewModel.output.user.firstName.isEmpty || !viewModel.output.user.lastName.isEmpty else {
            return nil
        }
        return User(
            email: viewModel.output.user.email.isEmpty ? "preview@example.com" : viewModel.output.user.email,
            firstName: viewModel.output.user.firstName.isEmpty ? "F" : viewModel.output.user.firstName,
            lastName: viewModel.output.user.lastName.isEmpty ? "L" : viewModel.output.user.lastName,
            avatar: viewModel.output.user.avatar
        )
    }
    
    // MARK: - Effect Handling
    
    private func handleEffect(_ effect: UserFormViewModel.Effect) {
        switch effect {
        case .showError(let error):
            errorToShow = error
            showingError = true
            
        case .dismiss(let user):
            if let user = user {
                onSave(user)
            }
            dismiss()
        }
    }
}

// MARK: - Form Field Component
struct FormField: View {
    let title: String
    @Binding var text: String
    let error: String?
    let placeholder: String
    let keyboardType: UIKeyboardType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(ArcanaTheme.Typography.callout)
                .fontWeight(.semibold)
                .foregroundColor(ArcanaTheme.Colors.textPrimary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(ArcanaTheme.Typography.body)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: ArcanaTheme.CornerRadius.small)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ArcanaTheme.CornerRadius.small)
                        .stroke(error != nil ? ArcanaTheme.Colors.accentRed : Color.clear, lineWidth: 1)
                )
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
            
            if let error = error {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(error)
                        .font(ArcanaTheme.Typography.caption2)
                }
                .foregroundColor(ArcanaTheme.Colors.accentRed)
            }
        }
    }
}

// MARK: - Preview
#Preview("Create Mode") {
    AppDependencies.withPreviewDependencies {
        NavigationStack {
            UserFormView(
                viewModel: UserFormViewModel(mode: .create)
            )
        }
    }
}

#Preview("Edit Mode") {
    AppDependencies.withPreviewDependencies {
        NavigationStack {
            UserFormView(
                viewModel: UserFormViewModel(mode: .edit(User.mock()))
            )
        }
    }
}

// MARK: - Preview Mocks
private class PreviewUserService: UserService {
    func getUsers() async throws -> [User] { [] }
    func getUsers(page: Int, perPage: Int) async throws -> PaginatedResult<User> {
        PaginatedResult(items: [], currentPage: 1, totalPages: 1, hasMore: false)
    }
    func getUser(id: String) async throws -> User { User.mock() }
    func createUser(_ user: User) async throws -> User { user }
    func updateUser(_ user: User) async throws -> User { user }
    func deleteUser(_ user: User) async throws { }
    func searchUsers(query: String) async throws -> [User] { [] }
    func refreshUsers() async throws -> [User] { [] }
}

private class PreviewAnalyticsTracker: AnalyticsTracker {
    var sessionId: String = UUID().uuidString
    func trackEvent(_ event: AnalyticsEvent, params: [String: Any]) { }
    func trackScreen(_ screen: String, params: [String: Any]) { }
    func trackError(_ error: Error, context: [String: Any]) { }
    func trackAppError(_ appError: AppError, context: [String: Any]) { }
}
