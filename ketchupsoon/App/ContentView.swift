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
    
    var body: some View {
        ZStack {
            // Content based on selected tab - replacing TabView with our custom implementation
            ZStack {
                // Background
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                // Tab content based on selection
                Group {
                    if selectedTab == 0 {
                        // Home tab
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
                    else if selectedTab == 1 {
                        // Pulse tab
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
                    else if selectedTab == 2 {
                        // Meetup tab
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
                    else if selectedTab == 3 {
                        // Profile tab
                        CustomNavigationBarContainer(
                            showLeadingButton: false,
                            showTrailingButton: false,
                            profileEmoji: "😎"
                        ) {
                            // FIREBASE REQUIREMENT: Profile tab
                            // - Critical: Uses FirebaseSyncService for user profile management
                            // - Uses FirestoreListenerService indirectly for friend status updates
                            // - Primary interface for friendship operations
                            UserProfileView()
                                .environmentObject(firebaseSyncService)
                        }
                        .transition(.opacity)
                    }
                }
            }
            // Apply our custom tab bar
            .withCustomTabBar(selectedTab: selectedTab) { tab in
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = tab
                }
            }
        }
        .alert("Debug Mode", isPresented: $showingDebugAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Debug mode activated!")
        }
        // Add back the fullScreenCover to show onboarding when isShowingOnboarding becomes true
        .fullScreenCover(isPresented: $onboardingManager.isShowingOnboarding) {
            UserOnboardingView(container: modelContext.container)
                .environmentObject(firebaseSyncService)
                .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            // Sync Firebase data when ContentView appears if user is logged in
            if Auth.auth().currentUser != nil {
                Task {
                    await firebaseSyncService.performFullSync()
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
