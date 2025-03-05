import SwiftUI

struct SocialProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var socialAuthManager = SocialAuthManager.shared
    
    @State private var showAuthMethodsSheet = false
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showSignOutConfirm = false
    
    var body: some View {
        Form {
            Section {
                if socialAuthManager.isAuthenticated {
                    // When authenticated, show the provider and status
                    if let authProvider = socialAuthManager.authProvider {
                        HStack {
                            Image(systemName: authProvider.iconName)
                                .foregroundColor(AppColors.accent)
                                .font(.title3)
                            
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
                            
                            Text("Active")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppColors.accent.opacity(0.2))
                                .foregroundColor(AppColors.accent)
                                .cornerRadius(8)
                        }
                        .padding(.vertical, 4)
                    }
                    
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
                } else {
                    // When not authenticated, show a button to sign in
                    Button {
                        showAuthMethodsSheet = true
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "person.fill.badge.plus")
                            Text("Sign In to Activate Social Profile")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            } footer: {
                Text("The social profile enables Ketchup Soon to suggest hangouts with friends who also have social profiles. Your information is only shared with friends you explicitly connect with.")
            }
        }
        .navigationTitle("Social Profile")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Check if we have the latest data
            if let userId = socialAuthManager.currentUser?.uid {
                Task {
                    await profileManager.fetchUserProfile(userId: userId)
                }
            }
        }
        .sheet(isPresented: $showAuthMethodsSheet) {
            AuthMethodSelectionView(onCompletion: {
                showAuthMethodsSheet = false
                
                // After authentication, update profile
                if socialAuthManager.isAuthenticated {
                    updateProfileAfterSignIn()
                }
            }, onCancel: {
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
            Text("You will be signed out from your social profile. Your social profile will be deactivated until you sign in again.")
        }
    }
    
    private func updateProfileAfterSignIn() {
        isUpdating = true
        
        Task {
            // Refresh the profile data to ensure everything is in sync
            if let userId = socialAuthManager.currentUser?.uid {
                await profileManager.fetchUserProfile(userId: userId)
            }
            
            await MainActor.run {
                isUpdating = false
                alertMessage = "Social profile activated successfully"
                showAlert = true
            }
        }
    }
    
    private func signOut() {
        Task {
            do {
                try await socialAuthManager.signOut()
                
                await MainActor.run {
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

#Preview {
    NavigationStack {
        SocialProfileView()
    }
} 

