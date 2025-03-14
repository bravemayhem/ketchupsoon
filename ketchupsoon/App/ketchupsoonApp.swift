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
import UIKit
import Observation

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate { // Removed MessagingDelegate
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()  // Uncomment to enable Firebase
        
        // Initialize core services that should run regardless of auth state
        _ = LoggingService.shared
        _ = AuthStateService.shared
        _ = FirebaseOperationCoordinator.shared
        
        // Set UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Only schedule Firebase-dependent operations if/when user is authenticated
        // This prevents unnecessary resource usage for non-authenticated users
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if user != nil {
                // User is authenticated, schedule contacts check
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    Task {
                        await self?.checkForFirebaseUsersInContacts()
                    }
                }
                
                // Initialize Firebase Messaging only for authenticated users
                // self.setupFirebaseMessaging()
            }
        }
        
        return true
    }
    
    // MARK: - Firebase User Lookup
    
    func checkForFirebaseUsersInContacts() async {
        // Get model context
        let schema = Schema([UserModel.self, FriendshipModel.self, MeetupModel.self])
        let sharedModelContainer = try? ModelContainer(for: schema)
        guard let context = sharedModelContainer?.mainContext else {
            print("⚠️ Failed to get SwiftData context")
            return
        }
        
        // Only proceed if user is authenticated
        guard Auth.auth().currentUser != nil else {
            print("⚠️ Cannot check for Firebase users in contacts - no authenticated user")
            return
        }
        
        // Search for existing users in Firebase
        await FirebaseUserSearchService.shared.checkExistingFriendsForFirebaseUsers(in: context)
    }
    
    // Private method to set up Firebase Messaging when needed
    private func setupFirebaseMessaging() {
        // Configure Firebase Messaging
        // Messaging.messaging().delegate = self
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

// MARK: - Haptic Feedback
@Observable
class HapticFeedbackGenerator {
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    init() {
        prepare()
    }
    
    func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    func lightImpact() {
        lightGenerator.impactOccurred()
    }
    
    func mediumImpact() {
        mediumGenerator.impactOccurred()
    }
    
    func heavyImpact() {
        heavyGenerator.impactOccurred()
    }
    
    func selectionChanged() {
        selectionGenerator.selectionChanged()
    }
    
    func notificationOccurred(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }
    
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }
    
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }
}

// Environment key for haptic feedback
struct HapticFeedbackKey: EnvironmentKey {
    static let defaultValue = HapticFeedbackGenerator()
}

extension EnvironmentValues {
    var hapticFeedback: HapticFeedbackGenerator {
        get { self[HapticFeedbackKey.self] }
        set { self[HapticFeedbackKey.self] = newValue }
    }
}

@main
struct ketchupsoonApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    static func registerValueTransformers() {
        // Register our custom transformers for array handling
        ArrayTransformer.register()
    }
    
    let container: ModelContainer
    @StateObject private var colorSchemeManager = ColorSchemeManager.shared
    @StateObject private var profileManager = UserProfileManager.shared  // Initialize UserProfileManager
    @StateObject private var firebaseSyncService: FirebaseSyncService
    @StateObject private var onboardingManager = OnboardingManager.shared  // Add OnboardingManager
    @Environment(\.scenePhase) private var scenePhase
    
    // Update to use Observable without @StateObject
    private var feedbackGenerator = HapticFeedbackGenerator()
    
    init() {
        PerformanceMonitor.shared.startMeasuring("AppLaunch")
        
        // Register our custom array transformer
        Self.registerValueTransformers()
        
        // Verify transformer registration
        let registeredTransformers = ValueTransformer.valueTransformerNames()
        print("✓ Registered transformers: \(registeredTransformers)")
        
        // Initialize ModelContainer
        do {
            print("🏗 Creating schema...")
            let schema = Schema([
                UserModel.self,
                FriendshipModel.self,
                MeetupModel.self
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
        
        // Initialize Firebase services with the container's context
        let syncService = FirebaseSyncService(modelContext: container.mainContext)
        _firebaseSyncService = StateObject(wrappedValue: syncService)
        
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
            ContentView()
                .modelContainer(for: [
                    UserModel.self,
                    FriendshipModel.self,
                    MeetupModel.self
                ])
                .environment(\.modelContext, container.mainContext)
                .environmentObject(colorSchemeManager)
                .environmentObject(profileManager)
                .environmentObject(firebaseSyncService)
                .environmentObject(onboardingManager)  // Add OnboardingManager to environment
                .environment(feedbackGenerator)
                .onAppear {
                    // Initialize the logging service
                    _ = LoggingService.shared
                    
                    // Initialize auth state service
                    _ = AuthStateService.shared
                    
                    // Other existing onAppear code...
                }
                .preferredColorScheme(colorSchemeManager.currentAppearanceMode == .system ? nil : colorSchemeManager.colorScheme)
                .environment(\.colorScheme, colorSchemeManager.colorScheme)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // App became active
                if Auth.auth().currentUser != nil {
                    // Initialize log verbosity first
                    FirebaseOperationCoordinator.shared.setLogVerbosity(.important)
                    
                    // Tell auth service to refresh state (which will trigger necessary operations)
                    AuthStateService.shared.refreshState()
                }
            case .background:
                // App entered background, cancel non-critical operations
                if let userID = Auth.auth().currentUser?.uid {
                    FirebaseOperationCoordinator.shared.cancelOperations(withKey: "sync_after_listen_\(userID)")
                    FirebaseOperationCoordinator.shared.cancelOperations(withKey: "full_sync_\(userID)")
                }
            case .inactive:
                // App is transitioning between states, do nothing
                break
            @unknown default:
                break
            }
        }
    }
}
