//
//  UserFormView.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import SwiftUI

/// User Form View for creating and editing users
struct UserFormView: View {
    @StateObject private var viewModel: UserFormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingError = false
    @State private var errorToShow: AppError?
    
    let onSave: (User) -> Void
    
    init(viewModel: UserFormViewModel, onSave: @escaping (User) -> Void = { _ in }) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                                get: { viewModel.state.firstName },
                                set: { viewModel.send(.updateFirstName($0)) }
                            ),
                            error: viewModel.state.firstNameError,
                            placeholder: "Enter first name",
                            keyboardType: .default
                        )

                        // Last Name
                        FormField(
                            title: "Last Name",
                            text: Binding(
                                get: { viewModel.state.lastName },
                                set: { viewModel.send(.updateLastName($0)) }
                            ),
                            error: viewModel.state.lastNameError,
                            placeholder: "Enter last name",
                            keyboardType: .default
                        )

                        // Email
                        FormField(
                            title: "Email",
                            text: Binding(
                                get: { viewModel.state.email },
                                set: { viewModel.send(.updateEmail($0)) }
                            ),
                            error: viewModel.state.emailError,
                            placeholder: "Enter email address",
                            keyboardType: .emailAddress
                        )

                        // Avatar URL (Optional)
                        FormField(
                            title: "Avatar URL (Optional)",
                            text: Binding(
                                get: { viewModel.state.avatar },
                                set: { viewModel.send(.updateAvatar($0)) }
                            ),
                            error: nil,
                            placeholder: "https://example.com/avatar.jpg",
                            keyboardType: .URL
                        )
                    }
                    .padding(.horizontal, ArcanaTheme.Spacing.md)
                    
                    // Submit button
                    Button(action: {
                        viewModel.send(.submit)
                    }) {
                        HStack {
                            if viewModel.state.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            
                            Text(viewModel.submitButtonTitle)
                                .font(ArcanaTheme.Typography.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            viewModel.state.isSaveEnabled && !viewModel.state.isLoading
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
                    .disabled(!viewModel.state.isSaveEnabled || viewModel.state.isLoading)
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
            }
        }
        .alert("Error", isPresented: $showingError, presenting: errorToShow) { error in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
        }
        .onReceive(viewModel.effects) { effect in
            handleEffect(effect)
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
        guard !viewModel.state.firstName.isEmpty || !viewModel.state.lastName.isEmpty else {
            return nil
        }
        return User(
            email: viewModel.state.email.isEmpty ? "preview@example.com" : viewModel.state.email,
            firstName: viewModel.state.firstName.isEmpty ? "F" : viewModel.state.firstName,
            lastName: viewModel.state.lastName.isEmpty ? "L" : viewModel.state.lastName,
            avatar: viewModel.state.avatar
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
