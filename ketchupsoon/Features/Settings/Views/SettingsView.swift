import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var colorSchemeManager = ColorSchemeManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var showingClearDataAlert = false
    @State private var showingDeleteStoreAlert = false
    @State private var showingResetOnboardingAlert = false
    @StateObject private var socialAuthManager = SocialAuthManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    NavigationLink {
                        ProfileSettingsView()
                    } label: {
                        Label {
                            Text("Profile Settings")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "person.circle")
                                .foregroundColor(AppColors.accent)
                        }
                    }
                }
                
                Section("App Settings") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    
                    Picker(selection: $colorSchemeManager.currentAppearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.displayName)
                                .tag(mode)
                        }
                    } label: {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                    }
                }
                
                // Only show Data section in debug builds, not in TestFlight or production
#if DEBUG
                Section("Data") {
                    Button(role: .destructive) {
                        showingClearDataAlert = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteStoreAlert = true
                    } label: {
                        Label("Delete Data Store", systemImage: "trash.slash")
                    }
                    
                    Button(role: .destructive) {
                        showingResetOnboardingAlert = true
                    } label: {
                        Label("Reset Onboarding", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
#endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    Task { @MainActor in
      //                 await clearAllData()
                    }
                }
            } message: {
                Text("This will delete all friends and hangouts. This action cannot be undone.")
            }
            .alert("Delete Data Store", isPresented: $showingDeleteStoreAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task { @MainActor in
        //              await deleteDataStore()
                    }
                }
            } message: {
                Text("This will delete the entire data store. This action cannot be undone.")
            }
            .alert("Reset Onboarding", isPresented: $showingResetOnboardingAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    onboardingManager.resetOnboarding()
                    dismiss()
                }
            } message: {
                Text("This will reset the onboarding flow and show it again the next time you open the app.")
            }
        }
    }
    
    /*
     private func clearAllData() async {
     
     
     private func deleteDataStore() async {
     
     }
     
     */
    
}
