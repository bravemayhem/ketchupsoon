import SwiftUI
import SwiftData
import FirebaseAuth
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SettingsView")


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
    @State private var isCalendarIntegrated = true
    @EnvironmentObject private var firebaseSyncService: FirebaseSyncService
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        ZStack {
            // Use the shared background components and ensure it fills the screen
            CompleteBackground.profile
                .ignoresSafeArea()
            
            // Content layer
            VStack(spacing: 0) {
                // Navigation bar with title and Done button
                HStack {
                    Text("Settings")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.custom("SpaceGrotesk-SemiBold", size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "15103A").opacity(0.7))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Main content in ScrollView
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Profile Section
                        sectionHeader(title: "profile")
                        
                        VStack(spacing: 0) {
                            NavigationLink {
                                ProfileFactory.createProfileView(
                                    for: .currentUser,
                                    modelContext: modelContext,
                                    firebaseSyncService: firebaseSyncService
                                )
                            } label: {
                                menuItem(
                                    title: "Profile Settings",
                                    icon: "person.circle",
                                    iconColor: AppColors.accent,
                                    hasChevron: true,
                                    isLast: false
                                )
                            }
                            
                            Button {
                                showingSignOutAlert = true
                            } label: {
                                menuItem(
                                    title: "Sign Out",
                                    icon: "rectangle.portrait.and.arrow.right",
                                    iconColor: Color(hex: "FF2D55"),
                                    textColor: Color(hex: "FF2D55"),
                                    isLast: true
                                )
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(hex: "15103A").opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .clipped()
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        // App Settings Section
                        sectionHeader(title: "app settings")
                        
                        VStack(spacing: 0) {
                            NavigationLink {
                                NotificationSettingsView()
                                    .environmentObject(firebaseSyncService)
                            } label: {
                                menuItem(
                                    title: "Notifications",
                                    icon: "bell",
                                    hasChevron: true
                                )
                            }
                            
                            appAppearanceItem(selection: $colorSchemeManager.currentAppearanceMode)
                            
                            calendarIntegrationItem(isOn: $isCalendarIntegrated)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(hex: "15103A").opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .clipped()
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        // Data Section (Debug only)
                        #if DEBUG
                        sectionHeader(title: "data")
                        
                        VStack(spacing: 0) {
                            Button {
                                showingClearDataAlert = true
                            } label: {
                                menuItem(
                                    title: "Clear All Data",
                                    icon: "trash",
                                    iconColor: Color(hex: "FF2D55"),
                                    textColor: Color(hex: "FF2D55")
                                )
                            }
                            
                            Button {
                                showingDeleteStoreAlert = true
                            } label: {
                                menuItem(
                                    title: "Delete Data Store",
                                    icon: "trash.slash",
                                    iconColor: Color(hex: "FF2D55"),
                                    textColor: Color(hex: "FF2D55")
                                )
                            }
                            
                            Button {
                                showingResetOnboardingAlert = true
                            } label: {
                                menuItem(
                                    title: "Reset Onboarding",
                                    icon: "arrow.triangle.2.circlepath",
                                    iconColor: Color(hex: "FF2D55"),
                                    textColor: Color(hex: "FF2D55"),
                                    isLast: true
                                )
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(hex: "15103A").opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .clipped()
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                        #endif
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                .background(Color.clear) // Ensure ScrollView has clear background
            }
        }
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task { @MainActor in
                    await clearAllData()
                }
            }
        } message: {
            Text("This will delete all friends and hangouts. This action cannot be undone.")
        }
        .alert("Delete Data Store", isPresented: $showingDeleteStoreAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { @MainActor in
                    await deleteDataStore()
                }
            }
        } message: {
            Text("This will delete the entire data store. This action cannot be undone.")
        }
        .alert("Reset Onboarding", isPresented: $showingResetOnboardingAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                onboardingManager.resetOnboardingAndNavigateToOnboarding()
                dismiss()
            }
        } message: {
            Text("This will reset the onboarding flow and take you to the onboarding process immediately.")
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") {
                errorMessage = nil
            }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred")
        })
        .overlay {
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }
    
    // Helper function to create section headers
    func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.custom("SpaceGrotesk-SemiBold", size: 16))
            .foregroundColor(.white)
            .padding(.top, 10)
            .padding(.bottom, 5)
    }
    
    // Helper function to create menu items
    func menuItem(title: String, icon: String? = nil, iconColor: Color = .white, subtitle: String? = nil, textColor: Color = .white, hasChevron: Bool = false, isLast: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 18))
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("SpaceGrotesk-SemiBold", size: 14))
                        .foregroundColor(textColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.custom("SpaceGrotesk-Regular", size: 12))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                if hasChevron {
                    Text("→")
                        .font(.custom("SpaceGrotesk-Medium", size: 20))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            
            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.leading, 20)
            }
        }
    }
    
    // Helper function for appearance mode picker
    func appAppearanceItem(selection: Binding<AppearanceMode>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .frame(width: 24, height: 24)
                
                Text("Appearance")
                    .font(.custom("SpaceGrotesk-SemiBold", size: 14))
                    .foregroundColor(.white)
                
                Spacer()
                
                Picker("", selection: selection) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName)
                            .tag(mode)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .accentColor(.white)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.leading, 20)
        }
    }
    
    // Calendar integration toggle item with Firebase sync
    func calendarIntegrationItem(isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calendar Integration")
                        .font(.custom("SpaceGrotesk-SemiBold", size: 14))
                        .foregroundColor(.white)
                    
                    Text("Google Calendar")
                        .font(.custom("SpaceGrotesk-Regular", size: 12))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                
                Spacer()
                
                // Custom toggle
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(hex: "15103A").opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .frame(width: 60, height: 30)
                    
                    Circle()
                        .fill(isOn.wrappedValue ? AnyShapeStyle(AppColors.accentGradient) : AnyShapeStyle(Color.gray.opacity(0.5)))
                        .frame(width: 20, height: 20)
                        .offset(x: isOn.wrappedValue ? 15 : -15)
                }
                .onTapGesture {
                    withAnimation(.spring()) {
                        isOn.wrappedValue.toggle()
                        
                        // Save preferences to Firebase when toggled
                        let syncService = firebaseSyncService
                        Task {
                            do {
                                if let user = Auth.auth().currentUser {
                                    try await syncService.updateUserPreference(
                                        userID: user.uid,
                                        key: "calendarIntegration",
                                        value: isOn.wrappedValue
                                    )
                                    logger.info("Updated calendar integration preference in Firebase: \(isOn.wrappedValue)")
                                }
                            } catch {
                                logger.error("Failed to update calendar integration preference: \(error)")
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.leading, 20)
        }
    }
}

