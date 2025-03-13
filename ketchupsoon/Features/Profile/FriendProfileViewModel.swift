import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseFirestore
import OSLog
import Combine

@MainActor
class FriendProfileViewModel: ObservableObject, ProfileViewModel {
    // MARK: - ProfileViewModel Protocol Properties
    var id: String { friend.id }
    var userName: String { friend.name ?? "Friend" }
    var userBio: String { friend.bio ?? "" }
    var profileImageURL: String? { friend.profileImageURL }
    var profileImage: UIImage? { nil } // Friends don't have locally stored images
    var cachedProfileImage: UIImage? { nil }
    var isLoadingImage: Bool { false }
    var profileRingGradient: LinearGradient {
        // Safely access the avatar gradients array
        let gradients = AppColors.avatarGradients
        let safeIndex = min(max(friend.gradientIndex, 0), gradients.count - 1)
        return gradients[safeIndex]
    }
    var profileEmoji: String { "😎" }
    var canEdit: Bool { false } // Users cannot edit friend profiles
    var showActions: Bool { true } // Show friend action buttons
    var isInitialDataLoad: Bool { true } // Always load friend data initially
    
    // MARK: - Published Properties
    @Published var friend: UserModel
    @Published var refreshedFriend: UserModel?
    @Published var isEditMode: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isFavorite: Bool = false
    
    // MARK: - Dependencies
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "FriendProfileViewModel")
    private var userRepository: UserRepository
    private var firebaseSyncService: FirebaseSyncService
    private var modelContext: ModelContext
    private var userDocumentListener: ListenerRegistration?
    private var friendshipRepository: FriendshipRepository
    
    // MARK: - Initialization
    init(friend: UserModel, modelContext: ModelContext, firebaseSyncService: FirebaseSyncService, friendshipRepository: FriendshipRepository) {
        self.friend = friend
        self.modelContext = modelContext
        self.firebaseSyncService = firebaseSyncService
        self.friendshipRepository = friendshipRepository
        self.userRepository = UserRepositoryFactory.createRepository(modelContext: modelContext)
        
        logger.info("Created FriendProfileViewModel for friend \(friend.id)")
    }
    
    deinit {
        // Clean up any resources - use a weak reference to avoid the Swift 6 error
        // Store a local reference to the listener and then remove it
        if let listener = userDocumentListener {
            listener.remove()
        }
        userDocumentListener = nil
    }
    
    // MARK: - ProfileViewModel Protocol Methods
    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        
        logger.info("Loading profile for friend: \(self.friend.id)")
        
        // Set up listener for real-time updates
        setupFirestoreListener()
        
        // Load any additional data needed
        // We'll need to check for favorite status in a different way since UserModel doesn't have isFavorite
        // This might need to come from a separate FriendshipModel or similar
        Task {
            // Set a default value
            isFavorite = false
            
            // Check favorite status based on your app's data structure
            // e.g., checking a friendships collection or similar
            do {
                try await self.userRepository.updateUser(user: self.friend)
            } catch {
                logger.error("Error updating friend: \(error.localizedDescription)")
            }
        }
    }
    
    func refreshProfile() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        logger.info("Refreshing profile for friend: \(self.friend.id)")
        
        // Fetch latest data from Firestore
        await refreshFriendData()
    }
    
    // MARK: - Firestore Listener
    private func setupFirestoreListener() {
        // Remove any existing listener
        removeFirestoreListener()
        
        // Set up a new listener to the user document
        let db = Firestore.firestore()
        userDocumentListener = db.collection("users").document(self.friend.id).addSnapshotListener { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Error listening to user document: \(error.localizedDescription)")
                return
            }
            
            // If the document exists and has data, update our friend model
            if let document = document, document.exists, let userData = document.data() {
                // Create a UserModel from firestore data
                // Get existing user to update
                let friendID = document.documentID
                let descriptor = FetchDescriptor<UserModel>(predicate: #Predicate { user in 
                    user.id == friendID
                })
                do {
                    let existingUser = try self.modelContext.fetch(descriptor).first
                    
                    if let existingUser = existingUser {
                        // Update existing user on the main thread
                        DispatchQueue.main.async {
                            // Update properties from firestore data
                            existingUser.name = userData["name"] as? String ?? existingUser.name
                            existingUser.profileImageURL = userData["profileImageURL"] as? String ?? existingUser.profileImageURL
                            existingUser.bio = userData["bio"] as? String ?? existingUser.bio
                            
                            // Update our local state
                            self.refreshedFriend = existingUser
                            self.logger.info("Real-time update received for friend \(existingUser.id)")
                        }
                    }
                } catch {
                    self.logger.error("Error updating friend from Firestore: \(error)")
                }
            }
        }
        
        logger.info("Set up Firestore listener for friend \(self.friend.id)")
    }
    
    private func removeFirestoreListener() {
        userDocumentListener?.remove()
        userDocumentListener = nil
    }
    
    // MARK: - Friend Data Actions
    func refreshFriendData() async {
        do {
            // Fetch the latest data from Firebase
            isLoading = true
            defer { isLoading = false }
            
            // Using the UserRepository to fetch updated friend data
            let updatedFriend = try await userRepository.getUser(id: self.friend.id)
            DispatchQueue.main.async {
                self.refreshedFriend = updatedFriend
                self.logger.info("Successfully refreshed friend data for \(updatedFriend.id)")
            }
        } catch {
            self.logger.error("Error refreshing friend data: \(error.localizedDescription)")
            self.errorMessage = "Failed to refresh profile: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Friend Actions
    func toggleFavorite() {
        isFavorite.toggle()
        
        // Update in the database
        Task { [self] in
            do {
                try await userRepository.updateUser(user: self.friend)
                self.logger.info("Updated favorite status for friend: \(self.friend.id)")
            } catch {
                self.logger.error("Error updating favorite status: \(error.localizedDescription)")
            }
        }
    }
    
    func removeFriend() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            self.logger.error("No current user ID available")
            self.errorMessage = "Not logged in"
            return
        }
        
        do {
            // Remove the friendship using the FriendshipRepository
            try await self.friendshipRepository.removeFriendship(currentUserID: currentUserID, friendID: self.friend.id)
            self.logger.info("Successfully removed friend: \(self.friend.id)")
        } catch {
            self.logger.error("Error removing friend: \(error.localizedDescription)")
            self.errorMessage = "Failed to remove friend: \(error.localizedDescription)"
        }
    }
}
