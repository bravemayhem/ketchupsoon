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
            Task<Void, Never>(priority: .userInitiated) { @MainActor in
                self.isAuthenticated = user != nil
                self.hasCheckedAuth = true
                
                // Reset auth choice screens when auth state changes
                if user == nil {
                    // If user becomes unauthenticated, show the auth choice screen again
                    withAnimation {
                        showingAuthChoiceScreen = true
                        showingCreateAccount = false
                    }
                } else {
                    // If user becomes authenticated, hide auth choice screens
                    withAnimation {
                        showingAuthChoiceScreen = false
                        showingCreateAccount = false
                    }
                    
                    // Check if the user profile is incomplete
                    let userSettings = UserSettings.shared
                    let hasIncompleteProfile = userSettings.name.isNilOrEmpty
                    
                    // If user profile is incomplete and we're not already in onboarding, force onboarding
                    if hasIncompleteProfile && !onboardingManager.isCurrentlyOnboarding {
                        onboardingManager.resetOnboarding()
                    }
                    
                    // Only sync data when authenticated
                    self.syncAndCacheProfileOnAppear()
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
    
    // State to handle auth choice screen
    @State private var showingAuthChoiceScreen = false
    @State private var showingCreateAccount = false
    
    var body: some View {
        Group {
            if !hasCheckedAuth {
                // Show loading view until auth check completes
                loadingView
            } else if !isAuthenticated {
                // Show auth choice screen for non-authenticated users
                if showingCreateAccount {
                    // Show onboarding view for new users
                    UserOnboardingView(
                        container: modelContext.container,
                        dismissAction: { showingCreateAccount = false }
                    )
                        .environmentObject(firebaseSyncService)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                } else {
                    // Show auth choice or auth view
                    if showingAuthChoiceScreen {
                        // Display auth choice screen with sign in and create account options
                        ZStack {
                            // Background gradient
                            AppColors.backgroundGradient
                                .ignoresSafeArea()
                            
                            VStack(spacing: 30) {
                                Spacer()
                                
                                // App logo
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
                              /*
                                // Placeholder for a subtitle
                                Text("")
                                    .font(.custom("SpaceGrotesk-Regular", size: 18))
                                    .foregroundColor(.white.opacity(0.8))
                               */
                               
                                Spacer()
                                
                                // Sign In Button
                                Button(action: {
                                    // Go to sign in (AuthView)
                                    showingAuthChoiceScreen = false
                                }) {
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                        
                                        Text("Sign In")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(AppColors.accentGradient1)
                                    )
                                    .glow(color: AppColors.accent, radius: 5)
                                }
                                .padding(.horizontal, 30)
                                
                                // Create Account Button
                                Button(action: {
                                    // Go directly to onboarding flow
                                    showingCreateAccount = true
                                }) {
                                    HStack {
                                        Image(systemName: "person.badge.plus")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                        
                                        Text("Create New Account")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(AppColors.cardBackground)
                                            .clayMorphism()
                                    )
                                }
                                .padding(.horizontal, 30)
                                
                                Spacer()
                            }
                            .padding()
                        }
                        .transition(.opacity)
                    } else {
                        // Show regular auth view for sign in
                        AuthView(onAuthSuccess: {
                            // This will be called when authentication is successful
                            isAuthenticated = true
                        }, onBackButtonTapped: {
                            // Return to auth choice screen when back button is tapped
                            withAnimation {
                                showingAuthChoiceScreen = true
                            }
                        })
                        .transition(.opacity)
                    }
                }
            } else {
                // Show main content only if authenticated
                ZStack {
                    mainContent
                }
                .alert("Debug Mode", isPresented: $showingDebugAlert) {
                    Button("Reset Onboarding State", role: .destructive) {
                        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                        onboardingManager.resetOnboardingAndNavigateToOnboarding()
                        print("DEBUG: Reset onboarding state to false")
                    }
                    
                    Button("Clear All UserDefaults", role: .destructive) {
                        let domain = Bundle.main.bundleIdentifier!
                        
                        // Clear UserDefaults
                        UserDefaults.standard.removePersistentDomain(forName: domain)
                        UserDefaults.standard.synchronize()
                        
                        // Also clear UserSettings keychain data
                        UserSettings.shared.clearAll()
                        
                        print("DEBUG: Cleared all UserDefaults and UserSettings data")
                    }
                    
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Debug options for testing:")
                }
                // Show onboarding if needed (only when authenticated)
                .fullScreenCover(isPresented: $onboardingManager.isShowingOnboarding) {
                    UserOnboardingView(
                        container: modelContext.container,
                        dismissAction: { onboardingManager.isShowingOnboarding = false }
                    )
                        .environmentObject(firebaseSyncService)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .onAppear {
            // Set up auth state listener when ContentView appears
            setupAuthStateListener()
            
            // If not authenticated, show the auth choice screen
            if !isAuthenticated && hasCheckedAuth {
                withAnimation {
                    showingAuthChoiceScreen = true
                }
            }
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
