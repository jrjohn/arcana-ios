//
//  arcana_iosApp.swift
//  arcana-ios
//
//  Created by John on 2025/11/15.
//

import SwiftUI
import SwiftData

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
            ContentView()
                .modelContainer(sharedModelContainer)
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
