//
//  MainView.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import SwiftUI

/// Main welcome screen for Arcana User Management
struct MainView: View {
    @State private var viewModel: MainViewModel
    
    init(viewModel: MainViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
                // Background gradient - purple theme
                LinearGradient(
                    colors: [
                        Color(hex: "2E1F5E"),
                        Color(hex: "5B3A99"),
                        Color(hex: "764BA2")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: ArcanaTheme.Spacing.xl) {
                    Spacer()
                    
                    // Title with sparkles
                    HStack(spacing: 8) {
                        Text("✨")
                            .font(.system(size: 32))
                        
                        Text("Arcana")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        ArcanaTheme.Colors.accentGold,
                                        Color(hex: "FFB800")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("✨")
                            .font(.system(size: 32))
                    }
                    .padding(.bottom, 8)
                    
                    // Subtitle
                    Text("Mystical User Management")
                        .font(ArcanaTheme.Typography.body)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                        .frame(height: 60)
                    
                    // User count card or error
                    if viewModel.hasError {
                        errorView
                    } else {
                        userCountCard
                    }
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Manage Users button
                    Button(action: {
                        Task {
                            _ = await viewModel.input(.navigateToUserList)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text("Manage Users")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(Color(hex: "2E1F5E"))
                        .frame(maxWidth: 300)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: ArcanaTheme.CornerRadius.medium)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            ArcanaTheme.Colors.accentGold,
                                            Color(hex: "FFB800")
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: ArcanaTheme.Colors.accentGold.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .disabled(!viewModel.canNavigate)
                    .opacity(viewModel.canNavigate ? 1.0 : 0.6)
                    
                    Spacer()
                }
                .padding(.horizontal, ArcanaTheme.Spacing.lg)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        _ = await viewModel.input(.navigateToSettings)
                    }
                }) {
                    Image(systemName: "gear")
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }
        }
        .onAppear {
            Task {
                _ = await viewModel.input(.loadData)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var userCountCard: some View {
        VStack(spacing: ArcanaTheme.Spacing.md) {
            Text("Total Users")
                .font(ArcanaTheme.Typography.callout)
                .foregroundColor(.white.opacity(0.8))
            
            if viewModel.output.isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            } else {
                Text("\(viewModel.output.userCount)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                ArcanaTheme.Colors.accentGold,
                                Color(hex: "FFB800")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("Loaded: \(viewModel.output.userCount) users")
                    .font(ArcanaTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: 300)
        .padding(.vertical, ArcanaTheme.Spacing.xl)
        .padding(.horizontal, ArcanaTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: ArcanaTheme.CornerRadius.large)
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ArcanaTheme.CornerRadius.large)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var errorView: some View {
        VStack(spacing: ArcanaTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(ArcanaTheme.Colors.accentRed.opacity(0.8))
            
            Text("Error")
                .font(ArcanaTheme.Typography.headline)
                .foregroundColor(.white)
            
            if let errorMessage = viewModel.output.errorMessage {
                Text(errorMessage)
                    .font(ArcanaTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                Task {
                    _ = await viewModel.input(.retry)
                }
            }) {
                Text("Retry")
                    .font(ArcanaTheme.Typography.callout)
                    .foregroundColor(Color(hex: "2E1F5E"))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                    )
            }
        }
        .frame(maxWidth: 300)
        .padding(.vertical, ArcanaTheme.Spacing.xl)
        .padding(.horizontal, ArcanaTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: ArcanaTheme.CornerRadius.large)
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ArcanaTheme.CornerRadius.large)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        MainView(viewModel: MainViewModel(navGraph: NavGraph()))
    }
}

#Preview("With Users") {
    AppDependencies.withPreviewDependencies(mockUsers: User.mockUsers) {
        NavigationStack {
            MainView(viewModel: MainViewModel(navGraph: NavGraph()))
        }
    }
}
