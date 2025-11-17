//
//  NavGraph.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import SwiftUI
import Observation
import Dependencies

/// Navigation coordinator/router for the entire app
/// Manages navigation stack and routing logic
@MainActor
@Observable
final class NavGraph {
    
    // MARK: - Properties
    
    /// Navigation path - the stack of routes
    var path: [AppRoute] = []
    
    /// Currently presented sheet route
    var presentedSheet: AppRoute?
    
    /// Currently presented full screen cover
    var presentedFullScreenCover: AppRoute?
    
    /// Alert to show
    var alertToShow: AlertConfig?
    
    // MARK: - Navigation Methods
    
    /// Push a new route onto the navigation stack
    func push(_ route: AppRoute) {
        path.append(route)
        trackNavigation(to: route)
    }
    
    /// Pop the current route from the navigation stack
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    /// Pop to root (clear the entire stack)
    func popToRoot() {
        path.removeAll()
    }
    
    /// Pop to a specific route
    func popTo(_ route: AppRoute) {
        guard let index = path.firstIndex(of: route) else { return }
        path = Array(path.prefix(through: index))
    }
    
    /// Present a sheet
    func presentSheet(_ route: AppRoute) {
        presentedSheet = route
        trackNavigation(to: route)
    }
    
    /// Dismiss the current sheet
    func dismissSheet() {
        presentedSheet = nil
    }
    
    /// Present a full screen cover
    func presentFullScreenCover(_ route: AppRoute) {
        presentedFullScreenCover = route
        trackNavigation(to: route)
    }
    
    /// Dismiss the current full screen cover
    func dismissFullScreenCover() {
        presentedFullScreenCover = nil
    }
    
    /// Show an alert
    func showAlert(_ config: AlertConfig) {
        alertToShow = config
    }
    
    /// Dismiss alert
    func dismissAlert() {
        alertToShow = nil
    }
    
    // MARK: - Convenience Navigation
    
    /// Navigate to main (home)
    func navigateToMain() {
        popToRoot()
    }
    
    /// Navigate to user list
    func navigateToUserList() {
        push(.userList)
    }
    
    /// Navigate to user detail
    func navigateToUserDetail(_ user: User) {
        push(.userDetail(user))
    }
    
    /// Present create user form
    func presentCreateUserForm() {
        presentSheet(.userForm(mode: .create))
    }
    
    /// Present edit user form
    func presentEditUserForm(_ user: User) {
        presentSheet(.userForm(mode: .edit(user)))
    }
    
    /// Navigate to settings
    func navigateToSettings() {
        push(.settings)
    }
    
    // MARK: - Analytics
    
    private func trackNavigation(to route: AppRoute) {
        // Access dependency lazily when needed
        @Dependency(\.analyticsTracker) var analyticsTracker
        analyticsTracker.trackScreen(route.analyticsName)
    }
}

// MARK: - Alert Configuration

struct AlertConfig: Identifiable {
    let id = UUID()
    let title: String
    let message: String?
    let primaryButton: AlertButton?
    let secondaryButton: AlertButton?
    
    init(
        title: String,
        message: String? = nil,
        primaryButton: AlertButton? = nil,
        secondaryButton: AlertButton? = nil
    ) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
    
    struct AlertButton {
        let title: String
        let role: ButtonRole?
        let action: () -> Void
        
        init(title: String, role: ButtonRole? = nil, action: @escaping () -> Void = {}) {
            self.title = title
            self.role = role
            self.action = action
        }
    }
}

// MARK: - View Extension for NavGraph

extension View {
    /// Apply navigation handling with NavGraph
    func withNavigation(_ navGraph: NavGraph) -> some View {
        self.modifier(NavGraphModifier(navGraph: navGraph))
    }
}

/// ViewModifier to handle navigation bindings
private struct NavGraphModifier: ViewModifier {
    @Bindable var navGraph: NavGraph
    
    func body(content: Content) -> some View {
        content
            .sheet(item: $navGraph.presentedSheet) { route in
                NavigationStack {
                    NavGraphView.view(for: route, navGraph: navGraph)
                }
            }
            .fullScreenCover(item: $navGraph.presentedFullScreenCover) { route in
                NavigationStack {
                    NavGraphView.view(for: route, navGraph: navGraph)
                }
            }
            .alert(
                navGraph.alertToShow?.title ?? "",
                isPresented: Binding(
                    get: { navGraph.alertToShow != nil },
                    set: { if !$0 { navGraph.dismissAlert() } }
                ),
                presenting: navGraph.alertToShow
            ) { config in
                if let primary = config.primaryButton {
                    Button(primary.title, role: primary.role) {
                        primary.action()
                    }
                }
                if let secondary = config.secondaryButton {
                    Button(secondary.title, role: secondary.role) {
                        secondary.action()
                    }
                }
            } message: { config in
                if let message = config.message {
                    Text(message)
                }
            }
    }
}

// MARK: - Route View Builder

enum NavGraphView {
    @MainActor
    @ViewBuilder
    static func view(for route: AppRoute, navGraph: NavGraph) -> some View {
        switch route {
        case .main:
            MainView(viewModel: MainViewModel(navGraph: navGraph))
            
        case .userList:
            UserListView(viewModel: UserListViewModel(navGraph: navGraph))
            
        case .userDetail(let user):
            UserDetailView(user: user, navGraph: navGraph)
            
        case .userForm(let mode):
            let viewModelMode: UserFormViewModel.Mode = {
                switch mode {
                case .create:
                    return .create
                case .edit(let user):
                    return .edit(user)
                }
            }()
            UserFormView(
                viewModel: UserFormViewModel(mode: viewModelMode, navGraph: navGraph)
            ) { _ in
                navGraph.dismissSheet()
            }
            
        case .settings:
            SettingsView(navGraph: navGraph)
        }
    }
}

