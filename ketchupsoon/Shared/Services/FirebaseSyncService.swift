import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseFirestore
import OSLog
import Combine

/// Service that manages overall synchronization between Firebase and SwiftData
/// Coordinates all Firebase operations and provides a simple interface for the app
@MainActor
class FirebaseSyncService: ObservableObject {
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "FirebaseSyncService")
    private let modelContext: ModelContext
    
    // Services
    private let userRepository: UserRepository
    private let friendshipRepository: FriendshipRepository
    private let meetupRepository: MeetupRepository
    private let listenerService: FirestoreListenerService
    
    // Published properties for UI reactivity
    @Published var isSyncing: Bool = false
    @Published var lastSyncTimestamp: Date?
    @Published var syncError: Error?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Initialize repositories and services
        self.userRepository = UserRepositoryFactory.createRepository(modelContext: modelContext)
        self.friendshipRepository = FriendshipRepositoryFactory.createRepository(modelContext: modelContext)
        self.meetupRepository = MeetupRepositoryFactory.createRepository(modelContext: modelContext)
        self.listenerService = FirestoreListenerServiceFactory.createService(modelContext: modelContext)
    }
    
    // MARK: - Public Methods
    
    /// Start all Firebase services for the current user
    /// This should be called when the app starts or when a user logs in
    func startServices() {
        // Start real-time listeners
        listenerService.startListeningForCurrentUser()
        
        // Perform initial sync
        Task {
            await performFullSync()
        }
        
        logger.info("Started all Firebase services")
    }
    
    /// Stop all Firebase services
    /// This should be called when the app is backgrounded or when a user logs out
    func stopServices() {
        // Stop real-time listeners
        listenerService.stopAllListeners()
        
        logger.info("Stopped all Firebase services")
    }
    
    /// Perform a full sync between Firebase and SwiftData
    /// This will sync all user and friendship data
    func performFullSync() async {
        guard let currentUser = Auth.auth().currentUser else {
            logger.warning("Cannot sync - no current user")
            return
        }
        
        let userID = currentUser.uid
        
        // Set syncing state
        isSyncing = true
        syncError = nil
        
        do {
            // Sync user data
            logger.debug("Syncing user data")
            try await userRepository.refreshCurrentUser()
            
            // Sync friendship data
            logger.debug("Syncing friendship data")
            try await friendshipRepository.syncLocalWithRemote(for: userID)
            
            // Sync meetup data
            logger.debug("Syncing meetup data")
            try await meetupRepository.syncLocalWithRemote(for: userID)
            
            // Update sync timestamp
            lastSyncTimestamp = Date()
            logger.info("Completed full sync for user \(userID)")
        } catch {
            syncError = error
            logger.error("Error during full sync: \(error.localizedDescription)")
        }
        
        // Reset syncing state
        isSyncing = false
    }
    
    /// Create a new friendship between the current user and another user
    func createFriendship(with friendID: String, notes: String? = nil) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "com.ketchupsoon", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let friendship = FriendshipModel(
            userID: currentUser.uid,
            friendID: friendID,
            customNotes: notes
        )
        
        try await friendshipRepository.createFriendship(friendship: friendship)
    }
    
    /// Get all friends of the current user with their profile data
    func getFriendsWithProfiles() async throws -> [(FriendshipModel, UserModel)] {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "com.ketchupsoon", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await friendshipRepository.getFriendsWithProfiles(currentUserID: currentUser.uid)
    }
    
    /// Search for users by name or email
    func searchUsers(query: String) async throws -> [UserModel] {
        return try await userRepository.searchUsers(query: query)
    }
    
    /// Get count of pending friend requests for the current user
    func getPendingFriendRequestsCount() async throws -> Int {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "com.ketchupsoon", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await friendshipRepository.getPendingFriendRequestsCount(for: currentUser.uid)
    }
    
    /// Update the current user's profile
    func updateCurrentUserProfile(
        name: String? = nil,
        bio: String? = nil,
        birthday: Date? = nil,
        gradientIndex: Int? = nil,
        availabilityTimes: [String]? = nil,
        availableDays: [String]? = nil,
        favoriteActivities: [String]? = nil
    ) async throws {
        guard let currentUser = try await userRepository.getCurrentUser() else {
            throw NSError(domain: "com.ketchupsoon", code: 404, 
                         userInfo: [NSLocalizedDescriptionKey: "Current user not found"])
        }
        
        // Update fields if provided
        if let name = name { currentUser.name = name }
        if let bio = bio { currentUser.bio = bio }
        if let birthday = birthday { currentUser.birthday = birthday }
        if let gradientIndex = gradientIndex { currentUser.gradientIndex = gradientIndex }
        if let availabilityTimes = availabilityTimes { currentUser.availabilityTimes = availabilityTimes }
        if let availableDays = availableDays { currentUser.availableDays = availableDays }
        if let favoriteActivities = favoriteActivities { currentUser.favoriteActivities = favoriteActivities }
        
        // Update timestamp
        currentUser.updatedAt = Date()
        
        // Save changes
        try await userRepository.updateUser(user: currentUser)
    }
    
    /// Update a friendship with new information
    func updateFriendship(
        friendshipID: UUID,
        relationshipType: String? = nil,
        lastHangoutDate: Date? = nil,
        nextScheduledHangout: Date? = nil,
        customNotes: String? = nil,
        isFavorite: Bool? = nil
    ) async throws {
        // Fetch the friendship first
        let friendship = try await friendshipRepository.getFriendship(id: friendshipID)
        
        // Update fields if provided
        if let relationshipType = relationshipType { friendship.relationshipType = relationshipType }
        if let lastHangoutDate = lastHangoutDate { friendship.lastHangoutDate = lastHangoutDate }
        if let nextScheduledHangout = nextScheduledHangout { friendship.nextScheduledHangout = nextScheduledHangout }
        if let customNotes = customNotes { friendship.customNotes = customNotes }
        if let isFavorite = isFavorite { friendship.isFavorite = isFavorite }
        
        // Update timestamp
        friendship.updatedAt = Date()
        friendship.lastContactedDate = Date()
        
        // Save changes
        try await friendshipRepository.updateFriendship(friendship: friendship)
    }
    
    // MARK: - Meetup Methods
    
    /// Save a meetup to SwiftData and Firebase
    func saveMeetup(_ meetup: MeetupModel) async throws {
        try await meetupRepository.saveMeetup(meetup: meetup)
    }
    
    /// Delete a meetup (mark as deleted in Firebase)
    func deleteMeetup(_ meetup: MeetupModel) async throws {
        try await meetupRepository.deleteMeetup(meetup: meetup)
    }
    
    /// Get all meetups for the current user
    func getMeetups() async throws -> [MeetupModel] {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "com.ketchupsoon", code: 401, 
                        userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await meetupRepository.getMeetups(for: currentUser.uid)
    }
    
    /// Sync meetups from Firebase for the current user
    func syncMeetups() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "com.ketchupsoon", code: 401, 
                        userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await meetupRepository.syncLocalWithRemote(for: currentUser.uid)
    }
}

