// Primary purpose: UI state management for the onboarding flow
// Contains a temporary ProfileData struct that collects information during onboarding
// Eventually transforms this temporary data into a UserModel at the end of the flow

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftData
import OSLog

@MainActor
class UserOnboardingViewModel: ObservableObject {
    private let container: ModelContainer
    private let userRepository: UserRepository
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "UserOnboardingViewModel")
    
    // Initialize with the container
    init(container: ModelContainer) {
        self.container = container
        self.userRepository = UserRepositoryFactory.createRepository(modelContext: container.mainContext)
    }

    // Current step in the onboarding flow
    @Published var currentStep = 0
    
    // Authentication state
    @Published var phoneNumber = ""
    @Published var formattedPhoneNumber = ""
    @Published var verificationCode = ""
    @Published var verificationID: String?
    @Published var isVerifying = false
    @Published var isVerified = false
    @Published var showVerificationView = false
    @Published var authError: Error?
    @Published var showingError = false
    
    // Processing state
    @Published var isProcessingProfile = false
    
    // Image picker state
    @Published var showImagePicker = false
    @Published var sourceType: UIImagePickerController.SourceType = .camera
    
    // User profile data
    @Published var profileData = ProfileData()
    
    // Add new properties for handling existing accounts
    @Published var existingAccountFound = false
    @Published var existingUserId: String? = nil
    @Published var showExistingAccountAlert = false
    
    // Profile data structure
    struct ProfileData {
        var name: String = ""
        var birthday: Date? = nil
        var email: String = ""
        var bio: String = ""
        var avatarEmoji: String = "🌟"
        var avatarImage: UIImage? = nil
        var useImageAvatar: Bool = false
    }
    
    // Navigation methods
    func nextStep() {
        if currentStep < 5 {
            withAnimation {
                currentStep += 1
            }
        }
    }
    
    func previousStep() {
        if currentStep > 0 {
            withAnimation {
                currentStep -= 1
            }
        }
    }
    
    // Go to specific step
    func goToStep(_ step: Int) {
        if step >= 0 && step <= 5 {
            withAnimation {
                currentStep = step
            }
        }
    }
    
    // MARK: - Phone Authentication
    
    // Format phone number for display
    func formatPhoneNumber(_ input: String) -> String {
        // Only keep digits
        let cleaned = input.filter { $0.isNumber }
        // Store raw digits for authentication
        phoneNumber = cleaned
        
        // Format as (XXX) XXX-XXXX
        var formatted = ""
        for (index, character) in cleaned.enumerated() {
            if index == 0 {
                formatted += "("
            }
            if index == 3 {
                formatted += ") "
            }
            if index == 6 {
                formatted += "-"
            }
            if index < 10 { // Limit to 10 digits
                formatted.append(character)
            }
        }
        return formatted
    }
    
    // Request verification code
    func requestVerificationCode() {
        // Ensure there's a valid phone number
        guard !phoneNumber.isEmpty, phoneNumber.filter({ $0.isNumber }).count == 10 else {
            self.authError = NSError(domain: "com.ketchupsoon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid 10-digit phone number"])
            self.showingError = true
            return
        }
        
        isVerifying = true
        let fullPhoneNumber = "+1\(phoneNumber)" // Assuming US numbers, add country code logic as needed
        
        // Request verification code from Firebase
        PhoneAuthProvider.provider().verifyPhoneNumber(fullPhoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
            DispatchQueue.main.async {
                self?.isVerifying = false
                
                if let error = error {
                    self?.authError = error
                    self?.showingError = true
                    return
                }
                
                // Store verification ID for later use
                self?.verificationID = verificationID
                self?.showVerificationView = true
            }
        }
    }
    
    // Verify code and sign in
    func verifyCode() {
        guard let verificationID = verificationID, !verificationCode.isEmpty else {
            self.authError = NSError(domain: "com.ketchupsoon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Please enter the verification code"])
            self.showingError = true
            return
        }
        
        isVerifying = true
        
        // Create credential
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        
        // Sign in with credential
        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
            guard let self = self else { return }
            
            Task { @MainActor in
                defer {
                    self.isVerifying = false
                }
                
                if let error = error {
                    self.authError = error
                    self.showingError = true
                    return
                }
                
                // Check if this phone number already has an account
                do {
                    let (exists, userId) = try await self.userRepository.checkPhoneNumberExists(self.phoneNumber)
                    
                    if exists, let existingUserId = userId {
                        // An account with this phone number already exists
                        self.logger.info("Found existing account with phone number \(self.phoneNumber), user ID: \(existingUserId)")
                        
                        // Store the existing user ID
                        self.existingAccountFound = true
                        self.existingUserId = existingUserId
                        
                        // Check if the current authenticated user has the same ID
                        if let currentUser = Auth.auth().currentUser, currentUser.uid == existingUserId {
                            // Already signed in to the existing account
                            self.logger.info("Already signed in to existing account")
                            
                            // Save the phone number
                            self.savePhoneNumber()
                            self.isVerified = true
                            
                            // Show alert about existing account
                            self.showExistingAccountAlert = true
                        } else {
                            // Need to sign in to the existing account
                            self.logger.info("Need to sign in to existing account")
                            
                            // Attempting to automatically sign in to the correct account
                            try await self.signInToExistingAccount(userId: existingUserId)
                        }
                        
                        return
                    }
                    
                    // No existing account found, continue with new account flow
                    self.logger.info("No existing account found, continuing with new account creation")
                    self.isVerified = true
                    self.savePhoneNumber()
                    
                    // IMPORTANT: Make sure we're setting the current step directly rather than letting 
                    // another process update it. This ensures we move forward in the flow.
                    let currentStep = self.currentStep
                    if currentStep == 1 {
                        self.logger.info("Advancing to next step of onboarding (step 2)")
                        self.goToStep(2)
                    } else {
                        self.logger.info("Not on expected step (expected 1, got \(currentStep)). Moving to step 2.")
                        self.goToStep(2)
                    }
                    
                } catch {
                    self.logger.error("Error checking for existing account: \(error.localizedDescription)")
                    self.authError = error
                    self.showingError = true
                }
            }
        }
    }
    
    // New method to sign in to an existing account
    private func signInToExistingAccount(userId: String) async throws {
        // This is a bit tricky since we've already authenticated with Firebase Auth
        // but with potentially a different UID
        
        // We need to store that this phone number is associated with the existing userId
        logger.info("Signing in to existing account with ID: \(userId)")
        
        // Store the existing user ID for reference
        existingUserId = userId
        
        // Save the phone number
        savePhoneNumber()
        isVerified = true
        
        // Show the alert to inform the user about the existing account
        showExistingAccountAlert = true
    }
    
    // Function to handle what happens when user acknowledges they have an existing account
    func handleExistingAccountConfirmation() {
        // Clear any new account data
        self.profileData = ProfileData()
        
        // Mark the user as verified
        self.isVerified = true
        
        // Skip to the success screen
        self.goToStep(4)
        
        logger.info("User confirmed existing account, moving to the success screen")
    }
    
    // Save authenticated phone number to user profile
    private func savePhoneNumber() {
        // Add code to save the verified phone number to UserSettings or other user data store
        UserSettings.shared.updatePhoneNumber(phoneNumber)
    }
    
    // MARK: - Avatar Methods
    
    // Set avatar to use emoji
    func setEmojiAvatar(_ emoji: String) {
        profileData.avatarEmoji = emoji
        profileData.useImageAvatar = false
        logger.debug("🧩 DEBUG: Set emoji avatar to \(emoji), useImageAvatar=false")
    }
    
    // Set avatar to use image
    func setImageAvatar(_ image: UIImage) {
        profileData.avatarImage = image
        profileData.useImageAvatar = true
        logger.debug("DEBUG: Set image avatar, useImageAvatar=true, image size: \(String(describing: image.size))")
    }
    
    // Show camera for taking photo
    func showCamera() {
        sourceType = .camera
        showImagePicker = true
    }
    
    // Show photo library for choosing image
    func showPhotoLibrary() {
        sourceType = .photoLibrary
        showImagePicker = true
    }
    
    // MARK: - Profile Creation
    
    /// Create and save user profile to both SwiftData and Firebase
    @MainActor // Mark this method as running on the Main actor
    func completeOnboarding() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            logger.error("❌ ERROR: User not authenticated")
            throw NSError(domain: "com.ketchupsoon", code: 3, 
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Log collected data
        logger.debug("📝 DEBUG: Profile creation started for user \(userId)")
        logger.debug("📝 DEBUG: Profile data collected:")
        logger.debug("📝 DEBUG: - Name: '\(self.profileData.name)'")
        logger.debug("📝 DEBUG: - Email: '\(self.profileData.email)'")
        logger.debug("📝 DEBUG: - Bio: '\(self.profileData.bio)'")
        logger.debug("📝 DEBUG: - Phone: '\(self.phoneNumber)'")
        logger.debug("📝 DEBUG: - Birthday: \(self.profileData.birthday?.description ?? "nil")")
        logger.debug("📝 DEBUG: - Using image avatar: \(self.profileData.useImageAvatar)")
        logger.debug("📝 DEBUG: - Avatar emoji: \(self.profileData.avatarEmoji)")
        logger.debug("📝 DEBUG: - Avatar image exists: \(self.profileData.avatarImage != nil)")
        
        // Create UserModel from collected data with all required fields
        let newUser = UserModel(
            id: userId,
            name: self.profileData.name.isEmpty ? nil : self.profileData.name,
            profileImageURL: nil, // Will be updated after image upload if needed
            email: self.profileData.email.isEmpty ? nil : self.profileData.email,
            phoneNumber: self.phoneNumber.isEmpty ? nil : self.phoneNumber,
            bio: self.profileData.bio.isEmpty ? nil : self.profileData.bio,
            birthday: self.profileData.birthday,
            gradientIndex: Int.random(in: 0...5), // Set a default gradient
            isSocialProfileActive: false,
            socialAuthProvider: Auth.auth().currentUser?.providerData.first?.providerID,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        logger.debug("📝 DEBUG: Created UserModel:")
        logger.debug("📝 DEBUG: - ID: \(newUser.id)")
        logger.debug("📝 DEBUG: - Name: \(newUser.name ?? "nil")")
        logger.debug("📝 DEBUG: - Email: \(newUser.email ?? "nil")")
        logger.debug("📝 DEBUG: - Phone: \(newUser.phoneNumber ?? "nil")")
        logger.debug("📝 DEBUG: - Bio: \(newUser.bio ?? "nil")")
        logger.debug("📝 DEBUG: - Birthday: \(newUser.birthday?.description ?? "nil")")
        
        // Upload profile image if needed
        if self.profileData.useImageAvatar, let image = self.profileData.avatarImage {
            logger.debug("🖼️ DEBUG: Starting profile image upload")
            
            // Compress image
            guard let compressedImage = image.jpegData(compressionQuality: 0.7) else {
                logger.error("❌ ERROR: Failed to compress image")
                throw NSError(domain: "com.ketchupsoon", code: 4, 
                             userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
            }
            
            logger.debug("🖼️ DEBUG: Image compressed, size: \(compressedImage.count) bytes")
            
            // Upload to Firebase Storage
            let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
            logger.debug("🖼️ DEBUG: Uploading to Firebase Storage: profile_images/\(userId).jpg")
            
            _ = try await storageRef.putDataAsync(compressedImage)
            logger.debug("🖼️ DEBUG: Image upload to Firebase Storage complete!")
            
            // Get download URL
            let downloadURL = try await storageRef.downloadURL()
            logger.debug("🖼️ DEBUG: Got download URL: \(downloadURL.absoluteString)")
            
            // Update model with image URL
            newUser.profileImageURL = downloadURL.absoluteString
            logger.debug("🖼️ DEBUG: Updated UserModel with profileImageURL")
        } else {
            logger.debug("🖼️ DEBUG: No profile image to upload (useImageAvatar=\(self.profileData.useImageAvatar))")
        }
        
        logger.info("Creating user with name: \(newUser.name ?? "unnamed"), email: \(newUser.email ?? "no email"), bio: \(newUser.bio ?? "no bio")")
        
        // Use UserRepository to create the user in Firebase and SwiftData
        logger.debug("💾 DEBUG: Saving user to repository (Firebase and SwiftData)")
        try await userRepository.createUser(user: newUser)
        logger.debug("💾 DEBUG: User successfully saved to repository!")
        
        // Update UserSettings with additional user info
        if !self.profileData.name.isEmpty {
            logger.debug("⚙️ DEBUG: Updating UserSettings with name: \(self.profileData.name)")
            UserSettings.shared.updateName(self.profileData.name)
        }
        
        if !self.profileData.email.isEmpty {
            logger.debug("⚙️ DEBUG: Updating UserSettings with email: \(self.profileData.email)")
            UserSettings.shared.updateEmail(self.profileData.email)
        }
        // Phone number already saved in savePhoneNumber()
        
        logger.debug("✅ DEBUG: Profile creation completed successfully!")
    }
    
    /// UI-facing function to start the profile creation process
    func finishOnboarding() {
        // Set processing state
        isProcessingProfile = true
        
        Task {
            do {
                logger.debug("🚀 DEBUG: Starting profile creation process")
                try await completeOnboarding()
                
                // Update UI on success
                await MainActor.run {
                    isProcessingProfile = false
                    logger.debug("✅ DEBUG: Profile creation completed, updating UI")
                    // Here you could navigate to main app or show success message
                    // For example: appState.onboardingComplete = true
                }
            } catch {
                // Handle errors
                await MainActor.run {
                    isProcessingProfile = false
                    self.authError = error
                    self.showingError = true
                    logger.error("❌ DEBUG: Profile creation failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
