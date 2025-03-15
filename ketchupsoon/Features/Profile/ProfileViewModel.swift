import SwiftUI
import FirebaseAuth
import OSLog
import SwiftData
import Combine
import PhotosUI
import FirebaseStorage

// Define FirebaseStorageManager as a utility class
class FirebaseStorageManager {
    static func downloadImage(from urlString: String) async throws -> UIImage {
        // Create a storage reference from the URL
        let storageRef = Storage.storage().reference(forURL: urlString)
        
        // Download the data
        let maxSize: Int64 = 5 * 1024 * 1024 // 5MB max size
        let data = try await storageRef.data(maxSize: maxSize)
        
        // Convert to UIImage
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "com.ketchupsoon", code: 1, 
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create image from data"])
        }
        
        return image
    }
}

// The profile view model protocol defines the shared interface for all profile view models

/// Protocol defining the shared interface for all profile view models
@MainActor
protocol ProfileViewModel: ObservableObject {
    // MARK: - Profile Data
    var id: String { get }
    var userName: String { get }
    var userBio: String { get }
    var profileImageURL: String? { get }
    var profileImage: UIImage? { get }
    var cachedProfileImage: UIImage? { get }
    var isLoadingImage: Bool { get }
    var phoneNumber: String { get }
    var birthday: Date? { get }
    
    // MARK: - Profile Appearance
    var profileRingGradient: LinearGradient { get }
    var profileEmoji: String { get }
    
    // MARK: - UI State
    var isEditMode: Bool { get set }
    var isRefreshing: Bool { get set }
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    var isInitialDataLoad: Bool { get }
    
    // MARK: - Methods
    func loadProfile() async
    func refreshProfile() async
    
    // Optional - implemented differently for user vs friend
    var canEdit: Bool { get }
    var showActions: Bool { get }
}

/// Default implementations of the ProfileViewModel protocol
extension ProfileViewModel {
    var profileEmoji: String { "😎" }
    var canEdit: Bool { false }
    var showActions: Bool { false }
    
    // Other default implementations as needed
}

/// Concrete implementation of ProfileViewModel that can handle both user and friend profiles
@MainActor
class CombinedProfileViewModel: ObservableObject, ProfileViewModel {
    // MARK: - Profile Type
    private let profileType: ProfileType
    
    // MARK: - Debug Properties
    // This is added for debugging purposes
    var profileTypeDescription: String {
        switch profileType {
        case .currentUser:
            return "currentUser"
        case .friend(let model):
            return "friend(\(model.id))"
        }
    }
    
    // MARK: - ProfileViewModel Protocol Properties
    var id: String {
        switch profileType {
        case .currentUser:
            return Auth.auth().currentUser?.uid ?? ""
        case .friend(let model):
            return model.id
        }
    }
    
    @Published var userName: String = ""
    @Published var userBio: String = ""
    @Published var profileImageURL: String?
    
    var isLoadingImage: Bool { isUploadingImage }
    
    // MARK: - Published Properties
    @Published var name = ""
    @Published var bio = ""
    @Published var phoneNumber: String = ""
    @Published var email: String = ""
    @Published var birthday: Date? = nil
    @Published var isRefreshing = false
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Profile appearance
    @Published var profileRingGradient: LinearGradient = AppColors.accentGradient2
    @Published var profileEmoji = "😎"
    
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
    
    // Conditional properties for user profile
    @Published var userInfo = ""  // Only relevant for user profile
    @Published var cameraEmoji = "📸" // Only for user profile
    
    // Alert state
    @Published var showAlert = false
    @Published var alertTitle = "Profile Photo"
    @Published var alertMessage = ""
    
    // Friend-specific properties
    @Published var isFavorite: Bool = false  // Only for friend profiles
    private var friendshipData: FriendshipModel?
    
    // Internal loading state tracking to prevent duplicate loads
    private var isCurrentlyLoading = false
    
    // Refresh control properties
    private let refreshDebounceInterval: TimeInterval = 5.0 // Minimum seconds between refreshes
    private var lastRefreshTime: Date? // Last time a refresh was performed
    private var pendingRefreshTask: Task<Void, Error>? // Track current refresh operation
    
