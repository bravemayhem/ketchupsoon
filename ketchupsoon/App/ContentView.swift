import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var onboardingManager: OnboardingManager
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
                        // Home tab (emoji: 🏠)
                        CustomNavigationBarContainer(
                            title: "Home",
                            subtitle: "Your friends",
                            showLeadingButton: true,
                            showTrailingButton: true,
                            leadingIcon: "gear",
                            trailingIcon: "plus",
                            leadingButtonAction: {
                                showingSettings = true
                            },
                            trailingButtonAction: {
                                showingContactPicker = true
                            },
                            enableDebugMode: true,
                            debugModeAction: {
                                showingDebugAlert = true
                            },
                            profileEmoji: "👋"
                        ) {
                            HomeView()
                        }
                        .transition(.opacity)
                        .sheet(isPresented: $showingSettings) {
                            SettingsView()
                        }
                    }
                    else if selectedTab == 1 {
                        // Pulse tab (emoji: 📅)
                        CustomNavigationBarContainer(
                            title: "Pulse",
                            subtitle: "Schedule ketchups",
                            showLeadingButton: true,
                            showTrailingButton: true,
                            leadingIcon: "gear",
                            trailingIcon: "calendar.badge.plus",
                            leadingButtonAction: {
                                showingSettings = true
                            },
                            trailingButtonAction: {
                                // Calendar action
                            },
                            profileEmoji: "📆"
                        ) {
                            Text("Pulse View Coming Soon")
                                .foregroundColor(.white)
                                .font(.title)
                        }
                        .transition(.opacity)
                        .sheet(isPresented: $showingSettings) {
                            SettingsView()
                        }
                    }
                    else if selectedTab == 2 {
                        // Other tab content
                        CustomNavigationBarContainer(
                            title: "Profile",
                            subtitle: "Your account",
                            showLeadingButton: true,
                            showTrailingButton: false,
                            leadingIcon: "gear",
                            leadingButtonAction: {
                                showingSettings = true
                            },
                            profileEmoji: "👤"
                        ) {
                            Text("Profile View Coming Soon")
                                .foregroundColor(.white)
                                .font(.title)
                        }
                        .transition(.opacity)
                        .sheet(isPresented: $showingSettings) {
                            SettingsView()
                        }
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [], inMemory: true)
}
