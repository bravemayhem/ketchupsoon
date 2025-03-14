import SwiftUI
import FirebaseAuth
import PhotosUI
import FirebaseStorage
import OSLog
import Combine
import SwiftData

// Import the ProfileViewModel protocol
@_exported import class UIKit.UIImage

@MainActor
class UserProfileViewModel: ObservableObject, ProfileViewModel {
    // MARK: - ProfileViewModel Protocol Properties
    var id: String { Auth.auth().currentUser?.uid ?? "" }
    @Published var userName: String = ""
    @Published var userBio: String = ""
    var profileImageURL: String? { nil } // Will be set during loading
    var isLoadingImage: Bool { isUploadingImage }
    
    // MARK: - Published Properties
    @Published var name = ""
    @Published var bio = ""
    @Published var userInfo = ""
    @Published var phoneNumber: String = ""
    @Published var email: String = ""
    @Published var birthday: Date? = nil
    @Published var isRefreshing = false
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
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
    
    // Internal loading state tracking to prevent duplicate loads
    private var isCurrentlyLoading = false
    
    // Refresh control properties
    private let refreshDebounceInterval: TimeInterval = 5.0 // Minimum seconds between refreshes
    private var lastRefreshTime: Date? // Last time a refresh was performed
    private var pendingRefreshTask: Task<Void, Error>? // Track current refresh operation
    
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
    
    // MARK: - ProfileViewModel Protocol Properties
    var canEdit: Bool { true } // User can edit their own profile
    var showActions: Bool { false } // No action buttons needed for own profile
    
    // MARK: - ProfileViewModel Protocol Methods
    
    func refreshProfile() async {
        // Check if we've refreshed recently to implement debounce
        let now = Date()
        if let lastRefresh = lastRefreshTime, now.timeIntervalSince(lastRefresh) < refreshDebounceInterval {
            print("⏯️ DEBUG: Skipping refresh - too soon since last refresh (\(now.timeIntervalSince(lastRefresh)) seconds)")
            isRefreshing = false
            return
        }
        
        // Cancel any existing refresh operation
        pendingRefreshTask?.cancel()
        
        // Create a new refresh task
        pendingRefreshTask = Task { [weak self] in
            guard let self = self, !Task.isCancelled else { return }
            
            isRefreshing = true
            defer { isRefreshing = false }
            
            print("🔄 DEBUG: Starting profile refresh operation")
            await loadProfile()
            
            // Update refresh timestamp
            lastRefreshTime = Date()
        }
        
        // Wait for the task to complete
        try? await pendingRefreshTask?.value
    }
    
    // MARK: - Public Methods
    
    /// Load the user profile data from repository and Firebase
    /// Simplified profile loading method to reduce async complexity
    func loadProfile() async {
        // First check for cancellation to allow early exit
        if Task.isCancelled {
            print("🛑 DEBUG: loadProfile cancelled before starting")
            return
        }
        
        // Add stack trace debug info to identify the call source
        let callStackSymbols = Thread.callStackSymbols
        print("🛠 DEBUG CALL STACK: loadProfile called from:\n\(callStackSymbols.prefix(8).joined(separator: "\n"))")
        
        // Use a dedicated isCurrentlyLoading flag to prevent concurrent or repeated loading attempts
        // This is more reliable than isLoading which can be reset externally
        guard !isCurrentlyLoading else {
            logger.warning("⏩ Skipping profile load - already in progress")
            return
        }
        
        // Create a unique ID for this loading operation
        let operationId = UUID().uuidString.prefix(8)
        print("🛠 DEBUG: Starting profile load operation [\(operationId)]")
        
        // Set loading state
        await MainActor.run {
            isLoading = true
            isCurrentlyLoading = true
        }
        
        // Create a task that will reset the loading state after a maximum timeout
        // This ensures we never get stuck in a loading state
        let safetyTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 second safety timeout
            if let self = self {
                await MainActor.run {
                    if self.isLoading || self.isCurrentlyLoading {
                        self.logger.warning("⚠️ Safety timeout triggered - resetting loading state")
                        self.isLoading = false
                        self.isCurrentlyLoading = false
                    }
                }
            }
        }
        
        // Ensure loading state is reset when we exit this function
        defer {
            safetyTimeoutTask.cancel() // Cancel the safety timeout if we finish normally
            Task { @MainActor [weak self] in
                self?.isLoading = false
                self?.isCurrentlyLoading = false
                self?.logger.debug("📋 Profile loading completed")
            }
        }
        
