//
//  arcana_iosApp.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import SwiftUI
import SwiftData
import Dependencies  // re-exports IssueReporting.isTesting

@main
struct arcana_iosApp: App {
    let sharedModelContainer: ModelContainer
    
    init() {
        // Step 1: Create ModelContainer using AppDependencies helper
        sharedModelContainer = AppDependencies.createModelContainer()

        // Step 2: Configure dependencies (must happen before creating views)
        MainActor.assumeIsolated {
            AppDependencies.setup(modelContainer: sharedModelContainer)
        }
    }

    var body: some Scene {
        WindowGroup {
            // When this app is only the host for unit tests, don't bring up the UI:
            // MainView.onAppear would load data through the live dependencies from
            // outside any test, which swift-dependencies reports as an issue
            // attributed to no test («unknown»). UI tests launch the app as a
            // separate process, where isTesting is false.
            if !isTesting {
                ContentView()
                    .modelContainer(sharedModelContainer)
            }
        }
    }
}

// MARK: - Content View with Navigation

struct ContentView: View {
    @State private var navGraph = NavGraph()
    
    var body: some View {
        NavigationStack(path: $navGraph.path) {
            MainView(viewModel: MainViewModel(navGraph: navGraph))
                .navigationDestination(for: AppRoute.self) { route in
                    NavGraphView.view(for: route, navGraph: navGraph)
                }
        }
        .withNavigation(navGraph)
    }
}
