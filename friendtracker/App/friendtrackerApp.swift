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
import OSLog
import UIKit

// Add debug logging for UIViewController presentations using method swizzling
extension UIViewController {
    static let swizzleViewDidLoad: Void = {
        let originalSelector = #selector(UIViewController.viewDidLoad)
        let swizzledSelector = #selector(UIViewController.swizzled_viewDidLoad)
        
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector) else { return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()
    
    @objc private func swizzled_viewDidLoad() {
        swizzled_viewDidLoad()
        print("👀 UIViewController Debug - viewDidLoad: \(type(of: self))")
    }
    
    static let swizzleViewWillAppear: Void = {
        let originalSelector = #selector(UIViewController.viewWillAppear(_:))
        let swizzledSelector = #selector(UIViewController.swizzled_viewWillAppear(_:))
        
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector) else { return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()
    
    @objc private func swizzled_viewWillAppear(_ animated: Bool) {
        swizzled_viewWillAppear(animated)
        print("👀 UIViewController Debug - viewWillAppear: \(type(of: self))")
    }
    
    static let swizzleViewDidAppear: Void = {
        let originalSelector = #selector(UIViewController.viewDidAppear(_:))
        let swizzledSelector = #selector(UIViewController.swizzled_viewDidAppear(_:))
        
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector) else { return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()
    
    @objc private func swizzled_viewDidAppear(_ animated: Bool) {
        swizzled_viewDidAppear(animated)
        print("👀 UIViewController Debug - viewDidAppear: \(type(of: self))")
    }
    
    static let swizzlePresent: Void = {
        let originalSelector = #selector(UIViewController.present(_:animated:completion:))
        let swizzledSelector = #selector(UIViewController.swizzled_present(_:animated:completion:))
        
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector) else { return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()
    
    @objc private func swizzled_present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        print("👀 UIViewController Debug - presenting: \(type(of: viewControllerToPresent)) from: \(type(of: self))")
        swizzled_present(viewControllerToPresent, animated: flag, completion: completion)
    }
}

// Initialize swizzling
private let initializeSwizzling: Void = {
    UIViewController.swizzleViewDidLoad
    UIViewController.swizzleViewWillAppear
    UIViewController.swizzleViewDidAppear
    UIViewController.swizzlePresent
}()

@main
struct friendtrackerApp: App {
    let container: ModelContainer
    @StateObject private var colorSchemeManager = ColorSchemeManager.shared
    @StateObject private var calendarManager = CalendarManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Ensure swizzling is initialized
        _ = initializeSwizzling
        
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
                container = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
                
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
                .preferredColorScheme(colorSchemeManager.colorScheme)
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
