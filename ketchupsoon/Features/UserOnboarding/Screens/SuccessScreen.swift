import SwiftUI
import UIKit
import FirebaseStorage
import FirebaseAuth

struct SuccessScreen: View {
    @EnvironmentObject var viewModel: KetchupSoonOnboardingViewModel
    @EnvironmentObject var onboardingManager: OnboardingManager
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var userProfileManager = UserProfileManager.shared
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isUploadingImage = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 20)
                    
                    // Success checkmark
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(UIColor(red: 100/255, green: 66/255, blue: 255/255, alpha: 1.0)),
                                        Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0))
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(UIColor(red: 100/255, green: 66/255, blue: 255/255, alpha: 0.3)), radius: 12)
                        
                        Text("✓")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 20)
                    
                    Text("Profile Created!")
                        .font(.custom("SpaceGrotesk-Bold", size: 24))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    
                    Text("You're all set to start connecting")
                        .font(.custom("SpaceGrotesk-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 30)
                    
                    // Profile card preview
                    ProfileCardPreview(profileData: viewModel.profileData)
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
            }
            
            // Final action button
            VStack {
                Button {
                    // Save profile data and move to permissions
                    saveProfileAndContinue()
                } label: {
                    if isUploadingImage {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text("Next: Setup Permissions")
                            .font(.custom("SpaceGrotesk-SemiBold", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .disabled(isUploadingImage)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)),
                            Color(UIColor(red: 255/255, green: 138/255, blue: 66/255, alpha: 1.0))
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 0.3)), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(UIColor(red: 13/255, green: 10/255, blue: 34/255, alpha: 0.8)))
        }
        .alert("Error Saving Profile", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveProfileAndContinue() {
        // Create updates dictionary
        Task {
            await MainActor.run {
                isUploadingImage = true
            }
            
            do {
                var updates = [String: Any]()
                updates["name"] = viewModel.profileData.name
                updates["email"] = viewModel.profileData.email
                if !viewModel.profileData.bio.isEmpty {
                    updates["bio"] = viewModel.profileData.bio
                }
                
                // Handle profile image - either upload image or use emoji
                if viewModel.profileData.useImageAvatar, let image = viewModel.profileData.avatarImage {
                    // Upload image to Firebase and get URL
                    let imageURL = try await uploadProfileImage(image)
                    updates["profileImageURL"] = imageURL
                } else {
                    // Use emoji avatar
                    updates["profileImageURL"] = viewModel.profileData.avatarEmoji
                }
                
                // Parse birthday if provided
                if let birthday = viewModel.profileData.birthday {
                    // Store as timestamp for Firestore
                    updates["birthday"] = birthday.timeIntervalSince1970
                }
                
                // Update UserProfileManager
                try await userProfileManager.updateUserProfile(updates: updates)
                
                // Update UserSettings
                userSettings.updateName(viewModel.profileData.name)
                userSettings.updateEmail(viewModel.profileData.email)
                
                // Continue to permissions screen
                await MainActor.run {
                    isUploadingImage = false
                    viewModel.nextStep()
                }
            } catch {
                await MainActor.run {
                    isUploadingImage = false
                    showError = true
                    errorMessage = "Could not save profile: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) async throws -> String {
        // Resize image for storage efficiency
        guard let resizedImage = image.resized(to: CGSize(width: 500, height: 500)) else {
            throw NSError(domain: "SuccessScreen", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not resize image"])
        }
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "SuccessScreen", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to JPEG data"])
        }
        
        // Get user ID for storage path
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "SuccessScreen", code: 3, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Create a reference to Firebase Storage
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImagesRef = storageRef.child("profile_images/\(userId).jpg")
        
        // Upload the image
        _ = try await profileImagesRef.putDataAsync(imageData)
        
        // Get the download URL
        let downloadURL = try await profileImagesRef.downloadURL()
        return downloadURL.absoluteString
    }
} 