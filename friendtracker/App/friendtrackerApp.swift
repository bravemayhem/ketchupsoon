//
//  friendtrackerApp.swift
//  friendtracker
//
//  Created by Amineh Beltran on 12/11/24.
//

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
    let container: ModelContainer
    @StateObject private var colorSchemeManager = ColorSchemeManager.shared
    @StateObject private var calendarManager = CalendarManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        PerformanceMonitor.shared.startMeasuring("AppLaunch")
        // Register the email array transformer
        EmailArrayValueTransformer.register()
        
        // Initialize ModelContainer
        do {
            // Define the schema
            let schema = Schema([
                Friend.self,
                Hangout.self,
                Tag.self
            ])
            
            if ProcessInfo.processInfo.isPreview {
                // Use in-memory configuration for previews
                let previewConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                container = try ModelContainer(
                    for: schema,
                    configurations: [previewConfig]
                )
            } else {
                // Use persistent configuration for actual app
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    allowsSave: true
                )
                
                do {
                    // First try to create the container normally
                    container = try ModelContainer(
                        for: schema,
                        configurations: [modelConfiguration]
                    )
                } catch {
                    print("Failed to load store, attempting to delete and recreate: \(error)")
                    
                    // Get the store URL from the Application Support directory
                    let storeURL = URL.applicationSupportDirectory.appendingPathComponent("default.store")
                    
                    // Delete the store file and any associated files
                    try? FileManager.default.removeItem(at: storeURL)
                    try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("sqlite3"))
                    try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("sqlite3-shm"))
                    try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("sqlite3-wal"))
                    
                    // Try to create the container again with a fresh store
                    container = try ModelContainer(
                        for: schema,
                        configurations: [modelConfiguration]
                    )
                }
                
                // Initialize predefined tags
                initializePredefinedTags()
            }
            
            debugLog("Model container initialized successfully")
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        
        configureAppearance()
        
        // Preload calendar events
        if !ProcessInfo.processInfo.isPreview {
            Task { @MainActor in
                await CalendarManager.shared.preloadTodaysEvents()
            }
        }
    }
    
    private func initializePredefinedTags() {
        Task { @MainActor in
            let context = container.mainContext
            let tagDescriptor = FetchDescriptor<Tag>(predicate: #Predicate<Tag> { tag in
                tag.isPredefined == true
            })
            
            if let existingTags = try? context.fetch(tagDescriptor), existingTags.isEmpty {
                Tag.predefinedTags.forEach { tagName in
                    let tag = Tag.createPredefinedTag(tagName)
                    context.insert(tag)
                }
                try? context.save()
            }
        }
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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorSchemeManager.currentAppearanceMode == .system ? nil : colorSchemeManager.colorScheme)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        // Refresh calendar events when app becomes active
                        Task {
                            await calendarManager.preloadTodaysEvents()
                        }
                    }
                }
                .onAppear {
                    PerformanceMonitor.shared.stopMeasuring("AppLaunch")
                }
        }
        .modelContainer(container)
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