// MARK: - Placeholder Views

/// User Detail View - Shows complete user information with avatar
private struct UserDetailView: View {
    let user: User
    let navGraph: NavGraph

    var body: some View {
        ZStack {
            // Background
            ArcanaTheme.Colors.backgroundLight
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: ArcanaTheme.Spacing.xl) {
                    // Avatar Section
                    avatarSection

                    // User Information Card
                    userInfoCard

                    // Additional Information Card
                    additionalInfoCard

                    // Action Buttons
                    actionButtons
                }
                .padding(.vertical, ArcanaTheme.Spacing.lg)
            }
        }
        .navigationTitle("User Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var avatarSection: some View {
        VStack(spacing: ArcanaTheme.Spacing.md) {
            // Large avatar
            AvatarView(user: user, size: 120)
                .shadow(color: ArcanaTheme.Colors.primaryPurple.opacity(0.3), radius: 10, x: 0, y: 5)

            // Full name
            Text(user.fullName)
                .font(ArcanaTheme.Typography.title)
                .fontWeight(.bold)
                .foregroundColor(ArcanaTheme.Colors.textPrimary)

            // ID Badge
            Text("ID: \(user.id)")
                .font(ArcanaTheme.Typography.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(.systemGray6))
                )
        }
        .padding(.top, ArcanaTheme.Spacing.md)
    }

    private var userInfoCard: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Image(systemName: "person.fill")
                    .foregroundStyle(ArcanaTheme.Colors.primaryPurple)
                Text("Personal Information")
                    .font(ArcanaTheme.Typography.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))

            // Information Rows
            VStack(spacing: 0) {
                InfoRow(
                    icon: "envelope.fill",
                    label: "Email",
                    value: user.email,
                    iconColor: ArcanaTheme.Colors.accentBlue
                )

                Divider()
                    .padding(.leading, 56)

                InfoRow(
                    icon: "person.text.rectangle.fill",
                    label: "First Name",
                    value: user.firstName,
                    iconColor: ArcanaTheme.Colors.accentGreen
                )

                Divider()
                    .padding(.leading, 56)

                InfoRow(
                    icon: "person.text.rectangle.fill",
                    label: "Last Name",
                    value: user.lastName,
                    iconColor: ArcanaTheme.Colors.accentGold
                )
            }
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: ArcanaTheme.CornerRadius.medium))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, ArcanaTheme.Spacing.md)
    }

    private var additionalInfoCard: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(ArcanaTheme.Colors.primaryPurple)
                Text("Additional Information")
                    .font(ArcanaTheme.Typography.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))

            // Information Rows
            VStack(spacing: 0) {
                InfoRow(
                    icon: "photo.fill",
                    label: "Avatar URL",
                    value: user.avatar.isEmpty ? "No avatar" : user.avatar,
                    iconColor: ArcanaTheme.Colors.primaryPurple
                )

                Divider()
                    .padding(.leading, 56)

                InfoRow(
                    icon: "calendar.badge.plus",
                    label: "Created",
                    value: formatDate(user.createdAt),
                    iconColor: ArcanaTheme.Colors.accentGreen
                )

                Divider()
                    .padding(.leading, 56)

                InfoRow(
                    icon: "calendar.badge.clock",
                    label: "Updated",
                    value: formatDate(user.updatedAt),
                    iconColor: ArcanaTheme.Colors.accentBlue
                )
            }
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: ArcanaTheme.CornerRadius.medium))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, ArcanaTheme.Spacing.md)
    }

    private var actionButtons: some View {
        VStack(spacing: ArcanaTheme.Spacing.md) {
            // Edit Button
            Button(action: {
                navGraph.presentEditUserForm(user)
            }) {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 20))
                    Text("Edit User")
                        .font(ArcanaTheme.Typography.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(ArcanaTheme.Colors.primaryGradient)
                .foregroundColor(.white)
                .cornerRadius(ArcanaTheme.CornerRadius.medium)
            }
            .accessibilityIdentifier("EditUserButton")

            // View Avatar Button (if avatar exists)
            if !user.avatar.isEmpty, let url = URL(string: user.avatar) {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "photo.circle.fill")
                            .font(.system(size: 20))
                        Text("View Full Avatar")
                            .font(ArcanaTheme.Typography.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [ArcanaTheme.Colors.accentBlue, ArcanaTheme.Colors.accentBlue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(ArcanaTheme.CornerRadius.medium)
                }
                .accessibilityIdentifier("ViewAvatarButton")
            }
        }
        .padding(.horizontal, ArcanaTheme.Spacing.md)
        .padding(.bottom, ArcanaTheme.Spacing.lg)
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Info Row Component

private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let iconColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: ArcanaTheme.Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(ArcanaTheme.Typography.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(ArcanaTheme.Typography.body)
                    .foregroundColor(ArcanaTheme.Colors.textPrimary)
                    .lineLimit(nil)
            }

            Spacer()
        }
        .padding()
    }
}

/// Placeholder for SettingsView - implement this later
private struct SettingsView: View {
    let navGraph: NavGraph
    
    var body: some View {
        List {
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
