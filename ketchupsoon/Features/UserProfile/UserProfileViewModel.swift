import SwiftUI
import FirebaseAuth
import PhotosUI
import FirebaseStorage
import OSLog
import Combine
import SwiftData

@MainActor
class UserProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userName = ""
    @Published var userBio = ""
    @Published var userInfo = ""
    @Published var phoneNumber: String = ""
    @Published var email: String = ""
    @Published var birthday: Date? = nil
    
    // Profile appearance
    @Published var profileRingGradient: LinearGradient = AppColors.accentGradient2
    @Published var profileEmoji = "😎"
    @Published var cameraEmoji = "📸"
    
    // Image related properties
    @Published var selectedPhoto: PhotosPickerItem? = nil
    @Published var profileImage: UIImage? = nil
    @Published var cachedProfileImage: UIImage? = nil
    @Published var isUploadingImage = false
    @Published var croppingImage: UIImage? = nil
    
    // UI state
    @Published var isEditMode = false
    @Published var saveInProgress = false
    @Published var hasChanges = false
    @Published var isInitialDataLoad = true
    
    // Alert state
    @Published var showAlert = false
    @Published var alertTitle = "Profile Photo"
    @Published var alertMessage = ""
    
    // MARK: - Dependencies
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "UserProfileViewModel")
    var userRepository: UserRepository!
    var firebaseSyncService: FirebaseSyncService!
    private var profileManager = UserProfileManager.shared
    private var autoSaveTimer: AnyCancellable?
    
    // MARK: - Initialization
    
    // Default initializer for use with dependency injection
    init() {
        logger.info("Created UserProfileViewModel with default initializer")
    }
    
    // Full initializer with dependencies provided
    init(modelContext: ModelContext, firebaseSyncService: FirebaseSyncService) {
        self.userRepository = UserRepositoryFactory.createRepository(modelContext: modelContext)
        self.firebaseSyncService = firebaseSyncService
        logger.info("Created UserProfileViewModel with full dependencies")
    }
    
    // MARK: - Public Methods
    
    /// Load the user profile data from repository and Firebase
    func loadProfile() async {
        do {
            // Try to load the user profile via FirebaseSyncService first
            if let currentUser = Auth.auth().currentUser {
                // Trigger a sync to ensure we have fresh data
                try await userRepository.syncLocalWithRemote()
                
                // Attempt to load from local repository
                if let localUserModel = try await userRepository.getCurrentUser() {
                    await MainActor.run {
                        updateUIFromUserModel(localUserModel)
                        logger.info("📋 Loaded user data from local repository")
                    }
                }
                
                // Legacy approach using ProfileManager
                await profileManager.fetchUserProfile(userId: currentUser.uid)
                
                // Update from profile manager if needed
                await MainActor.run {
                    if let profile = profileManager.currentUserProfile {
                        updateUIFromProfileManager(profile)
                        logger.info("📋 Updated user data from ProfileManager")
                    }
                    
                    // Load profile image if available
                    if let photoURL = profileManager.currentUserProfile?.profileImageURL,
                       !photoURL.isEmpty {
                        preloadProfileImage(from: photoURL)
                    }
                    
                    // Set a small delay before allowing auto-saves
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.isInitialDataLoad = false
                        self.logger.info("📋 Initial data load complete, auto-save enabled")
                    }
                }
            }
        } catch {
            logger.error("❌ Error loading profile: \(error.localizedDescription)")
            alertTitle = "Profile Error"
            alertMessage = "Failed to load profile: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    /// Save profile changes
    func saveProfile() {
        if !hasChanges {
            logger.info("No changes detected, skipping save")
            return
        }
        
        saveInProgress = true
        
        Task {
            do {
                // Use FirebaseSyncService for the update
                try await firebaseSyncService.updateCurrentUserProfile(
                    name: userName,
                    bio: userBio,
                    birthday: birthday
                    // We could add other profile fields here as needed
                )
                
                await MainActor.run {
                    saveInProgress = false
                    hasChanges = false
                    isEditMode = false
                }
                
                logger.info("✅ Profile saved successfully via FirebaseSyncService")
            } catch {
                logger.error("❌ Error saving profile: \(error.localizedDescription)")
                
                await MainActor.run {
                    saveInProgress = false
                    // Show an error alert if needed
                    alertTitle = "Save Error"
                    alertMessage = "Failed to save profile: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    /// Legacy method for saving profile (fallback)
    func saveProfileLegacy() async {
        // This is the legacy method - we should prefer using FirebaseSyncService.updateCurrentUserProfile
        // but keeping this as a fallback
        
        // Check if we have a user profile or if the user is logged in
        guard let userProfile = profileManager.currentUserProfile,
              let userId = Auth.auth().currentUser?.uid else {
            logger.error("❌ No user profile or user not logged in")
            return
        }
        
        do {
            // Create an updated profile
            let updatedProfile = userProfile
            updatedProfile.name = userName
            updatedProfile.bio = userBio
            updatedProfile.birthday = birthday
            
            // Sync with FirebaseManager
            try await profileManager.updateUserProfile(updates: [
                "name": userName,
                "bio": userBio,
                "birthday": birthday ?? Date(timeIntervalSince1970: 0)  // Default to Unix epoch if nil
            ])
            
            // Also update the repository for local persistence
            let localUser = try await userRepository.getUser(id: userId)
            let updatedUser = localUser
            updatedUser.name = userName
            updatedUser.bio = userBio
            updatedUser.birthday = birthday ?? Date(timeIntervalSince1970: 0)  // Default to Unix epoch if nil
            
            try await userRepository.updateUser(user: updatedUser)
            logger.info("✅ Updated user in local repository")
            
            await MainActor.run {
                saveInProgress = false
                hasChanges = false
                logger.info("✅ Profile saved successfully via legacy method")
            }
        } catch {
            logger.error("❌ Error saving profile: \(error.localizedDescription)")
            await MainActor.run {
                saveInProgress = false
                alertTitle = "Save Error"
                alertMessage = "Failed to save profile: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    /// Process photo selection from PhotosPicker
    func loadTransferableImage(from pickerItem: PhotosPickerItem) async {
        do {
            if let data = try await pickerItem.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        croppingImage = image
                    }
                }
            }
        } catch {
            logger.error("❌ Failed to load image: \(error.localizedDescription)")
            alertTitle = "Image Error"
            alertMessage = "Failed to load image: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    /// Upload profile image to Firebase Storage
    func uploadProfileImage(_ image: UIImage) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            logger.error("❌ No user ID available")
            return
        }
        
        await MainActor.run {
            isUploadingImage = true
        }
        
        do {
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                throw NSError(domain: "com.ketchupsoon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
            }
            
            // Create a storage reference
            let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
            
            // Upload the data
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            
            // Get the download URL
            let downloadURL = try await storageRef.downloadURL()
            
            // Update profile in Firestore
            await updateProfileWithImageURL(downloadURL.absoluteString)
            
            await MainActor.run {
                profileImage = image
                cachedProfileImage = image
                isUploadingImage = false
                logger.info("✅ Profile image uploaded successfully")
            }
        } catch {
            logger.error("❌ Error uploading profile image: \(error.localizedDescription)")
            
            await MainActor.run {
                isUploadingImage = false
                alertTitle = "Upload Error"
                alertMessage = "Failed to upload profile image: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    /// Mark that changes have been made and trigger auto-save
    func triggerAutoSave() {
        // Don't auto-save during initial data loading
        if isInitialDataLoad {
            return
        }
        
        hasChanges = true
        
        // Cancel any existing timer
        autoSaveTimer?.cancel()
        
        // Set up a new timer for auto-save
        autoSaveTimer = Just(())
            .delay(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.hasChanges && !self.saveInProgress {
                    self.saveProfile()
                }
            }
    }
    
    // MARK: - Helper Methods
    
    /// Load profile image from URL
    func preloadProfileImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("❌ Error loading profile image: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.cachedProfileImage = image
                    self.logger.info("✅ Cached profile image loaded")
                }
            }
        }.resume()
    }
    
    /// Format phone number for display
    func formatPhoneForDisplay(_ phone: String) -> String {
        // Simple formatting for display - could be made more sophisticated
        if phone.count == 10 {
            let area = phone.prefix(3)
            let middle = phone.dropFirst(3).prefix(3)
            let last = phone.dropFirst(6).prefix(4)
            return "(\(area)) \(middle)-\(last)"
        }
        return phone
    }
    
    /// Format birthday for display
    func formatBirthdayForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Private Methods
    
    /// Update the Firebase profile with new image URL
    private func updateProfileWithImageURL(_ url: String) async {
        do {
            try await firebaseSyncService.updateCurrentUserProfileImage(url: url)
            
            // Also update the legacy profile manager
            if let userProfile = profileManager.currentUserProfile,
               let _ = Auth.auth().currentUser?.uid {
                userProfile.profileImageURL = url
                try await profileManager.updateUserProfile(updates: ["profileImageURL": url])
            }
            
            logger.info("✅ Profile image URL updated in Firestore")
        } catch {
            logger.error("❌ Error updating profile with image URL: \(error.localizedDescription)")
        }
    }
    
    /// Update UI elements from user model
    private func updateUIFromUserModel(_ userModel: UserModel) {
        if !(userModel.name?.isEmpty ?? true) {
            userName = userModel.name ?? ""
        }
        
        if !(userModel.bio?.isEmpty ?? true) {
            userBio = userModel.bio ?? ""
        }
        
        if let userBirthday = userModel.birthday {
            birthday = userBirthday
        }
        
        if !(userModel.email?.isEmpty ?? true) {
            email = userModel.email ?? ""
        }
        
        if !(userModel.phoneNumber?.isEmpty ?? true) {
            phoneNumber = userModel.phoneNumber ?? ""
        }
    }
    
    /// Update UI elements from profile manager
    private func updateUIFromProfileManager(_ profile: UserModel) {
        if !(profile.name?.isEmpty ?? true) {
            userName = profile.name ?? ""
        }
        
        if !(profile.bio?.isEmpty ?? true) {
            userBio = profile.bio ?? ""
        }
        
        if let profileBirthday = profile.birthday {
            birthday = profileBirthday
        }
        
        // Email and phone from Auth if available
        if let user = Auth.auth().currentUser {
            if !user.email.isNilOrEmpty && email.isEmpty {
                email = user.email ?? ""
            }
            
            if !user.phoneNumber.isNilOrEmpty && phoneNumber.isEmpty {
                phoneNumber = user.phoneNumber ?? ""
            }
        }
    }
}

// MARK: - Helper Extensions
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        self == nil || self!.isEmpty
    }
}