    // MARK: - Dependencies
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "ProfileViewModel")
    var userRepository: UserRepository!
    var friendshipRepository: FriendshipRepository?
    var firebaseSyncService: FirebaseSyncService!
    private var autoSaveTimer: AnyCancellable?
    
    // MARK: - ProfileViewModel Protocol Computed Properties
    var canEdit: Bool {
        switch profileType {
        case .currentUser:
            return true // User can edit their own profile
        case .friend:
            return false // Cannot edit friend profiles
        }
    }
    
    var showActions: Bool {
        switch profileType {
        case .currentUser:
            return false // No actions for own profile
        case .friend:
            return true // Show actions for friend profiles
        }
    }
    
    // MARK: - Initialization
    
    // Initializer for user profile mode
    convenience init(modelContext: ModelContext, firebaseSyncService: FirebaseSyncService) {
        self.init(
            profileType: .currentUser,
            modelContext: modelContext,
            firebaseSyncService: firebaseSyncService,
            friendshipRepository: nil
        )
    }
    
    // Initializer for friend profile mode
    convenience init(
        friend: UserModel,
        modelContext: ModelContext,
        firebaseSyncService: FirebaseSyncService,
        friendshipRepository: FriendshipRepository
    ) {
        self.init(
            profileType: .friend(friend),
            modelContext: modelContext,
            firebaseSyncService: firebaseSyncService,
            friendshipRepository: friendshipRepository
        )
    }
    
    // Private shared initializer
    private init(
        profileType: ProfileType,
        modelContext: ModelContext,
        firebaseSyncService: FirebaseSyncService,
        friendshipRepository: FriendshipRepository?
    ) {
        self.profileType = profileType
        self.firebaseSyncService = firebaseSyncService
        self.userRepository = UserRepositoryFactory.createRepository(modelContext: modelContext)
        self.friendshipRepository = friendshipRepository
        
        // If this is a friend profile, initialize with friend data
        if case .friend(let friendModel) = profileType {
            self.name = friendModel.name ?? ""
            self.userName = friendModel.name ?? ""
            self.bio = friendModel.bio ?? ""
            self.userBio = friendModel.bio ?? ""
            self.email = "\(friendModel.email ?? "")"
            self.phoneNumber = "\(friendModel.phoneNumber ?? "")"
            self.birthday = friendModel.birthday
            self.profileImageURL = friendModel.profileImageURL
            
            // Set gradient based on friend's gradient index
            let gradientIndex = min(max(friendModel.gradientIndex, 0), AppColors.avatarGradients.count - 1)
            self.profileRingGradient = AppColors.avatarGradients[gradientIndex]
        }
        
        let profileTypeString: String
        switch profileType {
        case .currentUser:
            profileTypeString = "current user"
        case .friend:
            profileTypeString = "friend"
        }
        self.logger.info("Created ProfileViewModel in \(profileTypeString) mode")
    }
    
    // MARK: - Profile Loading
    
    func loadProfile() async {
        // First check for cancellation to allow early exit
        if Task.isCancelled {
            logger.debug("🛑 Profile load cancelled before starting")
            return
        }
        
        // Prevent concurrent loading
        guard !isCurrentlyLoading else {
            logger.warning("⏩ Skipping profile load - already in progress")
            return
        }
        
        logger.debug("🔄 DEBUG: Starting loadProfile task for \(self.profileTypeDescription), user ID: \(self.id)")
        
        // Track loading without immediately showing UI indicator
        isCurrentlyLoading = true
        
        // Use a delayed loading indicator to prevent flashing for quick operations
        var shouldShowLoading = true
        
        // Start a delayed task to show loading only if operation takes longer than 300ms
        let loadingTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
            if shouldShowLoading && !Task.isCancelled {
                isLoading = true
            }
        }
        
        // Ensure loading state is reset when we exit
        defer {
            Task { @MainActor [weak self] in
                // Cancel the delayed loading task
                loadingTask.cancel()
                // Mark that we shouldn't show loading anymore
                shouldShowLoading = false
                // Reset states
                self?.isLoading = false
                self?.isCurrentlyLoading = false
                self?.logger.debug("📋 Profile loading completed")
            }
        }
        
        switch profileType {
        case .currentUser:
            await loadUserProfile()
        case .friend(let friendModel):
            await loadFriendProfile(friend: friendModel)
        }
    }
    
    private func loadUserProfile() async {
        // Check for authentication
        guard let currentUser = Auth.auth().currentUser else {
            await MainActor.run {
                self.errorMessage = "No authenticated user found"
                self.logger.error("❌ No authenticated user found")
            }
            return
        }
        
        self.logger.info("🔄 Loading profile for user ID: \(currentUser.uid)")
        
        // Try loading from local repository first
        let userModel: UserModel?
        do {
            logger.debug("🔍 DEBUG: Attempting to load user data from local repository")
            userModel = try await userRepository.getCurrentUser()
            
            if let userModel = userModel {
                logger.debug("✅ DEBUG: Found user in local database: \(userModel.id)")
                logger.debug("📄 DEBUG: Local user data - Name: '\(userModel.name ?? "nil")', Email: '\(userModel.email ?? "nil")', Bio: '\(userModel.bio ?? "nil")'")
                logger.debug("📄 DEBUG: Local user profileImageURL: \(userModel.profileImageURL ?? "nil")")
            } else {
                logger.debug("⚠️ DEBUG: User not found in local database")
            }
        } catch {
            self.logger.warning("⚠️ Failed to load user from repository: \(error.localizedDescription)")
            userModel = nil
        }
        
        // If found locally, update the UI
        if let userModel = userModel {
            logger.debug("🔄 DEBUG: Updating UI from local user model")
            await updateUIFromUserModel(userModel)
            logger.debug("✅ DEBUG: UI updated from local data - userName: '\(self.userName)', userBio: '\(self.userBio)'")
        }
        
        // Also try to refresh from Firebase for the latest data
        do {
            logger.debug("🔄 DEBUG: Refreshing user data from Firebase: \(currentUser.uid)")
            let userModel = try await userRepository.getUser(id: currentUser.uid)
            logger.debug("✅ DEBUG: Successfully got user from Firebase")
            logger.debug("📄 DEBUG: Firebase user data - Name: '\(userModel.name ?? "nil")', Email: '\(userModel.email ?? "nil")', Bio: '\(userModel.bio ?? "nil")'")
            logger.debug("📄 DEBUG: Firebase profileImageURL: \(userModel.profileImageURL ?? "nil")")
            
            logger.debug("🔄 DEBUG: Updating UI with data from Firebase")
            await updateUIFromUserModel(userModel)
            logger.debug("✅ DEBUG: UI updated from Firebase - userName: '\(self.userName)', userBio: '\(self.userBio)'")
            
            self.logger.info("✅ Successfully refreshed user data from Firebase")
        } catch {
            self.logger.warning("⚠️ Failed to refresh from Firebase: \(error.localizedDescription)")
            // If we have no data at all, show an error
            if userModel == nil {
                await MainActor.run {
                    self.errorMessage = "Could not load profile: \(error.localizedDescription)"
                }
            }
        }
        
        // Load profile image if we have a URL
        logger.debug("🖼️ DEBUG: Checking for profile image to load")
        if let imageURL = profileImageURL, !imageURL.isEmpty {
            logger.debug("🖼️ DEBUG: Found profileImageURL: \(imageURL)")
        } else {
            logger.debug("🖼️ DEBUG: No profileImageURL found")
        }
        await loadProfileImage()
        
        await MainActor.run {
            self.isInitialDataLoad = false
            logger.debug("🏁 DEBUG: Profile load complete, final UI state - userName: '\(self.userName)', userBio: '\(self.userBio)'")
            logger.debug("🏁 DEBUG: Profile image state - cached: \(self.cachedProfileImage != nil), loaded: \(self.profileImage != nil)")
        }
    }
    
    private func loadFriendProfile(friend: UserModel) async {
        // Update UI with the friend data we already have
        await updateUIFromUserModel(friend)
        
        // Try to get the latest data from Firebase
        do {
            let refreshedFriend = try await userRepository.getUser(id: friend.id)
            await updateUIFromUserModel(refreshedFriend)
            self.logger.info("✅ Successfully refreshed friend data from Firebase")
        } catch {
            self.logger.warning("⚠️ Failed to refresh friend from Firebase: \(error.localizedDescription)")
        }
        
        // Load friendship data if available
        if let friendshipRepository = friendshipRepository {
            // Check if we can convert the ID to UUID first
            guard let friendshipID = UUID(uuidString: friend.id) else {
                self.logger.warning("⚠️ Invalid friendship ID format: \(friend.id)")
                return
            }
            
            // Now proceed with the do-catch around the throwing operation
            do {
                friendshipData = try await friendshipRepository.getFriendship(id: friendshipID)
                await MainActor.run {
                    self.isFavorite = friendshipData?.isFavorite ?? false
                }
            } catch {
                self.logger.warning("⚠️ Failed to load friendship data: \(error.localizedDescription)")
            }
        }
        
        // Load profile image if we have a URL
        await loadProfileImage()
        
        await MainActor.run {
            self.isInitialDataLoad = false
        }
    }
    
    // MARK: - UI Update Helpers
    
    private func updateUIFromUserModel(_ userModel: UserModel) async {
        logger.debug("🔄 DEBUG: Updating UI from UserModel - ID: \(userModel.id)")
        logger.debug("📄 DEBUG: Source data - Name: '\(userModel.name ?? "nil")', Bio: '\(userModel.bio ?? "nil")'")
        logger.debug("📄 DEBUG: Source data - ProfileImageURL: \(userModel.profileImageURL ?? "nil")")
        
        await MainActor.run {
            self.name = userModel.name ?? ""
            self.userName = userModel.name ?? ""
            self.bio = userModel.bio ?? ""
            self.userBio = userModel.bio ?? ""
            self.email = userModel.email ?? ""
            self.phoneNumber = userModel.phoneNumber ?? ""
            self.birthday = userModel.birthday
            self.profileImageURL = userModel.profileImageURL
            
            logger.debug("📄 DEBUG: UI updated - userName: '\(self.userName)', userBio: '\(self.userBio)'")
            logger.debug("📄 DEBUG: UI updated - profileImageURL: \(self.profileImageURL ?? "nil")")
            
            // Set gradient based on user's gradient index
            let gradientIndex = min(max(userModel.gradientIndex, 0), AppColors.avatarGradients.count - 1)
            self.profileRingGradient = AppColors.avatarGradients[gradientIndex]
        }
    }
    
    // MARK: - Image Loading
    
    private func loadProfileImage() async {
        guard let imageURL = profileImageURL, !imageURL.isEmpty else {
            logger.debug("🖼️ DEBUG: No profile image URL to load")
            return
        }
        
        logger.debug("🖼️ DEBUG: Attempting to load profile image from URL: \(imageURL)")
        
        do {
            // Load cached image first if available
            if let cachedImage = ImageCacheManager.shared.getImage(for: imageURL) {
                logger.debug("🖼️ DEBUG: Found image in cache")
                await MainActor.run {
                    self.cachedProfileImage = cachedImage
                    self.profileImage = cachedImage
                    logger.debug("🖼️ DEBUG: Set profile image from cache")
                }
                return
            }
            
            // Otherwise download from Firebase
            logger.debug("🖼️ DEBUG: No cached image, downloading from Firebase Storage")
            let downloadedImage = try await FirebaseStorageManager.downloadImage(from: imageURL)
            logger.debug("🖼️ DEBUG: Successfully downloaded image from Firebase")
            
            // Update UI and cache the image
            await MainActor.run {
                self.profileImage = downloadedImage
                self.cachedProfileImage = downloadedImage
                ImageCacheManager.shared.storeImage(downloadedImage, for: imageURL)
                logger.debug("🖼️ DEBUG: Image set in UI and stored in cache")
            }
        } catch {
            self.logger.error("Failed to load profile image: \(error.localizedDescription)")
            logger.debug("❌ DEBUG: Image load error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Profile Refresh
    
    func refreshProfile() async {
        // Check if we've refreshed recently to implement debounce
        let now = Date()
        if let lastRefresh = lastRefreshTime, now.timeIntervalSince(lastRefresh) < refreshDebounceInterval {
            logger.debug("⏯️ Skipping refresh - too soon since last refresh")
            isRefreshing = false
            return
        }
        
        logger.debug("🔄 DEBUG: Starting profile refresh for \(self.profileTypeDescription), user ID: \(self.id)")
        
        // Cancel any existing refresh operation
        pendingRefreshTask?.cancel()
        
        // Create a new refresh task
        pendingRefreshTask = Task { [weak self] in
            guard let self = self, !Task.isCancelled else { return }
            
            isRefreshing = true
            defer { isRefreshing = false }
            
            logger.debug("🔄 DEBUG: Loading fresh profile data")
            await loadProfile()
            logger.debug("✅ DEBUG: Profile refresh completed")
            
            // Update refresh timestamp
            lastRefreshTime = Date()
        }
        
        // Wait for the task to complete
        try? await pendingRefreshTask?.value
    }
    
    // MARK: - User Profile Editing (only available in currentUser mode)
    
    func saveProfile() async {
        guard case .currentUser = profileType else {
            logger.warning("❌ Cannot save profile for friend - editing not supported")
            return
        }
        
        await MainActor.run {
            saveInProgress = true
        }
        
        defer {
            Task { @MainActor in
                self.saveInProgress = false
            }
        }
        
        do {
            // Create or update the user model
            let userModel = try await userRepository.getCurrentUser() ?? UserModel(
                id: Auth.auth().currentUser?.uid ?? "",
                name: name,
                profileImageURL: profileImageURL,
                email: email,
                phoneNumber: phoneNumber,
                bio: bio,
                birthday: birthday
            )
            
            // Update fields
            userModel.name = name
            userModel.bio = bio
            userModel.phoneNumber = phoneNumber
            userModel.birthday = birthday
            userModel.updatedAt = Date()
            
            // Save to local repository and Firebase
            try await userRepository.updateUser(user: userModel)
            
            await MainActor.run {
                self.hasChanges = false
                self.userName = name
                self.userBio = bio
            }
            
            logger.info("✅ Successfully saved user profile")
        } catch {
            logger.error("❌ Failed to save profile: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to save: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Friend-specific Actions
    
    func toggleFavorite() async {
        guard case .friend = profileType, let friendshipRepository = friendshipRepository else {
            return
        }
        
        do {
            if let friendship = friendshipData {
                // Update existing friendship
                friendship.isFavorite.toggle()
                try await friendshipRepository.updateFriendship(friendship: friendship)
            } else if case .friend(let friendModel) = profileType {
                // Create new friendship with correct parameter names
                let newFriendship = FriendshipModel(
                    id: UUID(),
                    userID: Auth.auth().currentUser?.uid ?? "",
                    friendID: friendModel.id,
                    relationshipType: "friend",
                    isFavorite: true,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                try await friendshipRepository.createFriendship(friendship: newFriendship)
                friendshipData = newFriendship
            }
            
            await MainActor.run {
                self.isFavorite.toggle()
            }
        } catch {
            logger.error("❌ Failed to toggle favorite: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to update favorite status: \(error.localizedDescription)"
            }
        }
    }
}

/// Factory for creating the appropriate profile view model
@MainActor
enum ProfileViewModelFactory {
    // Track created view models to debug multiple creation
    private static var createdViewModels: [ObjectIdentifier: String] = [:]
    
    @MainActor
    static func createViewModel(
        for profileType: ProfileType,
        modelContext: ModelContext,
        firebaseSyncService: FirebaseSyncService
    ) -> CombinedProfileViewModel {
        let factoryID = UUID().uuidString.prefix(6)
        print("🏭 DEBUG: ProfileViewModelFactory.createViewModel called [\(factoryID)]")
        
        switch profileType {
            case .currentUser:
                let viewModel = CombinedProfileViewModel(
                    modelContext: modelContext, 
                    firebaseSyncService: firebaseSyncService
                )
                
                let id = ObjectIdentifier(viewModel)
                print("🏭 DEBUG: Created ProfileViewModel (user mode) [ID: \(id)] - Total created: \(createdViewModels.count + 1)")
                createdViewModels[id] = "ProfileViewModel-User"
                return viewModel
                
            case .friend(let friendModel):
                let friendshipRepository = FriendshipRepositoryFactory.createRepository(modelContext: modelContext)
                let viewModel = CombinedProfileViewModel(
                    friend: friendModel,
                    modelContext: modelContext,
                    firebaseSyncService: firebaseSyncService,
                    friendshipRepository: friendshipRepository
                )
                
                let id = ObjectIdentifier(viewModel)
                print("🏭 DEBUG: Created ProfileViewModel (friend mode) [ID: \(id)] - Total created: \(createdViewModels.count + 1)")
                createdViewModels[id] = "ProfileViewModel-Friend"
                return viewModel
        }
    }
}

/// Enum to define the type of profile being displayed
enum ProfileType {
    case currentUser
    case friend(UserModel)
}
