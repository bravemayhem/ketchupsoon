////  ketchupsoonApp.swift
//  ketchupsoon
//  Created by Amineh Beltran on 12/11/24.
//

import SwiftUI
import SwiftData
import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications
import WatchConnectivity

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate { // Removed MessagingDelegate
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()  // Uncomment to enable Firebase
        
        // Configure Firebase Messaging
        // Messaging.messaging().delegate = self  // Temporarily commented out for testing
        
        // Set UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Schedule Firebase user lookup for existing friends
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            Task {
                await self.checkForFirebaseUsersInContacts()
            }
        }
        
        return true
    }
    
    // MARK: - Firebase User Lookup
    
    func checkForFirebaseUsersInContacts() async {
        // Get model context
        let sharedModelContainer = try? ModelContainer()
        guard let context = sharedModelContainer?.mainContext else {
            print("⚠️ Failed to get SwiftData context")
            return
        }
        
        // Search for existing users in Firebase
        await FirebaseUserSearchService.shared.checkExistingFriendsForFirebaseUsers(in: context)
    }
    
    // MARK: - Firebase Cloud Messaging
    // Temporarily commenting out Firebase-related methods but keeping local notification methods
    
    // MARK: - Remote Notifications
    
    func application(_ application: UIApplication, 
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Pass device token to Firebase Messaging
        // Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - Remote Notification Handling for Firebase Auth
    
    func application(_ application: UIApplication, 
                    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Forward the notification to Firebase Auth to handle phone authentication
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        
        // Handle other notification types here if needed
        print("Received remote notification: \(userInfo)")
        
        completionHandler(.newData)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle foreground notifications
        let userInfo = notification.request.content.userInfo
        print("Received notification in foreground: \(userInfo)")
        
        // Show notification in foreground
        completionHandler([.badge, .sound, .banner, .list])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification interaction
        let userInfo = response.notification.request.content.userInfo
        print("User interacted with notification: \(userInfo)")
        
        // Process notification data here
        
        completionHandler()
    }
}

// MARK: - URL Handling Extension for Firebase Auth
extension AppDelegate {
    // Handle URL scheme for Firebase phone auth
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Forward URL to Firebase Auth
        if Auth.auth().canHandle(url) {
            return true
        }
        
        // Handle other URL schemes here if needed
        
        return false
    }
}

// Extension to check if running in preview mode
extension ProcessInfo {
    var isPreview: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

// Extension for application support directory URL
extension URL {
    static var applicationSupportDirectory: URL {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
    }
}

@main
struct ketchupsoonApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    let container: ModelContainer
    @StateObject private var colorSchemeManager = ColorSchemeManager.shared
    @StateObject private var profileManager = UserProfileManager.shared  // Initialize UserProfileManager
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        PerformanceMonitor.shared.startMeasuring("AppLaunch")
        
        // Verify transformer registration
        let registeredTransformers = ValueTransformer.valueTransformerNames()
        print("✓ Registered transformers: \(registeredTransformers)")
        
        // Initialize ModelContainer
        do {
            print("🏗 Creating schema...")
            let schema = Schema([
                UserModel.self
            ])
            
            print("📦 Creating ModelContainer...")
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
                print("✅ Created preview ModelContainer")
            } else {
                // Use persistent configuration for actual app
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    allowsSave: true
                )
                
                do {
                    print("📦 Attempting to create ModelContainer...")
                    container = try ModelContainer(
                        for: schema,
                        configurations: [modelConfiguration]
                    )
                    print("✅ Created ModelContainer successfully")
                } catch {
                    print("❌ Failed to load store, attempting to delete and recreate: \(error)")
                    
                    // Get the store URL from the Application Support directory
                    let storeURL = URL.applicationSupportDirectory.appendingPathComponent("default.store")
                    
                    // Delete the store file and any associated files
                    try? FileManager.default.removeItem(at: storeURL)
                    try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("sqlite3"))
                    try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("sqlite3-shm"))
                    try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("sqlite3-wal"))
                    
                    print("🔄 Attempting to create fresh ModelContainer...")
                    container = try ModelContainer(
                        for: schema,
                        configurations: [modelConfiguration]
                    )
                    print("✅ Created fresh ModelContainer successfully")
                }
            }
        } catch {
            print("❌ Fatal error initializing ModelContainer: \(error)")
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        
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
            SplashScreenView()
                .modelContainer(for: [], inMemory: false)
                .preferredColorScheme(colorSchemeManager.currentAppearanceMode == .system ? nil : colorSchemeManager.colorScheme)
                .environment(\.colorScheme, colorSchemeManager.colorScheme)
                .onAppear {
                    // Verify font registration on startup (DEBUG only)
                    #if DEBUG
                    verifyFontRegistration()
                    #endif
                }
        }
        .modelContainer(container)
    }
}
