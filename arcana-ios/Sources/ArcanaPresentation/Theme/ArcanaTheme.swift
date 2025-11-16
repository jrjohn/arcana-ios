//
//  ArcanaTheme.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import SwiftUI

/// Arcana iOS Design Theme
struct ArcanaTheme {
    
    // MARK: - Colors
    struct Colors {
        // Primary gradient colors
        static let primaryPurple = Color(hex: "667eea")
        static let primaryViolet = Color(hex: "764ba2")
        
        // Accent colors
        static let accentGold = Color(hex: "FFD700")
        static let accentViolet = Color(hex: "9333EA")
        static let accentBlue = Color(hex: "3B82F6")
        static let accentGreen = Color(hex: "10B981")
        static let accentRed = Color(hex: "EF4444")
        
        // Backgrounds
        static let backgroundDark = Color(hex: "1a1a2e")
        static let backgroundLight = Color(hex: "f8f9fa")
        static let cardBackground = Color(hex: "ffffff")
        
        // Text colors
        static let textPrimary = Color(hex: "1a1a2e")
        static let textSecondary = Color(hex: "6c757d")
        static let textTertiary = Color(hex: "adb5bd")
        
        // Gradients
        static let primaryGradient = LinearGradient(
            colors: [primaryPurple, primaryViolet],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardGradient = LinearGradient(
            colors: [Color(hex: "f5f7fa"), Color(hex: "c3cfe2")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let goldGradient = LinearGradient(
            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 15, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 14, weight: .regular, design: .rounded)
        static let caption2 = Font.system(size: 12, weight: .regular, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }
    
    // MARK: - Shadow Styles
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // MARK: - Shadows
    struct Shadow {
        static let small = ShadowStyle(
            color: .black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )

        static let medium = ShadowStyle(
            color: .black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )

        static let large = ShadowStyle(
            color: .black.opacity(0.2),
            radius: 16,
            x: 0,
            y: 8
        )
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extension for Shadows
extension View {
    func arcanaShadow(_ style: ArcanaTheme.ShadowStyle = ArcanaTheme.Shadow.medium) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