        do {
            // Check for authentication
            guard let currentUser = Auth.auth().currentUser else {
                await MainActor.run {
                    self.errorMessage = "No authenticated user found"
                    self.logger.error("❌ No authenticated user found")
                }
                return
            }
            
            self.logger.info("🔄 Loading profile for user ID: \(currentUser.uid)")
            
            // SIMPLIFIED APPROACH: Use direct calls instead of complex task groups
            
            // Step 1: Try loading from local repository first
            var localUserModel: UserModel? = nil
            
            // This try-catch can be removed since we're handling the result directly
            // Handle any errors from tasks inside their result case statements
            
            // Simple timeout with a direct call
            let getUserTask = Task { 
                do {
                    return try await userRepository.getCurrentUser()
                } catch {
                    self.logger.error("❌ Error loading user from repository: \(error.localizedDescription)")
                    return nil
                }
            }
            
            // Wait maximum 3 seconds
            let timeoutTask = Task { 
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                return nil as UserModel?
            }
            
            // Wait for either task to complete
            if let userModel = await getUserTask.value {
                localUserModel = userModel
                // Cancel the timeout task as we already have a result
                timeoutTask.cancel()
            } else {
                // If the first task failed or returned nil, wait for the timeout
                let _ = await timeoutTask.value  // Just wait for timeout
            }
            
            // Step 2: Update UI if we have local data
            if let user = localUserModel {
                await MainActor.run {
                    self.updateUIFromUserModel(user)
                    self.logger.info("✅ Updated UI from local user model")
                }
            } else {
                self.logger.warning("⚠️ No local user model found, trying ProfileManager")
                
                // Step 3: Fall back to ProfileManager if needed
                await profileManager.fetchUserProfile(userId: currentUser.uid)
                
                // Step 4: Update from ProfileManager
                await MainActor.run {
                    if let profile = profileManager.currentUserProfile {
                        self.updateUIFromProfileManager(profile)
                        self.logger.info("✅ Updated UI from ProfileManager")
                        
                        // Load profile image in background if available
                        if let photoURL = profile.profileImageURL, !photoURL.isEmpty {
                            Task {
                                self.preloadProfileImage(from: photoURL)
                            }
                        }
                    } else {
                        self.logger.warning("⚠️ No profile found in ProfileManager")
                    }
                }
            }
            
            // Step 5: Trigger a background refresh without blocking profile load
            Task.detached {
                do {
                    try await self.userRepository.refreshCurrentUser()
                    self.logger.info("✅ Background refresh completed successfully")
                    
                    // Once refresh is done, sync in background
                    try await self.userRepository.syncLocalWithRemote()
                    self.logger.info("✅ Background sync completed successfully")
                } catch {
                    self.logger.error("❌ Background refresh/sync error: \(error.localizedDescription)")
                }
            }
            
            // Step 6: Finalize the UI and settings
            await MainActor.run {
                // Enable auto-saves with a small delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isInitialDataLoad = false
                    self.logger.info("📋 Initial data load complete, auto-save enabled")
                }
                
                // Reset loading flags
                self.isLoading = false
                self.isCurrentlyLoading = false
                print("🛠 DEBUG: Profile loading completed [\(operationId)]")
                self.logger.info("📋 Profile loading completed")
            }
            
