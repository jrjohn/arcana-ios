//
//  UserListView.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import SwiftUI
import Dependencies

/// User List Screen with search and CRUD operations using Observation
struct UserListView: View {
    @State private var viewModel: UserListViewModel
    @State private var showingAddUser = false
    @State private var userToDelete: User?
    @State private var showingDeleteAlert = false
    @State private var showingError = false
    @State private var errorToShow: AppError?
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    init(viewModel: UserListViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    private var searchQueryBinding: Binding<String> {
        Binding(
            get: { viewModel.output.searchQuery },
            set: { newValue in
                Task {
                    _ = await viewModel.input(.search(newValue))
                }
            }
        )
    }

    var body: some View {
        ZStack {
            background
            mainContent
        }
        .navigationTitle("Users")
        .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddUser = true }) {
                        Image(systemName: "plus")
                            .foregroundStyle(ArcanaTheme.Colors.primaryPurple)
                    }
                    .accessibilityIdentifier("AddUserButton")
                    .accessibilityLabel("Add User")
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            if let effect = await viewModel.input(.refresh) {
                                handleEffect(effect)
                            }
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(ArcanaTheme.Colors.primaryPurple)
                    }
                    .accessibilityIdentifier("RefreshButton")
                    .disabled(viewModel.output.isRefreshing)
                }
            }
            .sheet(isPresented: $showingAddUser) {
                NavigationStack {
                    UserFormView(
                        viewModel: UserFormViewModel(mode: .create)
                    ) { createdUser in
                        showingAddUser = false
                        Task {
                            if let effect = await viewModel.input(.refresh) {
                                handleEffect(effect)
                            }
                        }
                    }
                }
            }
            .alert("Delete User", isPresented: $showingDeleteAlert, presenting: userToDelete) { user in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        if let effect = await viewModel.input(.deleteUser(user)) {
                            handleEffect(effect)
                        }
                    }
                }
            } message: { user in
                Text("Are you sure you want to delete \(user.fullName)?")
            }
            .alert("Error", isPresented: $showingError, presenting: errorToShow) { error in
                Button("OK", role: .cancel) { }
                if viewModel.canRetry {
                    Button("Retry") {
                        Task {
                            if let effect = await viewModel.input(.retryLastOperation) {
                                handleEffect(effect)
                            }
                        }
                    }
                }
            } message: { error in
                Text(error.localizedDescription)
            }
            .onAppear {
                Task {
                    if let effect = await viewModel.input(.loadInitial) {
                        handleEffect(effect)
                    }
                }

                // Update pending changes count periodically
                Task {
                    while !Task.isCancelled {
                        await updatePendingCount()
                        try? await Task.sleep(nanoseconds: 5_000_000_000) // Every 5 seconds
                    }
                }
            }
    }
    
    // MARK: - Subviews

    private var background: some View {
        ArcanaTheme.Colors.backgroundLight
            .ignoresSafeArea()
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            syncStatusBanner
            statisticsBanner
            searchBar
            contentView
            crudActionBar
        }
    }

    private var syncStatusBanner: some View {
        SyncStatusBanner(
            networkMonitor: networkMonitor,
            pendingChangesCount: viewModel.output.pendingChangesCount,
            onSyncTapped: {
                Task {
                    if let effect = await viewModel.input(.syncOfflineChanges) {
                        handleEffect(effect)
                    }
                }
            }
        )
    }

    @ViewBuilder
    private var statisticsBanner: some View {
        if !viewModel.output.users.isEmpty || viewModel.output.isLoading {
            UserStatisticsBanner(
                totalUsersLoaded: viewModel.output.users.count,
                currentPage: viewModel.output.currentPage,
                totalPages: viewModel.output.totalPages
            )
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private var searchBar: some View {
        SearchBar(text: searchQueryBinding)
            .padding(.horizontal)
            .padding(.vertical, 8)
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.output.isLoading && viewModel.displayedUsers.isEmpty {
            loadingView
        } else if viewModel.displayedUsers.isEmpty {
            emptyStateView
        } else {
            userListView
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading users...")
                .font(ArcanaTheme.Typography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 64))
                .foregroundStyle(ArcanaTheme.Colors.primaryPurple.opacity(0.5))
            
            Text(viewModel.emptyStateMessage)
                .font(ArcanaTheme.Typography.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if !viewModel.isSearching {
                Button(action: { showingAddUser = true }) {
                    Label("Add User", systemImage: "plus.circle.fill")
                        .font(ArcanaTheme.Typography.body)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(ArcanaTheme.Colors.primaryGradient)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var userListView: some View {
        List {
            ForEach(viewModel.displayedUsers) { user in
                UserCard(user: user)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task {
                            if let effect = await viewModel.input(.selectUser(user)) {
                                handleEffect(effect)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            userToDelete = user
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .onAppear {
                        // Trigger pagination when reaching the last item
                        if user.id == viewModel.displayedUsers.last?.id {
                            Task {
                                if let effect = await viewModel.input(.loadNextPage) {
                                    handleEffect(effect)
                                }
                            }
                        }
                    }
            }

            // Loading indicator for pagination
            if viewModel.output.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable {
            if let effect = await viewModel.input(.refresh) {
                await MainActor.run {
                    handleEffect(effect)
                }
            }
        }
        .overlay {
            if viewModel.output.isRefreshing {
                VStack {
                    ProgressView()
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - CRUD Action Bar
    
    private var crudActionBar: some View {
        HStack(spacing: 16) {
            // Create button
            ActionButton(
                icon: "plus.circle.fill",
                title: "Create",
                color: ArcanaTheme.Colors.accentGreen
            ) {
                showingAddUser = true
            }
            
            // Read/Refresh button
            ActionButton(
                icon: "arrow.clockwise.circle.fill",
                title: "Refresh",
                color: ArcanaTheme.Colors.accentBlue
            ) {
                Task {
                    if let effect = await viewModel.input(.refresh) {
                        handleEffect(effect)
                    }
                }
            }
            .disabled(viewModel.output.isRefreshing)
            
            // Update button (disabled when no selection)
            ActionButton(
                icon: "pencil.circle.fill",
                title: "Edit",
                color: ArcanaTheme.Colors.accentGold
            ) {
                // Edit functionality - you can implement selection logic
                print("Edit tapped")
            }
            .opacity(0.5) // Disabled appearance
            
            // Delete button (disabled when no selection)
            ActionButton(
                icon: "trash.circle.fill",
                title: "Delete",
                color: ArcanaTheme.Colors.accentRed
            ) {
                // Delete functionality - you can implement selection logic
                print("Delete tapped")
            }
            .opacity(0.5) // Disabled appearance
        }
        .padding(.horizontal, ArcanaTheme.Spacing.md)
        .padding(.vertical, ArcanaTheme.Spacing.md)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
    
    // MARK: - Effect Handling
    
    private func handleEffect(_ effect: UserListViewModel.Effect) {
        switch effect {
        case .showError(let error):
            errorToShow = error
            showingError = true

        case .showSuccess(let message):
            // Could show a toast here
            print("✅ Success: \(message)")

        case .navigateToDetail(let user):
            // Navigation handled by coordinator or navigation system
            print("Navigate to detail for user: \(user.fullName)")

        case .showDeleteConfirmation(let user):
            userToDelete = user
            showingDeleteAlert = true
        }
    }

    @MainActor
    private func updatePendingCount() async {
        // Access the repository through dependencies
        @Dependency(\.userRepository) var userRepository

        guard let repository = userRepository as? OfflineFirstUserRepositoryImpl else {
            return
        }

        let count = repository.getPendingChangesCount()
        Task {
            _ = await viewModel.input(.updatePendingChangesCount(count))
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search users...", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Action Button Component
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(ArcanaTheme.Typography.caption2)
                    .foregroundColor(ArcanaTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - User Statistics Banner
struct UserStatisticsBanner: View {
    let totalUsersLoaded: Int
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 0) {
            // Total Users Loaded
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Users Loaded")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("\(totalUsersLoaded)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(ArcanaTheme.Colors.primaryPurple)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Page Progress
            VStack(alignment: .trailing, spacing: 4) {
                Text("Page Progress")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("\(currentPage) / \(totalPages)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(ArcanaTheme.Colors.primaryPurple)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Preview
#Preview {
    AppDependencies.withPreviewDependencies(mockUsers: User.mockUsers) {
        NavigationStack {
            UserListView(viewModel: UserListViewModel())
        }
    }
}

