import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseFirestore
import OSLog
import Combine

/// Service that manages real-time Firestore listeners for both users and friendships
/// Provides automatic synchronization between Firebase and SwiftData
@MainActor
class FirestoreListenerService: ObservableObject {
    // MARK: - Properties
    
    private let db = Firestore.firestore()
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "FirestoreListenerService")
    private let modelContext: ModelContext
    
    // Store active listeners to allow cancellation
    private var userListeners: [ListenerRegistration] = []
    private var friendshipListeners: [ListenerRegistration] = []
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // Nonisolated copies for access from nonisolated contexts
    private nonisolated var _userListeners: [ListenerRegistration] {
        get async {
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    continuation.resume(returning: userListeners)
                }
            }
        }
    }
    
    private nonisolated var _friendshipListeners: [ListenerRegistration] {
        get async {
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    continuation.resume(returning: friendshipListeners)
                }
            }
        }
    }
    
    private nonisolated var _authStateListener: AuthStateDidChangeListenerHandle? {
        get async {
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    continuation.resume(returning: authStateListener)
                }
            }
        }
    }
    
    // Published properties for UI reactivity
    @Published var isListening: Bool = false
    @Published var lastUpdateTimestamp: Date?
    
    // Dependencies
    private lazy var userRepository: UserRepository = {
        return UserRepositoryFactory.createRepository(modelContext: modelContext)
    }()
    
    private lazy var friendshipRepository: FriendshipRepository = {
        return FriendshipRepositoryFactory.createRepository(modelContext: modelContext)
    }()
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    deinit {
        stopAllListeners()
    }
    
    // MARK: - Public Methods
    
    /// Start listening for real-time updates for the current user
    func startListeningForCurrentUser() {
        guard let currentUser = Auth.auth().currentUser else {
            logger.warning("Cannot start listening - no current user")
            return
        }
        
        // Set up Auth state listener first
        setupAuthStateListener()
        
        // Start listening for user profile updates
        startUserListener(for: currentUser.uid)
        
        // Start listening for friendship updates
        startFriendshipsListener(for: currentUser.uid)
        
        isListening = true
        logger.info("Started listening for real-time updates for user \(currentUser.uid)")
    }
    
    /// Stop all active listeners
    /// This method is marked as nonisolated so it can be called from deinit
    nonisolated func stopAllListeners() {
        Task {
            // Remove Auth state listener
            if let authListener = await _authStateListener {
                Auth.auth().removeStateDidChangeListener(authListener)
                
                // Update on main actor
                Task { @MainActor in
                    self.authStateListener = nil
                }
            }
            
            // Remove all user listeners
            let userListenersSnapshot = await _userListeners
            for listener in userListenersSnapshot {
                listener.remove()
            }
            
            // Update on main actor
            Task { @MainActor in
                self.userListeners.removeAll()
            }
            
            // Remove all friendship listeners
            let friendshipListenersSnapshot = await _friendshipListeners
            for listener in friendshipListenersSnapshot {
                listener.remove()
            }
            
            // Update on main actor
            Task { @MainActor in
                self.friendshipListeners.removeAll()
                self.isListening = false
                self.logger.info("Stopped all Firestore listeners")
            }
        }
    }
    
    /// Stop listening for a specific user
    func stopUserListener(for userID: String) {
        // Since we can't directly identify which listener corresponds to which user,
        // we need to stop all user listeners and restart them for other users
        for listener in userListeners {
            listener.remove()
        }
        userListeners.removeAll()
        
        logger.debug("Stopped listening for user \(userID)")
    }
    
    // MARK: - Private Helper Methods
    
    private func setupAuthStateListener() {
        // Remove existing listener if any
        if let authStateListener = authStateListener {
            Auth.auth().removeStateDidChangeListener(authStateListener)
        }
        
        // Set up new listener
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            if let user = user {
                // User signed in or changed
                logger.debug("Auth state changed, user: \(user.uid)")
                
                // Restart listeners for the current user
                Task {
                    await self.restartListenersForCurrentUser()
                }
            } else {
                // User signed out
                logger.debug("Auth state changed, user signed out")
                self.stopAllListeners()
            }
        }
    }
    
    private func restartListenersForCurrentUser() async {
        stopAllListeners()
        startListeningForCurrentUser()
        
        // Force sync to ensure we have the latest data
        if let currentUser = Auth.auth().currentUser {
            do {
                try await userRepository.refreshCurrentUser()
                try await friendshipRepository.syncLocalWithRemote(for: currentUser.uid)
            } catch {
                logger.error("Error syncing data after auth state change: \(error.localizedDescription)")
            }
        }
    }
    
    private func startUserListener(for userID: String) {
        // Listen for changes to the user document
        let listener = db.collection("users").document(userID)
            .addSnapshotListener { [weak self] (documentSnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    self.logger.error("Error listening for user updates: \(error.localizedDescription)")
                    return
                }
                
                guard let document = documentSnapshot, document.exists, let data = document.data() else {
                    self.logger.warning("User document doesn't exist or is empty")
                    return
                }
                
                Task {
                    await self.handleUserUpdate(userID: userID, data: data)
                }
            }
        
        userListeners.append(listener)
    }
    
    private func startFriendshipsListener(for userID: String) {
        // Listen for friendships where the user is the owner
        let listener1 = db.collection("friendships")
            .whereField("userID", isEqualTo: userID)
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    self.logger.error("Error listening for friendship updates: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.logger.warning("No friendship documents found")
                    return
                }
                
                Task {
                    await self.handleFriendshipsUpdate(documents: documents)
                }
            }
        
        friendshipListeners.append(listener1)
        
        // Listen for friendships where the user is the friend
        let listener2 = db.collection("friendships")
            .whereField("friendID", isEqualTo: userID)
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    self.logger.error("Error listening for friendship updates: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.logger.warning("No friendship documents found")
                    return
                }
                
                Task {
                    await self.handleFriendshipsUpdate(documents: documents)
                }
            }
        
        friendshipListeners.append(listener2)
    }
    
    private func handleUserUpdate(userID: String, data: [String: Any]) async {
        do {
            // Fetch existing user from SwiftData
            let descriptor = FetchDescriptor<UserModel>(predicate: #Predicate { (user: UserModel) -> Bool in 
                user.id == userID
            })
            
            let localUsers = try modelContext.fetch(descriptor)
            
            if let existingUser = localUsers.first {
                // Update existing user with remote data
                if let name = data["name"] as? String { existingUser.name = name }
                if let email = data["email"] as? String { existingUser.email = email }
                if let phoneNumber = data["phoneNumber"] as? String { existingUser.phoneNumber = phoneNumber }
                if let bio = data["bio"] as? String { existingUser.bio = bio }
                if let profileImageURL = data["profileImageURL"] as? String { existingUser.profileImageURL = profileImageURL }
                
                if let birthdayTimestamp = data["birthday"] as? TimeInterval {
                    existingUser.birthday = Date(timeIntervalSince1970: birthdayTimestamp)
                }
                
                existingUser.isSocialProfileActive = data["isSocialProfileActive"] as? Bool ?? existingUser.isSocialProfileActive
                
                if let socialAuthProvider = data["socialAuthProvider"] as? String {
                    existingUser.socialAuthProvider = socialAuthProvider
                }
                
                if let gradientIndex = data["gradientIndex"] as? Int {
                    existingUser.gradientIndex = gradientIndex
                }
                
                // Update preferences
                if let availabilityTimes = data["availabilityTimes"] as? [String] {
                    existingUser.availabilityTimes = availabilityTimes
                }
                
                if let availableDays = data["availableDays"] as? [String] {
                    existingUser.availableDays = availableDays
                }
                
                if let favoriteActivities = data["favoriteActivities"] as? [String] {
                    existingUser.favoriteActivities = favoriteActivities
                }
                
                if let calendarConnections = data["calendarConnections"] as? [String] {
                    existingUser.calendarConnections = calendarConnections
                }
                
                if let travelRadius = data["travelRadius"] as? String {
                    existingUser.travelRadius = travelRadius
                }
                
                // Update timestamps
                if let updatedTimestamp = data["updatedAt"] as? TimeInterval {
                    existingUser.updatedAt = Date(timeIntervalSince1970: updatedTimestamp)
                } else {
                    existingUser.updatedAt = Date()
                }
                
                // Save changes to SwiftData
                try modelContext.save()
                
                // Update timestamp for UI reactivity
                self.lastUpdateTimestamp = Date()
                logger.debug("Updated user \(userID) from Firestore listener")
            } else {
                // User doesn't exist locally, create new user
                // This shouldn't typically happen unless the user was deleted locally
                logger.warning("User \(userID) not found locally, fetching from Firestore")
                
                // Fetch full user data from repository (which will create it locally)
                _ = try await userRepository.getUser(id: userID)
                
                // Update timestamp for UI reactivity
                self.lastUpdateTimestamp = Date()
            }
        } catch {
            logger.error("Error handling user update: \(error.localizedDescription)")
        }
    }
    
    private func handleFriendshipsUpdate(documents: [QueryDocumentSnapshot]) async {
        do {
            for document in documents {
                let data = document.data()
                
                // Extract friendship ID (either stored as field or use document ID)
                let idString = data["id"] as? String ?? document.documentID
                guard let friendshipID = UUID(uuidString: idString) else {
                    logger.error("Invalid friendship ID format: \(idString)")
                    continue
                }
                
                // Check if friendship exists locally
                let descriptor = FetchDescriptor<FriendshipModel>(predicate: #Predicate { (friendship: FriendshipModel) -> Bool in 
                    friendship.id == friendshipID
                })
                
                let localFriendships = try modelContext.fetch(descriptor)
                
                if let existingFriendship = localFriendships.first {
                    // Check if remote data is newer
                    if let remoteUpdated = data["updatedAt"] as? TimeInterval,
                       Date(timeIntervalSince1970: remoteUpdated) > existingFriendship.updatedAt {
                        
                        // Update existing friendship
                        existingFriendship.relationshipType = data["relationshipType"] as? String ?? existingFriendship.relationshipType
                        
                        if let lastHangoutTimestamp = data["lastHangoutDate"] as? TimeInterval {
                            existingFriendship.lastHangoutDate = Date(timeIntervalSince1970: lastHangoutTimestamp)
                        }
                        
                        if let nextScheduledTimestamp = data["nextScheduledHangout"] as? TimeInterval {
                            existingFriendship.nextScheduledHangout = Date(timeIntervalSince1970: nextScheduledTimestamp)
                        }
                        
                        existingFriendship.customNotes = data["customNotes"] as? String
                        existingFriendship.isFavorite = data["isFavorite"] as? Bool ?? existingFriendship.isFavorite
                        
                        if let lastContactedTimestamp = data["lastContactedDate"] as? TimeInterval {
                            existingFriendship.lastContactedDate = Date(timeIntervalSince1970: lastContactedTimestamp)
                        }
                        
                        existingFriendship.updatedAt = Date(timeIntervalSince1970: remoteUpdated)
                        
                        // Save changes
                        try modelContext.save()
                        logger.debug("Updated friendship \(friendshipID) from Firestore listener")
                    }
                } else {
                    // Friendship doesn't exist locally, create it
                    let userID = data["userID"] as? String ?? ""
                    let friendID = data["friendID"] as? String ?? ""
                    
                    // Create new friendship
                    let newFriendship = FriendshipModel(
                        id: friendshipID,
                        userID: userID,
                        friendID: friendID,
                        relationshipType: data["relationshipType"] as? String ?? "friend",
                        isFavorite: data["isFavorite"] as? Bool ?? false
                    )
                    
                    // Set additional fields
                    if let lastHangoutTimestamp = data["lastHangoutDate"] as? TimeInterval {
                        newFriendship.lastHangoutDate = Date(timeIntervalSince1970: lastHangoutTimestamp)
                    }
                    
                    if let nextScheduledTimestamp = data["nextScheduledHangout"] as? TimeInterval {
                        newFriendship.nextScheduledHangout = Date(timeIntervalSince1970: nextScheduledTimestamp)
                    }
                    
                    newFriendship.customNotes = data["customNotes"] as? String
                    
                    if let lastContactedTimestamp = data["lastContactedDate"] as? TimeInterval {
                        newFriendship.lastContactedDate = Date(timeIntervalSince1970: lastContactedTimestamp)
                    }
                    
                    if let createdTimestamp = data["createdAt"] as? TimeInterval {
                        newFriendship.createdAt = Date(timeIntervalSince1970: createdTimestamp)
                    }
                    
                    if let updatedTimestamp = data["updatedAt"] as? TimeInterval {
                        newFriendship.updatedAt = Date(timeIntervalSince1970: updatedTimestamp)
                    }
                    
                    // Save to SwiftData
                    modelContext.insert(newFriendship)
                    try modelContext.save()
                    
                    logger.debug("Created friendship \(friendshipID) from Firestore listener")
                }
            }
            
            // Update timestamp for UI reactivity
            self.lastUpdateTimestamp = Date()
        } catch {
            logger.error("Error handling friendships update: \(error.localizedDescription)")
        }
    }
}

/// Factory for creating FirestoreListenerService instances
struct FirestoreListenerServiceFactory {
    /// Create the default listener service
    @MainActor
    static func createService(modelContext: ModelContext) -> FirestoreListenerService {
        return FirestoreListenerService(modelContext: modelContext)
    }
}
