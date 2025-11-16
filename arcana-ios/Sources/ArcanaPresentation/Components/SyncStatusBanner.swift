//
//  SyncStatusBanner.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import SwiftUI

/// Banner showing sync status and offline mode
struct SyncStatusBanner: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    let pendingChangesCount: Int
    let onSyncTapped: () -> Void

    var body: some View {
        if !networkMonitor.isConnected || pendingChangesCount > 0 {
            HStack(spacing: 12) {
                // Status icon
                Image(systemName: networkMonitor.isConnected ? "icloud.and.arrow.up" : "wifi.slash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                // Status text
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    if pendingChangesCount > 0 {
                        Text("\(pendingChangesCount) change\(pendingChangesCount == 1 ? "" : "s") pending")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()

                // Sync button (only show when online and has pending changes)
                if networkMonitor.isConnected && pendingChangesCount > 0 {
                    Button(action: onSyncTapped) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12))
                            Text("Sync")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(bannerColor)
            .animation(.easeInOut(duration: AppConstants.UI.animationDuration), value: networkMonitor.isConnected)
            .animation(.easeInOut(duration: AppConstants.UI.animationDuration), value: pendingChangesCount)
        }
    }

    private var statusTitle: String {
        if !networkMonitor.isConnected {
            return "Offline Mode"
        } else if pendingChangesCount > 0 {
            return "Syncing..."
        } else {
            return "Connected"
        }
    }

    private var bannerColor: Color {
        if !networkMonitor.isConnected {
            return Color.orange.opacity(0.9)
        } else if pendingChangesCount > 0 {
            return Color.blue.opacity(0.9)
        } else {
            return Color.green.opacity(0.9)
        }
    }
}

// MARK: - Preview
#Preview("Offline") {
    VStack {
        SyncStatusBanner(
            networkMonitor: {
                let monitor = NetworkMonitor.shared
                return monitor
            }(),
            pendingChangesCount: 3,
            onSyncTapped: {}
        )

        Spacer()
    }
}

#Preview("Online with Pending") {
    VStack {
        SyncStatusBanner(
            networkMonitor: NetworkMonitor.shared,
            pendingChangesCount: 5,
            onSyncTapped: {}
        )

        Spacer()
    }
}
