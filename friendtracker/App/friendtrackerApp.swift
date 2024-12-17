//
//  friendtrackerApp.swift
//  friendtracker
//
//  Created by Amineh Beltran on 12/11/24.
//

import SwiftUI
import SwiftData

@main
struct FriendTrackerApp: App {
    let container: ModelContainer
    let theme = Theme.shared
    
    init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: ProcessInfo.processInfo.isPreview)
            
            #if DEBUG
            debugLog("Initializing ModelContainer with configuration")
            #endif
            
            container = try ModelContainer(
                for: Friend.self, Hangout.self,
                configurations: config
            )
            
            #if DEBUG
            debugLog("Successfully initialized container")
            #endif
        } catch {
            #if DEBUG
            debugLog("Failed to initialize container: \(error)")
            #endif
            fatalError("Failed to initialize container: \(error)")
        }
        
        configureAppearance()
    }
    
    private func configureAppearance() {
        // Shared background color for bars
        let backgroundColor = UIColor(theme.background)
        
        // Navigation bar configuration -  bar at the top of each screen that shows the title "Friends" and contains the "+" button
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = backgroundColor
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(theme.primaryText)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(theme.primaryText)]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        
        // Tab bar configuration - This is the bar at the bottom of the screen that lets you switch between "Scheduled", "To Connect", and "Friends" tabs
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = backgroundColor
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(theme.secondaryText)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(theme)
        }
        .modelContainer(container)
    }
}

extension ProcessInfo {
    var isPreview: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
