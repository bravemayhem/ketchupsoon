import SwiftUI
import UIKit
import FirebaseStorage
import FirebaseAuth
import OSLog

struct SuccessScreen: View {
    @EnvironmentObject var viewModel: UserOnboardingViewModel
    @EnvironmentObject var onboardingManager: OnboardingManager
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var userProfileManager = UserProfileManager.shared
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isUploadingImage = false
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "SuccessScreen")
    
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
        .onAppear {
            logger.debug("🔍 DEBUG: SuccessScreen appeared with profile data:")
            logger.debug("🔍 DEBUG: - Name: '\(viewModel.profileData.name)'")
            logger.debug("🔍 DEBUG: - Email: '\(viewModel.profileData.email)'")
            logger.debug("🔍 DEBUG: - Bio: '\(viewModel.profileData.bio)'")
            logger.debug("🔍 DEBUG: - Using image avatar: \(viewModel.profileData.useImageAvatar)")
            logger.debug("🔍 DEBUG: - Has image: \(viewModel.profileData.avatarImage != nil)")
        }
    }
    
    private func saveProfileAndContinue() {
        // Create updates dictionary
        Task {
            logger.debug("🔄 DEBUG: Starting profile save process")
            
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
                
                logger.debug("📝 DEBUG: Prepared updates dictionary:")
                logger.debug("📝 DEBUG: - Name: '\(String(describing: updates["name"]))'")
                logger.debug("📝 DEBUG: - Email: '\(String(describing: updates["email"]))'")
                logger.debug("📝 DEBUG: - Bio: '\(String(describing: updates["bio"] ?? "nil"))'")
                
                // Handle profile image - either upload image or use emoji
                if viewModel.profileData.useImageAvatar, let image = viewModel.profileData.avatarImage {
                    // Upload image to Firebase and get URL
                    logger.debug("🖼️ DEBUG: Starting image upload to Firebase Storage")
                    let imageURL = try await uploadProfileImage(image)
                    updates["profileImageURL"] = imageURL
                    logger.debug("🖼️ DEBUG: Image uploaded successfully, URL: \(imageURL)")
                } else {
                    // Use emoji avatar
                    updates["profileImageURL"] = viewModel.profileData.avatarEmoji
                    logger.debug("🖼️ DEBUG: Using emoji avatar: \(viewModel.profileData.avatarEmoji)")
                }
                
                // Parse birthday if provided
                if let birthday = viewModel.profileData.birthday {
                    // Store as timestamp for Firestore
                    updates["birthday"] = birthday.timeIntervalSince1970
                    logger.debug("📅 DEBUG: Adding birthday timestamp: \(birthday.timeIntervalSince1970)")
                }
                
                // Update UserProfileManager
                logger.debug("💾 DEBUG: Updating user profile in UserProfileManager")
                try await userProfileManager.updateUserProfile(updates: updates)
                logger.debug("💾 DEBUG: UserProfileManager update successful")
                
                // Update UserSettings
                logger.debug("⚙️ DEBUG: Updating UserSettings with name: \(viewModel.profileData.name)")
                userSettings.updateName(viewModel.profileData.name)
                
                logger.debug("⚙️ DEBUG: Updating UserSettings with email: \(viewModel.profileData.email)")
                userSettings.updateEmail(viewModel.profileData.email)
                
                // Continue to permissions screen
                await MainActor.run {
                    logger.debug("✅ DEBUG: Profile save complete, continuing to permissions")
                    isUploadingImage = false
                    viewModel.nextStep()
                }
            } catch {
                logger.error("❌ ERROR: Failed to save profile: \(error.localizedDescription)")
                await MainActor.run {
                    isUploadingImage = false
                    showError = true
                    errorMessage = "Could not save profile: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) async throws -> String {
        logger.debug("🖼️ DEBUG: Starting image upload process")
        
        // Resize image for storage efficiency
        guard let resizedImage = image.resized(to: CGSize(width: 500, height: 500)) else {
            logger.error("❌ ERROR: Failed to resize image")
            throw NSError(domain: "SuccessScreen", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not resize image"])
        }
        
        logger.debug("🖼️ DEBUG: Image resized to 500x500")
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            logger.error("❌ ERROR: Failed to convert image to JPEG data")
            throw NSError(domain: "SuccessScreen", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to JPEG data"])
        }
        
        logger.debug("🖼️ DEBUG: Image compressed to JPEG, size: \(imageData.count) bytes")
        
        // Get user ID for storage path
        guard let userId = Auth.auth().currentUser?.uid else {
            logger.error("❌ ERROR: User not authenticated")
            throw NSError(domain: "SuccessScreen", code: 3, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        logger.debug("🖼️ DEBUG: User ID for image storage: \(userId)")
        
        // Create a reference to Firebase Storage
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImagesRef = storageRef.child("profile_images/\(userId).jpg")
        
        logger.debug("🖼️ DEBUG: Uploading to Firebase Storage path: profile_images/\(userId).jpg")
        
        // Upload the image
        _ = try await profileImagesRef.putDataAsync(imageData)
        logger.debug("🖼️ DEBUG: Image upload complete!")
        
        // Get the download URL
        let downloadURL = try await profileImagesRef.downloadURL()
        logger.debug("🖼️ DEBUG: Got download URL: \(downloadURL.absoluteString)")
        
        return downloadURL.absoluteString
    }
} 
