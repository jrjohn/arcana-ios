//
//  UserCard.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import SwiftUI

/// Reusable card component for displaying user information
struct UserCard: View {
    let user: User
    
    var body: some View {
        HStack(spacing: ArcanaTheme.Spacing.md) {
            // Avatar
            AvatarView(user: user, size: 56)

            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                    .font(ArcanaTheme.Typography.headline)
                    .foregroundColor(ArcanaTheme.Colors.textPrimary)
                
                Text(user.email)
                    .font(ArcanaTheme.Typography.caption)
                    .foregroundColor(ArcanaTheme.Colors.textSecondary)
                
                Text(formatDate(user.createdAt))
                    .font(ArcanaTheme.Typography.caption2)
                    .foregroundColor(ArcanaTheme.Colors.textTertiary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ArcanaTheme.Colors.textTertiary)
        }
        .padding(ArcanaTheme.Spacing.md)
        .background(ArcanaTheme.Colors.cardBackground)
        .cornerRadius(ArcanaTheme.CornerRadius.medium)
        .arcanaShadow(ArcanaTheme.Shadow.small)
        .padding(.horizontal, ArcanaTheme.Spacing.md)
        .padding(.vertical, ArcanaTheme.Spacing.xs)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Created " + formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview
#Preview("Single Card") {
    UserCard(user: User.mock())
        .padding()
        .background(ArcanaTheme.Colors.backgroundLight)
}

#Preview("Card List") {
    ScrollView {
        VStack(spacing: 8) {
            ForEach(User.mockUsers) { user in
                UserCard(user: user)
            }
        }
    }
    .background(ArcanaTheme.Colors.backgroundLight)
}
