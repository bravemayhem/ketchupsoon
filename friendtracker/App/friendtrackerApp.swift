//
//  friendtrackerApp.swift
//  friendtracker
//
//  Created by Amineh Beltran on 12/11/24.
//

import SwiftUI
import SwiftData

@main
struct friendtrackerApp: App {
    init() {
        // Debug: Print all available fonts
        #if DEBUG
        for family in UIFont.familyNames.sorted() {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("   Font: \(name)")
            }
        }
        #endif
        
        configureAppearance()
    }
    
    private func configureAppearance() {
        // Shared background color for bars
        let backgroundColor = UIColor(AppColors.systemBackground)
        
        // Navigation bar configuration
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundColor = backgroundColor
        navAppearance.shadowColor = .clear // This removes the bottom border
        
        // Title text attributes
        let titleTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(AppColors.label),
            .font: UIFont(name: "Cabin-Bold", size: 20) ?? {
                #if DEBUG
                print("Available fonts:")
                for family in UIFont.familyNames.sorted() {
                    print("\(family):")
                    for name in UIFont.fontNames(forFamilyName: family) {
                        print("   \(name)")
                    }
                }
                #endif
                return .systemFont(ofSize: 20, weight: .bold)
            }()
        ]
        
        let largeTitleTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(AppColors.label),
            .font: UIFont(name: "Cabin-Bold", size: 36) ?? {
                return .systemFont(ofSize: 36, weight: .bold)
            }()
        ]
        
        navAppearance.titleTextAttributes = titleTextAttributes
        navAppearance.largeTitleTextAttributes = largeTitleTextAttributes
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        
        // Tab bar configuration
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = backgroundColor
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(AppColors.secondaryLabel)
        UITabBar.appearance().tintColor = UIColor(AppColors.accent)
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Friend.self,
            Hangout.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

extension ProcessInfo {
    var isPreview: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

extension URL {
    static var applicationSupportDirectory: URL {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
    }
}
