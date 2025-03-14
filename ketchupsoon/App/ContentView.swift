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
    
    // Track authentication state
    @State private var isAuthenticated = false
    // Track if initial auth check has completed
    @State private var hasCheckedAuth = false
    
    // IMPORTANT: Cache the profile view to prevent repeated recreation
    // This prevents the infinite loading loop by ensuring we only create it once
    @State private var cachedProfileView: AnyView? = nil
    
    // Track Firebase sync operations to prevent excessive calls
    @State private var lastSyncTime: Date? = nil
    private let minSyncInterval: TimeInterval = 30.0 // Minimum seconds between syncs
    
    // MARK: - Auth State Management
    
    private func setupAuthStateListener() {
        // Set up auth state listener once at initialization
        // This runs before views are loaded
        let _ = Auth.auth().addStateDidChangeListener { _, user in
            // Update on main thread
            Task { @MainActor in
                self.isAuthenticated = user != nil
                self.hasCheckedAuth = true
                
                if user != nil {
                    // Only sync data when authenticated
                    self.syncAndCacheProfileOnAppear()
                } else {
                    // Clear any cached views when signing out
                    self.cachedProfileView = nil
                }
            }
        }
    }
    
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
                    // Replace text with EmptyView or transparent view to avoid the flash
                    EmptyView()
                        .onAppear {
                            // Create the profile view immediately
                            let view = ProfileFactory.createProfileView(
                                for: .currentUser,
                                modelContext: modelContext,
                                firebaseSyncService: firebaseSyncService
                            )
                            // Use immediate assignment instead of DispatchQueue
                            cachedProfileView = AnyView(view)
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
        // Only proceed if a user is logged in - double check to be safe
        guard Auth.auth().currentUser != nil else { return }
        
        // Create the profile view immediately to avoid loading flash
        ensureProfileViewIsCached()
        
        // Check if we've synced recently to avoid unnecessary operations
        let now = Date()
        if let lastSync = lastSyncTime, now.timeIntervalSince(lastSync) < minSyncInterval {
            print("🔄 DEBUG: Skipping Firebase sync - too soon since last sync (\(now.timeIntervalSince(lastSync)) seconds)")
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
        }
    }
    
    /// Ensures the profile view is cached, creating it if needed
    private func ensureProfileViewIsCached() {
        // Only create the view if it's not already cached
        if cachedProfileView == nil {
            print("🧩 DEBUG: Creating cached profile view")
            let profileView = ProfileFactory.createProfileView(
                for: .currentUser,
                modelContext: modelContext,
                firebaseSyncService: firebaseSyncService
            )
            // Assign directly on the main thread since we're likely already there
            cachedProfileView = AnyView(profileView)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack {
                // App name with gradient and glow effect
                Text("ketchupsoon")
                    .font(.custom("SpaceGrotesk-Bold", size: 42))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.accent, AppColors.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: AppColors.accent.opacity(0.7), radius: 10, x: 0, y: 0)
                
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                    .padding(.top, 20)
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if !hasCheckedAuth {
                // Show loading view until auth check completes
                loadingView
            } else if !isAuthenticated {
                // Show auth view directly if not authenticated
                AuthView(onAuthSuccess: {
                    // This will be called when authentication is successful
                    isAuthenticated = true
                })
            } else {
                // Show main content only if authenticated
                ZStack {
                    mainContent
                }
                .alert("Debug Mode", isPresented: $showingDebugAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Debug mode activated!")
                }
                // Show onboarding if needed (only when authenticated)
                .fullScreenCover(isPresented: $onboardingManager.isShowingOnboarding) {
                    UserOnboardingView(container: modelContext.container)
                        .environmentObject(firebaseSyncService)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .onAppear {
            // Set up auth state listener when ContentView appears
            setupAuthStateListener()
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
