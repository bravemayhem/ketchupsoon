import SwiftUI

struct SocialProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var socialAuthManager = SocialAuthManager.shared
    
    @State private var isSocialProfileActive: Bool = false
    @State private var showActivationSheet = false
    @State private var showAuthMethodsSheet = false
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showSignOutConfirm = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Social Profile", isOn: $isSocialProfileActive)
                    .onChange(of: isSocialProfileActive) { oldValue, newValue in
                        if newValue && !oldValue {
                            // User toggled social profile on
                            if socialAuthManager.isAuthenticated {
                                // Already authenticated, show activation info
                                showActivationSheet = true
                            } else {
                                // Need to authenticate first
                                showAuthMethodsSheet = true
                            }
                        } else if !newValue && oldValue {
                            // User toggled social profile off
                            Task {
                                do {
                                    try await socialAuthManager.deactivateSocialProfile()
                                    // We're just deactivating, not signing out
                                } catch {
                                    await MainActor.run {
                                        alertMessage = "Error deactivating profile: \(error.localizedDescription)"
                                        showAlert = true
                                        // Revert toggle if deactivation failed
                                        isSocialProfileActive = true
                                    }
                                }
                            }
                        }
                    }
            } footer: {
                Text("Activating the social profile will allow Ketchup Soon to suggest hangouts with friends who also have social profiles.")
            }
            
            if isSocialProfileActive, let authProvider = socialAuthManager.authProvider {
                Section("Authentication") {
                    HStack {
                        Image(systemName: authProvider.iconName)
                            .foregroundColor(AppColors.accent)
                        
                        VStack(alignment: .leading) {
                            Text("Signed in with \(authProvider.displayName)")
                                .font(.subheadline)
                            
                            if let email = socialAuthManager.currentUser?.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }
            }
            
            if isSocialProfileActive {
                Section {
                    Button(action: saveProfile) {
                        HStack {
                            Spacer()
                            if isUpdating {
                                ProgressView()
                            } else {
                                Text("Save Social Profile")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isUpdating)
                }
            }
        }
        .navigationTitle("Social Profile")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadProfileData()
        }
        .sheet(isPresented: $showActivationSheet) {
            SocialProfileActivationView(onActivate: {
                showActivationSheet = false
                saveProfile()
            }, onCancel: {
                isSocialProfileActive = false
                showActivationSheet = false
            })
        }
        .sheet(isPresented: $showAuthMethodsSheet, onDismiss: {
            // If sheet is dismissed without success, revert the toggle
            if !socialAuthManager.isAuthenticated {
                isSocialProfileActive = false
            } else {
                // Show activation info after authentication
                showActivationSheet = true
            }
        }) {
            AuthMethodSelectionView(onCompletion: {
                showAuthMethodsSheet = false
            }, onCancel: {
                isSocialProfileActive = false
                showAuthMethodsSheet = false
            })
        }
        .alert("Profile Update", isPresented: $showAlert) {
            Button("OK") { showAlert = false }
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog(
            "Sign Out from Social Profile",
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will be signed out from your social profile. Your profile will be deactivated until you sign in again.")
        }
    }
    
    private func loadProfileData() {
        guard let profile = profileManager.currentUserProfile else { return }
        isSocialProfileActive = profile.isSocialProfileActive
    }
    
    private func saveProfile() {
        isUpdating = true
        
        // Build updates dictionary with just the social profile flag
        let updates: [String: Any] = [
            "isSocialProfileActive": isSocialProfileActive
        ]
        
        // Update profile in Firestore
        Task {
            do {
                try await profileManager.updateUserProfile(updates: updates)
                await MainActor.run {
                    isUpdating = false
                    alertMessage = "Social profile updated successfully"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    alertMessage = "Error updating profile: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func signOut() {
        Task {
            do {
                // First deactivate the profile
                try await socialAuthManager.deactivateSocialProfile()
                
                // Then sign out
                try await socialAuthManager.signOut()
                
                await MainActor.run {
                    isSocialProfileActive = false
                    alertMessage = "Signed out successfully"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Error signing out: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

struct SocialProfileActivationView: View {
    var onActivate: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.2.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(AppColors.accent)
                    .padding()
                
                Text("Activate Social Profile")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Creating a social profile will unlock enhanced features:")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 5)
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "person.3.fill", text: "Connect with friends more easily")
                    FeatureRow(icon: "bell", text: "Smart reminders for staying in touch")
                }
                .padding(.horizontal)
                
                Text("Your information is only shared with friends you explicitly connect with.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                HStack(spacing: 20) {
                    Button(action: onCancel) {
                        Text("Not Now")
                            .fontWeight(.medium)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    
                    Button(action: onActivate) {
                        Text("Activate")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppColors.accent)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.accent)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    NavigationStack {
        SocialProfileView()
    }
} 