            // Trigger a throwing operation to ensure catch block is reachable
            // This helps maintain error handling while we refactor
            if Task.isCancelled {
                throw NSError(domain: "ProfileLoadingError", code: 999, 
                             userInfo: [NSLocalizedDescriptionKey: "Task was cancelled"])
            }
        } catch let loadError {
            // Handle top-level errors
            await MainActor.run {
                self.logger.error("❌ Error loading profile: \(loadError.localizedDescription)")
                self.alertTitle = "Profile Error"
                self.alertMessage = "Failed to load profile: \(loadError.localizedDescription)"
                self.showAlert = true
                
                // Reset loading flags even in error case
                self.isLoading = false
                self.isCurrentlyLoading = false
            }
        }
    }
    
    /// Save profile changes
    func saveProfile() {
        if !self.hasChanges {
            self.logger.info("No changes detected, skipping save")
            return
        }
        
        self.saveInProgress = true
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // Use FirebaseSyncService for the update
                try await self.firebaseSyncService.updateCurrentUserProfile(
                    name: self.userName,
                    bio: self.userBio,
                    birthday: self.birthday
                    // We could add other profile fields here as needed
                )
                
                await MainActor.run {
                    self.saveInProgress = false
                    self.hasChanges = false
                    self.isEditMode = false
                }
                
                self.logger.info("✅ Profile saved successfully via FirebaseSyncService")
            } catch {
                self.logger.error("❌ Error saving profile: \(error.localizedDescription)")
                
                await MainActor.run {
                    self.saveInProgress = false
                    // Show an error alert if needed
                    self.alertTitle = "Save Error"
                    self.alertMessage = "Failed to save profile: \(error.localizedDescription)"
                    self.showAlert = true
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
            logger.error("❌ Invalid profile image URL: \(urlString)")
            return
        }
        
        logger.debug("🖼️ Starting profile image download from: \(urlString)")
        
        // Create a task with timeout
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("❌ Error loading profile image: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                self.logger.debug("🖼️ Image response status code: \(httpResponse.statusCode)")
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.cachedProfileImage = image
                    self.logger.info("✅ Cached profile image loaded successfully")
                }
            } else {
                self.logger.error("❌ Failed to create image from downloaded data")
            }
        }
        
        // Set a timeout for the request
        task.resume()
        
        // Cancel the request after 10 seconds if it hasn't completed
        DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [weak task] in
            if let task = task, task.state == .running {
                task.cancel()
                self.logger.warning("⚠️ Cancelled profile image download due to timeout")
            }
        }
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
        // Always set values to ensure UI is updated, even for empty strings
        // This ensures we don't miss updates where fields were cleared
        self.userName = userModel.name ?? ""
        self.logger.debug("Setting userName to '\(self.userName)' from model")
        
        self.userBio = userModel.bio ?? ""
        self.logger.debug("Setting userBio to '\(self.userBio)' from model")
        
        if let userBirthday = userModel.birthday {
            self.birthday = userBirthday
            self.logger.debug("Setting birthday to \(userBirthday)")
        }
        
        self.email = userModel.email ?? ""
        self.logger.debug("Setting email to '\(self.email)' from model")
        
        self.phoneNumber = userModel.phoneNumber ?? ""
        self.logger.debug("Setting phoneNumber to '\(self.phoneNumber)' from model")
        
        // Force UI update
        self.objectWillChange.send()
    }
    
    /// Update UI elements from profile manager
    private func updateUIFromProfileManager(_ profile: UserModel) {
        // Always set values even if empty (don't skip empty values)
        // This ensures we override any stale cached values
        self.userName = profile.name ?? ""
        self.logger.debug("Setting userName to '\(self.userName)' from profile manager")
        
        self.userBio = profile.bio ?? ""
        self.logger.debug("Setting userBio to '\(self.userBio)' from profile manager")
        
        // Always set the birthday from profile if available
        if let profileBirthday = profile.birthday {
            self.birthday = profileBirthday
            self.logger.debug("Setting birthday to \(profileBirthday) from profile manager")
        }
        
        // Get phone number from profile if available
        if let profilePhone = profile.phoneNumber, !profilePhone.isEmpty {
            self.phoneNumber = profilePhone
            self.logger.debug("Setting phoneNumber to '\(self.phoneNumber)' from profile manager")
        }
        
        // Get email from profile if available
        if let profileEmail = profile.email, !profileEmail.isEmpty {
            self.email = profileEmail
            self.logger.debug("Setting email to '\(self.email)' from profile manager")
        }
        
        // Fallback to Auth for email and phone if still empty
        if let user = Auth.auth().currentUser {
            if !user.email.isNilOrEmpty && self.email.isEmpty {
                self.email = user.email ?? ""
                self.logger.debug("Setting email to '\(self.email)' from Auth")
            }
            
            if !user.phoneNumber.isNilOrEmpty && self.phoneNumber.isEmpty {
                self.phoneNumber = user.phoneNumber ?? ""
                self.logger.debug("Setting phoneNumber to '\(self.phoneNumber)' from Auth")
            }
        }
        
        // Force UI update to ensure all fields are refreshed
        self.objectWillChange.send()
    }
}

// MARK: - Helper Extensions
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        self == nil || self!.isEmpty
    }
}