// MARK: - Meetup Repository

/// Repository interface for Meetup operations
protocol MeetupRepository {
    func saveMeetup(meetup: MeetupModel) async throws
    func deleteMeetup(meetup: MeetupModel) async throws
    func getMeetups(for userID: String) async throws -> [MeetupModel]
    func syncLocalWithRemote(for userID: String) async throws
}

/// Implementation of MeetupRepository using Firebase
class FirestoreMeetupRepository: MeetupRepository {
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "MeetupRepository")
    private let modelContext: ModelContext
    private let firestoreDB = Firestore.firestore()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func saveMeetup(meetup: MeetupModel) async throws {
        // Set timestamps and ID if needed
        meetup.updatedAt = Date()
        
        // Get Firestore reference
        let meetupsCollection = firestoreDB.collection("meetups")
        
        // Convert to Firestore data
        let meetupData = meetup.toFirestoreData()
        
        // Add to SwiftData if needed
        if !modelContext.hasChanges(for: meetup) {
            modelContext.insert(meetup)
        }
        
        // Save to Firestore
        try await meetupsCollection.document(meetup.id).setData(meetupData)
        
        logger.info("Saved meetup \(meetup.id) to Firestore")
    }
    
    func deleteMeetup(meetup: MeetupModel) async throws {
        // Mark as deleted instead of actually deleting
        meetup.isDeleted = true
        meetup.updatedAt = Date()
        
        // Update in Firestore
        try await saveMeetup(meetup: meetup)
        
        logger.info("Marked meetup \(meetup.id) as deleted")
    }
    
    func getMeetups(for userID: String) async throws -> [MeetupModel] {
        let descriptor = FetchDescriptor<MeetupModel>(predicate: #Predicate {
            $0.isDeleted == false && $0.participants.contains(userID)
        }, sortBy: [SortDescriptor(\MeetupModel.date)])
        
        return try modelContext.fetch(descriptor)
    }
    
    func syncLocalWithRemote(for userID: String) async throws {
        // Fetch meetups where the user is a participant and not deleted
        try await syncMeetups(for: userID)
        
        logger.info("Completed meetup sync for user \(userID)")
    }
    
    private func syncMeetups(for userID: String) async throws {
        // Fetch meetups from Firestore where the user is a participant
        let snapshot = try await firestoreDB.collection("meetups")
            .whereField("participants", arrayContains: userID)
            .whereField("isDeleted", isEqualTo: false)
            .getDocuments()
        
        // Create a set of remote meetup IDs for tracking
        var remoteMeetupIDs = Set<String>()
        
        for document in snapshot.documents {
            if let meetup = MeetupModel.fromFirestore(documentData: document.data(), documentID: document.documentID) {
                remoteMeetupIDs.insert(meetup.id)
                
                // Check if meetup already exists in SwiftData
                let descriptor = FetchDescriptor<MeetupModel>(predicate: #Predicate { $0.id == meetup.id })
                if let existingMeetup = try? modelContext.fetch(descriptor).first {
                    // Update existing meetup if the remote is newer
                    if meetup.updatedAt > existingMeetup.updatedAt {
                        existingMeetup.title = meetup.title
                        existingMeetup.date = meetup.date
                        existingMeetup.location = meetup.location
                        existingMeetup.activityType = meetup.activityType
                        existingMeetup.participants = meetup.participants
                        existingMeetup.notes = meetup.notes
                        existingMeetup.isAiGenerated = meetup.isAiGenerated
                        existingMeetup.updatedAt = meetup.updatedAt
                        existingMeetup.isDeleted = meetup.isDeleted
                    }
                } else {
                    // Insert new meetup
                    modelContext.insert(meetup)
                }
            }
        }
        
        // Optionally handle local meetups that no longer exist in Firebase
        // For now, we'll just leave them as is
    }
}

/// Factory for creating MeetupRepository instances
struct MeetupRepositoryFactory {
    static func createRepository(modelContext: ModelContext) -> MeetupRepository {
        return FirestoreMeetupRepository(modelContext: modelContext)
    }
}

/// Factory for creating FirebaseSyncService instances
struct FirebaseSyncServiceFactory {
    /// Create the default sync service
    @MainActor
    static func createService(modelContext: ModelContext) -> FirebaseSyncService {
        return FirebaseSyncService(modelContext: modelContext)
    }
    
    // Preview service for SwiftUI previews
    static var preview: FirebaseSyncService {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: UserModel.self, FriendshipModel.self, MeetupModel.self, configurations: config)
        return FirebaseSyncService(modelContext: container.mainContext)
    }
}
