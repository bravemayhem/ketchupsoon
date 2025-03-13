import SwiftUI
import SwiftData
import UIKit
import FirebaseAuth

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var onboardingManager: OnboardingManager
    @EnvironmentObject private var firebaseSyncService: FirebaseSyncService
    @State private var selectedTab = 0
    @State private var showingContactPicker = false
    @State private var showingDebugAlert = false
    @State private var showingImportOptions = false
    @State private var showingSettings = false
    @State private var showConfetti = false {
        didSet {
            print("DEBUG: ContentView - showConfetti changed to \(showConfetti)")
        }
    }
    
    // IMPORTANT: Cache the profile view to prevent repeated recreation
    // This prevents the infinite loading loop by ensuring we only create it once
    @State private var cachedProfileView: AnyView? = nil
    
    // Track Firebase sync operations to prevent excessive calls
    @State private var lastSyncTime: Date? = nil
    private let minSyncInterval: TimeInterval = 30.0 // Minimum seconds between syncs
    
    // MARK: - Tab Content Views
    
    private var homeTabView: some View {
        CustomNavigationBarContainer(
            leadingButtonAction: {
                showingSettings = true
            },
            trailingButtonAction: {
                showingContactPicker = true
            },
            enableDebugMode: true,
            debugModeAction: {
                showingDebugAlert = true
            }
        ) {
            // FIREBASE REQUIREMENT: Home tab
            // - Uses FirebaseSyncService for displaying friend activity
            // - Uses FirestoreListenerService indirectly for real-time updates
            HomeView()
                .environmentObject(firebaseSyncService)
        }
        .transition(.opacity)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private var meetupTabView: some View {
        CustomNavigationBarContainer(
            leadingButtonAction: {
                showingSettings = true
            },
            trailingButtonAction: {
                showingContactPicker = true
            },
            enableDebugMode: true,
            debugModeAction: {
                showingDebugAlert = true
            }
        ) {
            // FIREBASE REQUIREMENT: Create Meetup tab
            // - Uses FirebaseSyncService for friend selection and invitations
            // - Needs friends list from Firestore
            CreateMeetupView()
                .environmentObject(firebaseSyncService)
        }
        .transition(.opacity)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private var pulseTabView: some View {
        CustomNavigationBarContainer(
            leadingButtonAction: {
                showingSettings = true
            },
            trailingButtonAction: {
                showingContactPicker = true
            },
            enableDebugMode: true,
            debugModeAction: {
                showingDebugAlert = true
            }
        ) {
            // FIREBASE REQUIREMENT: Pulse tab
            // - Uses FirebaseSyncService for social activity feeds
            // - Uses FirestoreListenerService indirectly for real-time notifications
            PulseView()
                .environmentObject(firebaseSyncService)
        }
        .transition(.opacity)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private var profileTabView: some View {
        CustomNavigationBarContainer(
            showLeadingButton: false,
            showTrailingButton: false,
            profileEmoji: "😎"
        ) {
            // FIREBASE REQUIREMENT: Profile tab
            // - Critical: Uses FirebaseSyncService for user profile management
            // - Uses FirestoreListenerService indirectly for friend status updates
            // - Primary interface for friendship operations
            
            Group {
                if let profileView = cachedProfileView {
                    profileView
                } else {
                    Text("Loading profile...")
                        .onAppear {
                            let view = ProfileFactory.createProfileView(
                                for: .currentUser,
                                modelContext: modelContext,
                                firebaseSyncService: firebaseSyncService
                            )
                            DispatchQueue.main.async {
                                cachedProfileView = AnyView(view)
                            }
                        }
                }
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Main Content
    
    private var tabContent: some View {
        Group {
            if selectedTab == 0 {
                homeTabView
            } else if selectedTab == 1 {
                meetupTabView
            } else if selectedTab == 2 {
                pulseTabView
            } else if selectedTab == 3 {
                profileTabView
            }
        }
    }
    
    private var mainContent: some View {
        ZStack {
            // Background
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            // Tab content based on selection
            tabContent
        }
        .withCustomTabBar(selectedTab: selectedTab) { tab in
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }
    }
    
    // MARK: - Lifecycle Methods
    
    private func syncAndCacheProfileOnAppear() {
        // Only proceed if a user is logged in
        guard Auth.auth().currentUser != nil else { return }
        
        // Check if we've synced recently to avoid unnecessary operations
        let now = Date()
        if let lastSync = lastSyncTime, now.timeIntervalSince(lastSync) < minSyncInterval {
            print("🔄 DEBUG: Skipping Firebase sync - too soon since last sync (\(now.timeIntervalSince(lastSync)) seconds)")
            
            // Still ensure profile view is cached even if we skip sync
            ensureProfileViewIsCached()
            return
        }
        
        // Perform sync as a background task
        Task {
            print("🔄 DEBUG: Starting Firebase data sync operation")
            await firebaseSyncService.performFullSync()
            await MainActor.run {
                lastSyncTime = Date()
                print("✅ DEBUG: Firebase data sync complete")
            }
            
            // Cache the profile view after sync completes
            ensureProfileViewIsCached()
        }
    }
    
    /// Ensures the profile view is cached, creating it if needed
    private func ensureProfileViewIsCached() {
        // Only create the view if it's not already cached
        if cachedProfileView == nil {
            DispatchQueue.main.async {
                print("🧩 DEBUG: Creating cached profile view")
                let profileView = ProfileFactory.createProfileView(
                    for: .currentUser,
                    modelContext: modelContext,
                    firebaseSyncService: firebaseSyncService
                )
                self.cachedProfileView = AnyView(profileView)
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            mainContent
        }
        .alert("Debug Mode", isPresented: $showingDebugAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Debug mode activated!")
        }
        .onAppear {
            syncAndCacheProfileOnAppear()
        }
        // Add back the fullScreenCover to show onboarding when isShowingOnboarding becomes true
        .fullScreenCover(isPresented: $onboardingManager.isShowingOnboarding) {
            UserOnboardingView(container: modelContext.container)
                .environmentObject(firebaseSyncService)
                .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            syncAndCacheProfileOnAppear()
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: UserModel.self)
    ContentView()
        .modelContainer(for: UserModel.self)
        .environmentObject(OnboardingManager.shared)
        .environmentObject(FirebaseSyncServiceFactory.createService(modelContext: container.mainContext))
}