// MARK: - Data Management Methods
extension SettingsView {
    /// Clear all data from both local SwiftData and Firebase
    private func clearAllData() async {
        do {
            isLoading = true
            errorMessage = nil
            
            // Clear local data first
            try await clearLocalData()
            
            // Then clear remote data if user is authenticated
            if let user = Auth.auth().currentUser {
                let syncService = firebaseSyncService
                try await syncService.clearAllUserData(userID: user.uid)
                logger.info("Successfully cleared all user data from Firebase for user: \(user.uid)")
            }
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to clear data: \(error.localizedDescription)"
            logger.error("Error clearing data: \(error.localizedDescription)")
        }
    }
    
    /// Clear only local SwiftData
    private func clearLocalData() async throws {
        // Delete all friend data
        let friendsFetchDescriptor = FetchDescriptor<UserModel>()
        let friends = try modelContext.fetch(friendsFetchDescriptor)
        for friend in friends {
            modelContext.delete(friend)
        }
        
        // Delete all friendship data
        let friendshipsFetchDescriptor = FetchDescriptor<FriendshipModel>()
        let friendships = try modelContext.fetch(friendshipsFetchDescriptor)
        for friendship in friendships {
            modelContext.delete(friendship)
        }
        
        // Delete all meetup data
        let meetupsFetchDescriptor = FetchDescriptor<MeetupModel>()
        let meetups = try modelContext.fetch(meetupsFetchDescriptor)
        for meetup in meetups {
            modelContext.delete(meetup)
        }
        
        // Save changes
        try modelContext.save()
        logger.info("Successfully cleared local data")
    }
    
    /// Delete the entire data store (debug only)
    private func deleteDataStore() async {
        do {
            isLoading = true
            errorMessage = nil
            
            // First clear the data
            try await clearLocalData()
            
            // Then attempt to remove the SwiftData container if possible
            // This is limited by SwiftData's API - full deletion may require app reinstall
            try await Task.sleep(nanoseconds: 1_000_000_000) // Brief delay to ensure saves complete
            
            // Log success
            logger.info("Successfully attempted to delete data store")
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to delete data store: \(error.localizedDescription)"
            logger.error("Error deleting data store: \(error.localizedDescription)")
        }
    }
}

// MARK: - Authentication Methods
extension SettingsView {
    private func signOut() async {
        do {
            isLoading = true
            errorMessage = nil
            
            // Use SocialAuthManager for sign out since it handles both Firebase Auth
            // and updating profile status
            try await socialAuthManager.signOut()
            
            // Close the settings view after signing out
            dismiss()
            
            logger.info("User successfully signed out")
        } catch {
            isLoading = false
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
            logger.error("Error signing out: \(error.localizedDescription)")
        }
    }
}

// Preview provider
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let previewContainer = try! ModelContainer(for: UserModel.self, FriendshipModel.self, MeetupModel.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        return SettingsView()
            .modelContainer(previewContainer)
            .environmentObject(FirebaseSyncServiceFactory.preview)
            .preferredColorScheme(.dark)
    }
}
