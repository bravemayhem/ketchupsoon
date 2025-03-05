import SwiftUI

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var profileManager = UserProfileManager.shared
    
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var bio: String = ""
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section {
                if let photoURL = profileManager.currentUserProfile?.profileImageURL,
                   !photoURL.isEmpty {
                    HStack {
                        Spacer()
                        AsyncImage(url: URL(string: photoURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .padding(.vertical, 8)
                        Spacer()
                    }
                }
                
                HStack {
                    Text("Name")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $name)
                        .multilineTextAlignment(.trailing)
                        .textContentType(.name)
                }
                
                HStack {
                    Text("Email")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $email)
                        .multilineTextAlignment(.trailing)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                HStack {
                    Text("Phone")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $phoneNumber)
                        .multilineTextAlignment(.trailing)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                HStack {
                    Text("Bio")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $bio)
                        .multilineTextAlignment(.trailing)
                }
            } header: {
                Text("PROFILE INFORMATION")
            } footer: {
                Text("Your phone number is required to create hangouts. This helps your friends identify you when they receive invites.")
            }
            
            Section {
                Button(action: saveProfile) {
                    HStack {
                        Spacer()
                        if isUpdating {
                            ProgressView()
                        } else {
                            Text("Save Profile")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(isUpdating)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadProfileData()
        }
        .alert("Profile Update", isPresented: $showAlert) {
            Button("OK") { showAlert = false }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadProfileData() {
        // Load from profile manager if available
        if let profile = profileManager.currentUserProfile {
            name = profile.name ?? ""
            email = profile.email ?? ""
            phoneNumber = profile.phoneNumber ?? ""
            bio = profile.bio ?? ""
        } else {
            // Fall back to UserSettings
            name = userSettings.name ?? ""
            phoneNumber = userSettings.phoneNumber ?? ""
            email = userSettings.email ?? ""
        }
    }
    
    private func saveProfile() {
        isUpdating = true
        
        // Build updates dictionary
        var updates: [String: Any] = [:]
        
        if !name.isEmpty {
            updates["name"] = name
        }
        
        if !email.isEmpty {
            updates["email"] = email
        }
        
        if !phoneNumber.isEmpty {
            updates["phoneNumber"] = phoneNumber
        }
        
        if !bio.isEmpty {
            updates["bio"] = bio
        }
        
        // Also update UserSettings
        userSettings.updateName(name.isEmpty ? nil : name)
        userSettings.updateEmail(email.isEmpty ? nil : email)
        userSettings.updatePhoneNumber(phoneNumber.isEmpty ? nil : phoneNumber)
        
        // Update profile in Firestore
        Task {
            do {
                try await profileManager.updateUserProfile(updates: updates)
                await MainActor.run {
                    isUpdating = false
                    alertMessage = "Profile updated successfully"
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
}

#Preview {
    NavigationStack {
        ProfileSettingsView()
    }
} 