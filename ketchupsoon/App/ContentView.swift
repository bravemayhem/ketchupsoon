import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var onboardingManager: OnboardingManager
    @EnvironmentObject private var appState: AppState
    
    // Change from computed property to @State property with didSet
    @State private var selectedTabIndex: Int = 0 {
        didSet {
            // Update appState when the tab changes
            switch selectedTabIndex {
            case 0: appState.selectedTab = .home
            case 1: appState.selectedTab = .createMeetup
            case 2: appState.selectedTab = .notifications
            case 3: appState.selectedTab = .profile
            default: appState.selectedTab = .home
            }
        }
    }
    
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
                    if selectedTabIndex == 0 {
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
                            HomeView()
                        }
                        .transition(.opacity)
                        .sheet(isPresented: $showingSettings) {
                            SettingsView()
                        }
                    }
                    else if selectedTabIndex == 1 {
                        // Create Meetup tab
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
                            CreateMeetupView()
                        }
                        .transition(.opacity)
                        .sheet(isPresented: $showingSettings) {
                            SettingsView()
                        }
                    }
                    else if selectedTabIndex == 2 {
                        // Notifications tab
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
                            PulseView()
                        }
                        .transition(.opacity)
                        .sheet(isPresented: $showingSettings) {
                            SettingsView()
                        }
                    }
                    else if selectedTabIndex == 3 {
                        // Profile tab
                        CustomNavigationBarContainer(
                            showLeadingButton: false,
                            showTrailingButton: false,
                            profileEmoji: "😎"
                        ) {
                            UserProfileView()
                        }
                        .transition(.opacity)
                    }
                }
            }
            // Apply our custom tab bar
            .withCustomTabBar(selectedTab: selectedTabIndex) { tab in
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTabIndex = tab
                }
            }
        }
        .alert("Debug Mode", isPresented: $showingDebugAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Debug mode activated!")
        }
        .onAppear {
            // Initialize the tab index based on appState when the view appears
            switch appState.selectedTab {
            case .home: selectedTabIndex = 0
            case .createMeetup: selectedTabIndex = 1
            case .notifications: selectedTabIndex = 2
            case .profile: selectedTabIndex = 3
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [], inMemory: true)
        .environmentObject(AppState())
        .environmentObject(OnboardingManager.shared) // Use the shared instance
}
