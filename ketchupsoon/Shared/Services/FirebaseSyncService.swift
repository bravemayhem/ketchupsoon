import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseFirestore
import OSLog
import Combine

/// Service that manages overall synchronization between Firebase and SwiftData
/// Coordinates all Firebase operations and provides a simple interface for the app
@MainActor
class FirebaseSyncService: ObservableObject, AuthStateSubscriber {
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "FirebaseSyncService")
    private let modelContext: ModelContext
    
    // Services
    private let userRepository: UserRepository
    private let friendshipRepository: FriendshipRepository
    private let meetupRepository: MeetupRepository
    private let operationCoordinator: FirebaseOperationCoordinator
    
    // Published properties for UI reactivity
    @Published var isSyncing: Bool = false
    @Published var lastSyncTimestamp: Date?
    @Published var syncError: Error?
    
    // MARK: - Concurrency Safety
    
    // Actor to provide thread-safe access to repository operations
    private actor RepositoryAccessActor {
        func performOperation<T>(_ operation: @escaping () async throws -> T) async throws -> T {
            try await operation()
        }
    }
    
    private let repositoryAccessActor = RepositoryAccessActor()
    
    @MainActor
    private func performRepositoryUpdate<T>(_ update: @escaping () async throws -> T) async throws -> T {
        // Use the actor to ensure isolation and concurrency safety
        return try await repositoryAccessActor.performOperation(update)
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Initialize repositories and services
        self.userRepository = UserRepositoryFactory.createRepository(modelContext: modelContext)
        self.friendshipRepository = FriendshipRepositoryFactory.createRepository(modelContext: modelContext)
        self.meetupRepository = MeetupRepositoryFactory.createRepository(modelContext: modelContext)
        self.operationCoordinator = FirebaseOperationCoordinator.shared
        
        // Register with auth state service
        Task { @MainActor in
            AuthStateService.shared.subscribe(self)
        }
    }
    
    deinit {
        // Create a local reference to ensure we don't capture self in the task
        let subscriber = self
        // Use detached task to avoid implicitly capturing self
        Task.detached { @MainActor in
            AuthStateService.shared.unsubscribe(subscriber)
        }
    }
    
    // MARK: - AuthStateSubscriber Implementation
    
    nonisolated func onAuthStateChanged(newState: AuthState, previousState: AuthState?) {
        Task { @MainActor in
            await handleAuthStateChange(newState: newState, previousState: previousState)
        }
    }
    
    @MainActor
    private func handleAuthStateChange(newState: AuthState, previousState: AuthState?) async {
        switch newState {
        case .authenticated:
            // User authenticated, start services
            if previousState == nil || previousState == .notAuthenticated {
                logger.notice("Auth state changed to authenticated, starting services")
                await startServices()
            }
        case .notAuthenticated:
            // User signed out, stop services
            if previousState?.isAuthenticated == true {
                logger.notice("Auth state changed to not authenticated, stopping services")
                stopServices()
            }
        case .refreshing:
            // Just refreshing, do nothing
            break
        }
    }
    
    // MARK: - Public Methods
    
    /// Start all Firebase services for the current user
    /// This should be called when the app starts or when a user logs in
    func startServices() async {
        // Perform initial sync
        await performFullSync()
        
        if FirebaseOperationCoordinator.shared.logVerbosity >= .important {
            logger.notice("Started all Firebase services")
        }
    }
    
    /// Stop all Firebase services
    /// This should be called when the app is backgrounded or when a user logs out
    func stopServices() {
        if FirebaseOperationCoordinator.shared.logVerbosity >= .important {
            logger.notice("Stopped all Firebase services")
        }
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
        
        // Schedule a full sync operation
        // Capture necessary dependencies locally to avoid capturing self in the closure
        let logger = self.logger
        let userRepository = self.userRepository
        let friendshipRepository = self.friendshipRepository
        let meetupRepository = self.meetupRepository
        
        operationCoordinator.scheduleOperation(
            name: "Full Data Sync",
            key: "full_sync_\(userID)",
            priority: .high,
            minInterval: 30.0, // 30 seconds minimum between full syncs
            operation: { [weak self] in
                // Use weak self to avoid reference cycles
                guard let self = self else { return }
                
                do {
                    // Sync user data
                    if FirebaseOperationCoordinator.shared.logVerbosity >= .verbose {
                        logger.debug("Syncing user data")
                    }
                    try await self.performRepositoryUpdate {
                        try await userRepository.refreshCurrentUser()
                    }
                    
                    // Sync friendship data
                    if FirebaseOperationCoordinator.shared.logVerbosity >= .verbose {
                        logger.debug("Syncing friendship data")
                    }
                    try await self.performRepositoryUpdate {
                        try await friendshipRepository.syncLocalWithRemote(for: userID)
                    }
                    
                    // Sync meetup data
                    if FirebaseOperationCoordinator.shared.logVerbosity >= .verbose {
                        logger.debug("Syncing meetup data")
                    }
                    try await self.performRepositoryUpdate {
                        try await meetupRepository.syncLocalWithRemote(for: userID)
                    }
                    
                    // Update sync timestamp
                    await MainActor.run {
                        self.lastSyncTimestamp = Date()
                        self.isSyncing = false
                    }
                    
                    if FirebaseOperationCoordinator.shared.logVerbosity >= .important {
                        logger.notice("Completed full sync for user \(userID)")
                    }
                } catch {
                    await MainActor.run {
                        self.syncError = error
                        self.isSyncing = false
                    }
                    logger.error("Error during full sync: \(error.localizedDescription)")
                }
            },
            errorHandler: { [weak self] error in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.syncError = error
                    self.isSyncing = false
                }
            }
        )
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
        
        try await performRepositoryUpdate {
            try await self.friendshipRepository.createFriendship(friendship: friendship)
        }
    }
    
    /// Get all friends of the current user with their profile data
    func getFriendsWithProfiles() async throws -> [(FriendshipModel, UserModel)] {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "com.ketchupsoon", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await performRepositoryUpdate {
            try await self.friendshipRepository.getFriendsWithProfiles(currentUserID: currentUser.uid)
        }
    }
    
    /// Search for users by name or email
    func searchUsers(query: String) async throws -> [UserModel] {
        return try await performRepositoryUpdate {
            try await self.userRepository.searchUsers(query: query)
        }
    }
    
    /// Get count of pending friend requests for the current user
    func getPendingFriendRequestsCount() async throws -> Int {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "com.ketchupsoon", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await performRepositoryUpdate {
            try await self.friendshipRepository.getPendingFriendRequestsCount(for: currentUser.uid)
        }
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
        try await performRepositoryUpdate {
            try await self.userRepository.updateUser(user: currentUser)
        }
    }
    
    /// Update the current user's profile image URL
    func updateCurrentUserProfileImage(url: String) async throws {
        guard let currentUser = try await userRepository.getCurrentUser() else {
            throw NSError(domain: "com.ketchupsoon", code: 404, 
                         userInfo: [NSLocalizedDescriptionKey: "Current user not found"])
        }
        
        // Update profile image URL
        currentUser.profileImageURL = url
        
        // Update timestamp
        currentUser.updatedAt = Date()
        
        // Save changes
        try await performRepositoryUpdate {
            try await self.userRepository.updateUser(user: currentUser)
        }
        
        logger.info("Updated profile image URL to: \(url)")
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
        try await performRepositoryUpdate {
            try await self.friendshipRepository.updateFriendship(friendship: friendship)
        }
    }
    
    // MARK: - Meetup Methods
    
    /// Save a meetup to SwiftData and Firebase
    func saveMeetup(_ meetup: MeetupModel) async throws {
        try await performRepositoryUpdate {
            try await self.meetupRepository.saveMeetup(meetup: meetup)
        }
    }
    
    /// Delete a meetup (mark as deleted in Firebase)
    func deleteMeetup(_ meetup: MeetupModel) async throws {
        try await performRepositoryUpdate {
            try await self.meetupRepository.deleteMeetup(meetup: meetup)
        }
    }
    
    /// Get all meetups for the current user
    func getMeetups() async throws -> [MeetupModel] {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "com.ketchupsoon", code: 401, 
                        userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await performRepositoryUpdate {
            try await self.meetupRepository.getMeetups(for: currentUser.uid)
        }
    }
    
    /// Sync meetups from Firebase for the current user
    func syncMeetups() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "com.ketchupsoon", code: 401, 
                        userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await performRepositoryUpdate {
            try await self.meetupRepository.syncLocalWithRemote(for: currentUser.uid)
        }
    }
    
    /// Update a user preference in Firebase
    /// - Parameters:
    ///   - userID: The ID of the user
    ///   - key: The preference key to update
    ///   - value: The new value (must be a type that can be stored in Firebase)
    @available(*, deprecated, message: "Use type-safe updateUserPreference methods instead")
    func updateUserPreference(userID: String, key: String, value: Any) async throws {
        // Since we need to maintain backward compatibility, redirect to appropriate type methods
        if let stringValue = value as? String {
            try await updateUserPreference(userID: userID, key: key, value: stringValue)
        } else if let intValue = value as? Int {
            try await updateUserPreference(userID: userID, key: key, value: intValue)
        } else if let doubleValue = value as? Double {
            try await updateUserPreference(userID: userID, key: key, value: doubleValue)
        } else if let boolValue = value as? Bool {
            try await updateUserPreference(userID: userID, key: key, value: boolValue)
        } else if let stringArray = value as? [String] {
            try await updateUserPreference(userID: userID, key: key, value: stringArray)
        } else if let stringDict = value as? [String: String] {
            try await updateUserPreference(userID: userID, key: key, value: stringDict)
        } else {
            throw NSError(domain: "com.ketchupsoon", code: 400,
                         userInfo: [NSLocalizedDescriptionKey: "Unsupported preference value type. Use type-safe methods instead."])
        }
    }
    
    // MARK: - Type-safe preference updates
    
    /// Update a user preference with a String value (Sendable-compliant)
    func updateUserPreference(userID: String, key: String, value: String) async throws {
        try await updateUserPreferenceInternal(userID: userID, key: key, value: value)
    }
    
    /// Update a user preference with an Int value (Sendable-compliant)
    func updateUserPreference(userID: String, key: String, value: Int) async throws {
        try await updateUserPreferenceInternal(userID: userID, key: key, value: value)
    }
    
    /// Update a user preference with a Double value (Sendable-compliant)
    func updateUserPreference(userID: String, key: String, value: Double) async throws {
        try await updateUserPreferenceInternal(userID: userID, key: key, value: value)
    }
    
    /// Update a user preference with a Bool value (Sendable-compliant)
    func updateUserPreference(userID: String, key: String, value: Bool) async throws {
        try await updateUserPreferenceInternal(userID: userID, key: key, value: value)
    }
    
    /// Update a user preference with a String array (Sendable-compliant)
    func updateUserPreference(userID: String, key: String, value: [String]) async throws {
        try await updateUserPreferenceInternal(userID: userID, key: key, value: value)
    }
    
    /// Update a user preference with a String dictionary (Sendable-compliant)
    func updateUserPreference(userID: String, key: String, value: [String: String]) async throws {
        try await updateUserPreferenceInternal(userID: userID, key: key, value: value)
    }
    
    /// Internal implementation for updating user preferences with Sendable types
    private func updateUserPreferenceInternal<T: Sendable>(userID: String, key: String, value: T) async throws {
        guard Auth.auth().currentUser != nil else {
            throw NSError(domain: "com.ketchupsoon", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Ensure we're updating the current user's preferences only
        guard let currentUser = try await userRepository.getCurrentUser(), 
              currentUser.id == userID else {
            throw NSError(domain: "com.ketchupsoon", code: 403, 
                         userInfo: [NSLocalizedDescriptionKey: "Cannot update preferences for another user"])
        }
        
        // Update the user preference in Firestore
        let userRef = Firestore.firestore().collection("users").document(userID)
        
        // Since Firebase's updateData requires [String: Any] but we need to maintain Sendable,
        // we'll need to apply special handling for each supported type
        @MainActor func updateFirestoreData() async throws {
            // On the main actor, we can safely work with non-Sendable types
            let updateData = ["preferences.\(key)": value]
            try await userRef.updateData(updateData)
        }
        
        // Perform the update on the main actor
        try await updateFirestoreData()
        
        // Update local model if needed
        if var preferences = currentUser.getPreferences() {
            preferences[key] = value
            currentUser.setPreferences(preferences)
            try await userRepository.updateUser(user: currentUser)
        } else {
            // If preferences don't exist yet, create them
            currentUser.setPreferences([key: value])
            try await userRepository.updateUser(user: currentUser)
        }
        
        logger.info("Successfully updated user preference: \(key) for user: \(userID)")
    }
    
    /// Clear all user data from Firebase
    /// This will remove all user-related data from Firestore but keep the auth account
    /// - Parameter userID: The ID of the user whose data should be cleared
    func clearAllUserData(userID: String) async throws {
        guard let currentUser = Auth.auth().currentUser, currentUser.uid == userID else {
            throw NSError(domain: "com.ketchupsoon", code: 403, 
                         userInfo: [NSLocalizedDescriptionKey: "Cannot clear data for another user"])
        }
        
        let firestoreDB = Firestore.firestore()
        let batch = firestoreDB.batch()
        
        // 1. Clear user profile data (but don't delete the document)
        logger.info("Clearing user profile data for user: \(userID)")
        let userRef = firestoreDB.collection("users").document(userID)
        
        // Keep minimal information but clear everything else
        let minimalUserData: [String: Any] = [
            "name": "",
            "email": currentUser.email ?? "",
            "preferences": [:],
            "availabilityTimes": [],
            "availableDays": [],
            "favoriteActivities": [],
            "bio": "",
            "updatedAt": FieldValue.serverTimestamp(),
            "dataCleared": true  // Flag to indicate this user has cleared their data
        ]
        batch.setData(minimalUserData, forDocument: userRef, merge: false)
        
        // 2. Get and delete all friendships
        logger.info("Clearing friendships for user: \(userID)")
        let friendshipsQuery = try await firestoreDB.collection("friendships")
            .whereField("userID", isEqualTo: userID)
            .getDocuments()
        
        for document in friendshipsQuery.documents {
            batch.deleteDocument(document.reference)
        }
        
        // 3. Get and delete all meetups where user is a participant
        logger.info("Clearing meetups for user: \(userID)")
        let meetupsQuery = try await firestoreDB.collection("meetups")
            .whereField("participants", arrayContains: userID)
            .getDocuments()
        
        for document in meetupsQuery.documents {
            batch.deleteDocument(document.reference)
        }
        
        // 4. Commit the batch operation
        try await batch.commit()
        
        // 5. Stop services to prevent immediate re-sync
        stopServices()
        
        logger.info("Successfully cleared all Firebase data for user: \(userID)")
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
    private let friendshipRepository: FriendshipRepository
    private let firestoreService: FirestoreListenerService
    private lazy var firestoreDB: Firestore = {
        return Firestore.firestore()
    }()
    
    init(modelContext: ModelContext, friendshipRepository: FriendshipRepository, firestoreService: FirestoreListenerService) {
        self.modelContext = modelContext
        self.friendshipRepository = friendshipRepository
        self.firestoreService = firestoreService
    }
    
    func saveMeetup(meetup: MeetupModel) async throws {
        // Set timestamps and ID if needed
        meetup.updatedAt = Date()
        
        // Get Firestore reference
        let meetupsCollection = firestoreDB.collection("meetups")
        
        // Convert to Firestore data
        let meetupData = meetup.toFirestoreData()
        
        // Add to SwiftData
        modelContext.insert(meetup)
        
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
        // Create descriptor with sort but no predicate initially
        let descriptor = FetchDescriptor<MeetupModel>(
            sortBy: [SortDescriptor(\MeetupModel.date)]
        )
        
        // Fetch all meetups and filter in memory
        let allMeetups = try modelContext.fetch(descriptor)
        return allMeetups.filter { !$0.isDeleted && $0.participants.contains(userID) }
    }
    
    func syncLocalWithRemote(for userID: String) async throws {
        // Fetch meetups where the user is a participant and not deleted
        try await syncMeetups(for: userID)
        
        logger.info("Completed meetup sync for user \(userID)")
    }
    
    private func syncUserFriendships() async {
        do {
            guard let currentUser = Auth.auth().currentUser else {
                logger.warning("Cannot sync friendships - no current user")
                return
            }
            // Use the repository's syncLocalWithRemote method instead
            try await friendshipRepository.syncLocalWithRemote(for: currentUser.uid)
        } catch {
            logger.error("Error syncing user friendships: \(error.localizedDescription)")
        }
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
                let descriptor = FetchDescriptor<MeetupModel>()
                
                // Fetch all and find match in memory
                let existingMeetups = try modelContext.fetch(descriptor)
                let existingMeetup = existingMeetups.first { $0.id == meetup.id }
                if let existingMeetup = existingMeetup {
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
    
    var listener: ListenerRegistration?
    
    func startListeningToFriendRequests() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        // Create a Firestore listener to observe friend requests
        let db = Firestore.firestore()
        listener = db.collection("friendships")
            .whereField("friendID", isEqualTo: currentUser.uid)
            .whereField("relationshipType", isEqualTo: "pending")
            .addSnapshotListener { [weak self] (snapshot, error) in
                if let error = error {
                    self?.logger.error("Error listening for friend requests: \(error.localizedDescription)")
                    return
                }
                
                // When friend requests change, sync friendships
                Task { [weak self] in
                    await self?.syncUserFriendships()
                }
            }
    }
}

/// Factory for creating MeetupRepository instances
struct MeetupRepositoryFactory {
    @MainActor
    static func createRepository(modelContext: ModelContext) -> MeetupRepository {
        let friendshipRepository = FriendshipRepositoryFactory.createRepository(modelContext: modelContext)
        let firestoreService = FirestoreListenerServiceFactory.createService(modelContext: modelContext)
        return FirestoreMeetupRepository(modelContext: modelContext, friendshipRepository: friendshipRepository, firestoreService: firestoreService)
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
    @MainActor
    static var preview: FirebaseSyncService {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: UserModel.self, FriendshipModel.self, MeetupModel.self, configurations: config)
        return FirebaseSyncService(modelContext: container.mainContext)
    }
}
