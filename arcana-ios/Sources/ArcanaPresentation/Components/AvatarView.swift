//
//  AvatarView.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import SwiftUI

/// Reusable avatar component that displays user image or initials
struct AvatarView: View {
    let user: User
    let size: CGFloat

    init(user: User, size: CGFloat = 56) {
        self.user = user
        self.size = size
    }

    var body: some View {
        ZStack {
            if !user.avatar.isEmpty, let url = URL(string: user.avatar) {
                // Show image from URL
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        loadingPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure:
                        initialsPlaceholder
                    @unknown default:
                        initialsPlaceholder
                    }
                }
            } else {
                // Show initials
                initialsPlaceholder
            }
        }
        .frame(width: size, height: size)
    }

    private var initialsPlaceholder: some View {
        Circle()
            .fill(ArcanaTheme.Colors.primaryGradient)
            .frame(width: size, height: size)
            .overlay {
                Text(user.initials)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
            }
    }

    private var loadingPlaceholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: size, height: size)
            .overlay {
                ProgressView()
                    .tint(ArcanaTheme.Colors.primaryPurple)
            }
    }
}

// MARK: - Preview
#Preview("With Avatar URL") {
    VStack(spacing: 20) {
        AvatarView(user: User(
            email: "john@example.com",
            firstName: "John",
            lastName: "Doe",
            avatar: "https://reqres.in/img/faces/1-image.jpg"
        ), size: 80)

        AvatarView(user: User(
            email: "john@example.com",
            firstName: "John",
            lastName: "Doe",
            avatar: "https://reqres.in/img/faces/2-image.jpg"
        ), size: 56)
    }
    .padding()
}

#Preview("Without Avatar (Initials)") {
    VStack(spacing: 20) {
        AvatarView(user: User(
            email: "john@example.com",
            firstName: "John",
            lastName: "Doe"
        ), size: 80)

        AvatarView(user: User(
            email: "jane@example.com",
            firstName: "Jane",
            lastName: "Smith"
        ), size: 56)
    }
    .padding()
}
