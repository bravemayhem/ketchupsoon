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
                            Text("Meetup View Coming Soon")
                                .foregroundColor(.white)
                                .font(.title)
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
                            UserProfileView()
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [], inMemory: true)
}
