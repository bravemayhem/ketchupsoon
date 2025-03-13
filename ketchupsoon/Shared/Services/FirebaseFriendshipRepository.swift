import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseFirestore
import OSLog

/// Firebase implementation of the FriendshipRepository protocol
/// Handles friendship data operations with Firebase and syncs with SwiftData
@MainActor
class FirebaseFriendshipRepository: FriendshipRepository {
    // MARK: - Properties
    
    private lazy var db: Firestore = {
        return Firestore.firestore()
    }()
    private let friendshipsCollection = "friendships"
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "FirebaseFriendshipRepository")
    private let modelContext: ModelContext
    
    // UserRepository dependency for fetching user profiles
    private var _userRepository: UserRepository?
    
    @MainActor
    private func getUserRepository() async -> UserRepository {
        if let repository = _userRepository {
            return repository
        }
        let repository = UserRepositoryFactory.createRepository(modelContext: modelContext)
        _userRepository = repository
        return repository
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Helper method to perform Firebase operations on background threads
    private func performFirebaseOperation<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        // Detach the Firebase operation from the main actor to avoid blocking UI
        return try await Task.detached {
            return try await operation()
        }.value
    }
    
    // MARK: - Helper Methods
    
    private func createFriendshipModelFromFirebaseData(id: String, data: [String: Any]) -> FriendshipModel {
        let friendship = FriendshipModel()
        
        // Basic data
        friendship.id = UUID(uuidString: id) ?? UUID()
        friendship.userID = data["userID"] as? String ?? ""
        friendship.friendID = data["friendID"] as? String ?? ""
        friendship.relationshipType = data["relationshipType"] as? String ?? "friend"
        
        // Metadata
        if let lastHangoutTimestamp = data["lastHangoutDate"] as? TimeInterval {
            friendship.lastHangoutDate = Date(timeIntervalSince1970: lastHangoutTimestamp)
        }
        
        if let nextScheduledTimestamp = data["nextScheduledHangout"] as? TimeInterval {
            friendship.nextScheduledHangout = Date(timeIntervalSince1970: nextScheduledTimestamp)
        }
        
        friendship.customNotes = data["customNotes"] as? String
        friendship.isFavorite = data["isFavorite"] as? Bool ?? false
        
        if let lastContactedTimestamp = data["lastContactedDate"] as? TimeInterval {
            friendship.lastContactedDate = Date(timeIntervalSince1970: lastContactedTimestamp)
        }
        
        // Tracking data
        if let createdTimestamp = data["createdAt"] as? TimeInterval {
            friendship.createdAt = Date(timeIntervalSince1970: createdTimestamp)
        }
        
        if let updatedTimestamp = data["updatedAt"] as? TimeInterval {
            friendship.updatedAt = Date(timeIntervalSince1970: updatedTimestamp)
        }
        
        return friendship
    }
    
    private func friendshipToFirebaseDictionary(_ friendship: FriendshipModel) -> [String: Any] {
        var dict: [String: Any] = [
            "userID": friendship.userID,
            "friendID": friendship.friendID,
            "relationshipType": friendship.relationshipType,
            "isFavorite": friendship.isFavorite,
            "createdAt": friendship.createdAt.timeIntervalSince1970,
            "updatedAt": Date().timeIntervalSince1970 // Always update the timestamp
        ]
        
        if let lastHangoutDate = friendship.lastHangoutDate {
            dict["lastHangoutDate"] = lastHangoutDate.timeIntervalSince1970
        }
        
        if let nextScheduledHangout = friendship.nextScheduledHangout {
            dict["nextScheduledHangout"] = nextScheduledHangout.timeIntervalSince1970
        }
        
        if let customNotes = friendship.customNotes {
            dict["customNotes"] = customNotes
        }
        
        if let lastContactedDate = friendship.lastContactedDate {
            dict["lastContactedDate"] = lastContactedDate.timeIntervalSince1970
        }
        
        return dict
    }
    
    // MARK: - Document ID Generation for Friendships
    
    private func generateFirestoreDocumentID(userID: String, friendID: String) -> String {
        // Create a consistent ID regardless of order
        let sortedIDs = [userID, friendID].sorted()
        return "\(sortedIDs[0])_\(sortedIDs[1])"
    }
    
    // MARK: - Friendship Fetching Methods
    
    func getFriendship(id: UUID) async throws -> FriendshipModel {
        // First check if friendship exists in SwiftData
        let targetId = id // Create a local variable for the UUID
        let descriptor = FetchDescriptor<FriendshipModel>(predicate: #Predicate { (friendship: FriendshipModel) -> Bool in 
            friendship.id == targetId
        })
        
        do {
            let localFriendships = try modelContext.fetch(descriptor)
            if let existingFriendship = localFriendships.first {
                self.logger.debug("Found friendship \(id) in local database")
                return existingFriendship
            }
        } catch {
            self.logger.error("Error fetching friendship from SwiftData: \(error.localizedDescription)")
            // Continue to fetch from Firebase rather than throwing
        }
        
        // Not found locally, fetch from Firebase
        self.logger.debug("Fetching friendship \(id) from Firebase")
        
        do {
            // Query friendships by UUID (stored as a field)
            let idString = id.uuidString
            let snapshot = try await self.db.collection(self.friendshipsCollection)
                .whereField("id", isEqualTo: idString)
                .getDocuments()
            
            guard let document = snapshot.documents.first else {
                throw NSError(domain: "com.ketchupsoon", code: 404, 
                             userInfo: [NSLocalizedDescriptionKey: "Friendship not found"])
            }
            
            let data = document.data()
            
            // Create a new friendship and save it to SwiftData
            let friendship = self.createFriendshipModelFromFirebaseData(id: document.documentID, data: data)
            
            // Save to local database
            self.modelContext.insert(friendship)
            try self.modelContext.save()
            
            return friendship
        } catch {
            self.logger.error("Error fetching friendship from Firebase: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getFriendshipsForCurrentUser() async throws -> [FriendshipModel] {
        guard let currentUser = Auth.auth().currentUser else {
            self.logger.warning("No user currently logged in")
            throw NSError(domain: "com.ketchupsoon", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let userID = currentUser.uid
        
        // First check if friendships exist in SwiftData
        let descriptor = FetchDescriptor<FriendshipModel>(predicate: #Predicate { (friendship: FriendshipModel) -> Bool in 
            friendship.userID == userID
        })
        
        do {
            let localFriendships = try modelContext.fetch(descriptor)
            if !localFriendships.isEmpty {
                self.logger.debug("Found \(localFriendships.count) friendships in local database")
                return localFriendships
            }
        } catch {
            self.logger.error("Error fetching friendships from SwiftData: \(error.localizedDescription)")
            // Continue to fetch from Firebase rather than throwing
        }
        
        // Not found locally or empty, fetch from Firebase
        self.logger.debug("Fetching friendships for user \(userID) from Firebase")
        
        // Perform Firebase operation on background thread
        return try await performFirebaseOperation {
        
        do {
            // Query friendships where userID matches current user
            let snapshot = try await self.db.collection(self.friendshipsCollection)
                .whereField("userID", isEqualTo: userID)
                .getDocuments()
            
            var friendships: [FriendshipModel] = []
            
            for document in snapshot.documents {
                let data = document.data()
                let friendship = self.createFriendshipModelFromFirebaseData(id: document.documentID, data: data)
                friendships.append(friendship)
                
                // Save to local database
                self.modelContext.insert(friendship)
            }
            
            if !friendships.isEmpty {
                try self.modelContext.save()
            }
            
            // Also check for friendships where the current user is the friend
            // This handles bidirectional relationship representation
            let reverseSnapshot = try await self.db.collection(self.friendshipsCollection)
                .whereField("friendID", isEqualTo: userID)
                .getDocuments()
            
            for document in reverseSnapshot.documents {
                let data = document.data()
                // Only add if not already added (to avoid duplicates)
                if !friendships.contains(where: { $0.id.uuidString == document.documentID }) {
                    let friendship = self.createFriendshipModelFromFirebaseData(id: document.documentID, data: data)
                    friendships.append(friendship)
                    
                    // Save to local database
                    self.modelContext.insert(friendship)
                }
            }
            
            if reverseSnapshot.documents.count > 0 {
                try self.modelContext.save()
            }
            
            return friendships
        } catch {
            self.logger.error("Error fetching friendships from Firebase: \(error.localizedDescription)")
            throw error
        }
        }
    }
    
    func getFriendship(currentUserID: String, friendID: String) async throws -> FriendshipModel? {
        // First check if friendship exists in SwiftData
        let descriptor = FetchDescriptor<FriendshipModel>(predicate: #Predicate { (friendship: FriendshipModel) -> Bool in 
            (friendship.userID == currentUserID && friendship.friendID == friendID) ||
            (friendship.userID == friendID && friendship.friendID == currentUserID)
        })
        
        do {
            let localFriendships = try modelContext.fetch(descriptor)
            if let existingFriendship = localFriendships.first {
                self.logger.debug("Found friendship between \(currentUserID) and \(friendID) in local database")
                return existingFriendship
            }
        } catch {
            self.logger.error("Error fetching friendship from SwiftData: \(error.localizedDescription)")
            // Continue to fetch from Firebase rather than throwing
        }
        
        // Not found locally, fetch from Firebase
        self.logger.debug("Fetching friendship between \(currentUserID) and \(friendID) from Firebase")
        
        // Perform Firebase operation on background thread
        return try await performFirebaseOperation {
            do {
                // Create a consistent document ID for this friendship
                let docID = self.generateFirestoreDocumentID(userID: currentUserID, friendID: friendID)
                
                let documentSnapshot = try await self.db.collection(self.friendshipsCollection).document(docID).getDocument()
                
                guard documentSnapshot.exists, let data = documentSnapshot.data() else {
                    // No friendship exists
                    return nil
                }
                
                // Create a new friendship
                let friendship = self.createFriendshipModelFromFirebaseData(id: documentSnapshot.documentID, data: data)
                
                // Return to main thread for SwiftData operations
                return await MainActor.run {
                    // Save to local database
                    self.modelContext.insert(friendship)
                    try? self.modelContext.save()
                    
                    return friendship
                }
            } catch {
                self.logger.error("Error fetching friendship from Firebase: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    // MARK: - Friendship Management Methods
    
    func createFriendship(friendship: FriendshipModel) async throws {
        self.logger.debug("Creating friendship between \(friendship.userID) and \(friendship.friendID)")
        
        // Ensure friendship doesn't already exist
        let existingFriendship = try await getFriendship(currentUserID: friendship.userID, friendID: friendship.friendID)
        
        if existingFriendship != nil {
            throw NSError(domain: "com.ketchupsoon", code: 409, 
                         userInfo: [NSLocalizedDescriptionKey: "Friendship already exists"])
        }
        
        // Create a consistent document ID for this friendship
        let docID = generateFirestoreDocumentID(userID: friendship.userID, friendID: friendship.friendID)
        
        // Prepare data for Firebase
        var firestoreData = friendshipToFirebaseDictionary(friendship)
        firestoreData["id"] = friendship.id.uuidString // Store UUID as string field
        
        do {
            // Save to Firestore
            try await self.db.collection(self.friendshipsCollection).document(docID).setData(firestoreData)
            
            // Save to local database
            let targetId = friendship.id // Create a local variable for the UUID
            let descriptor = FetchDescriptor<FriendshipModel>(predicate: #Predicate { (f: FriendshipModel) -> Bool in
                f.id == targetId
            })
            let existingFriendships = try modelContext.fetch(descriptor)
            
            if existingFriendships.isEmpty {
                self.modelContext.insert(friendship)
                try self.modelContext.save()
            }
            
            logger.info("Successfully created friendship between \(friendship.userID) and \(friendship.friendID)")
        } catch {
            self.logger.error("Error creating friendship in Firebase: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateFriendship(friendship: FriendshipModel) async throws {
        self.logger.debug("Updating friendship \(friendship.id)")
        
        // Create a consistent document ID for this friendship
        let docID = generateFirestoreDocumentID(userID: friendship.userID, friendID: friendship.friendID)
        
        // Prepare updated data for Firebase
        var firestoreData = friendshipToFirebaseDictionary(friendship)
        firestoreData["id"] = friendship.id.uuidString // Store UUID as string field
        firestoreData["updatedAt"] = Date().timeIntervalSince1970 // Update timestamp
        
        do {
            // Check if document exists
            let documentSnapshot = try await self.db.collection(self.friendshipsCollection).document(docID).getDocument()
            
            if !documentSnapshot.exists {
                throw NSError(domain: "com.ketchupsoon", code: 404, 
                             userInfo: [NSLocalizedDescriptionKey: "Friendship not found"])
            }
            
            // Update in Firestore
            try await self.db.collection(self.friendshipsCollection).document(docID).updateData(firestoreData)
            
            // Update in SwiftData
            friendship.updatedAt = Date()
            try self.modelContext.save()
            
            logger.info("Successfully updated friendship \(friendship.id)")
        } catch {
            self.logger.error("Error updating friendship in Firebase: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteFriendship(id: UUID) async throws {
        self.logger.debug("Deleting friendship \(id)")
        
        // First find the friendship to get the user and friend IDs
        let targetId = id // Create a local variable for the UUID
        let descriptor = FetchDescriptor<FriendshipModel>(predicate: #Predicate { (friendship: FriendshipModel) -> Bool in 
            friendship.id == targetId
        })
        
        do {
            let localFriendships = try modelContext.fetch(descriptor)
            
            guard let friendship = localFriendships.first else {
                throw NSError(domain: "com.ketchupsoon", code: 404, 
                             userInfo: [NSLocalizedDescriptionKey: "Friendship not found locally"])
            }
            
            // Create a consistent document ID for this friendship
            let docID = self.generateFirestoreDocumentID(userID: friendship.userID, friendID: friendship.friendID)
            
            // Delete from Firestore
            try await self.db.collection(self.friendshipsCollection).document(docID).delete()
            
            // Delete from SwiftData
            self.modelContext.delete(friendship)
            try self.modelContext.save()
            
            logger.info("Successfully deleted friendship \(id)")
        } catch {
            self.logger.error("Error deleting friendship: \(error.localizedDescription)")
            throw error
        }
    }
    
    func removeFriendship(currentUserID: String, friendID: String) async throws {
        self.logger.debug("Removing friendship between \(currentUserID) and \(friendID)")
        
        do {
            // Find the friendship
            guard let friendship = try await getFriendship(currentUserID: currentUserID, friendID: friendID) else {
                throw NSError(domain: "com.ketchupsoon", code: 404, 
                             userInfo: [NSLocalizedDescriptionKey: "Friendship not found"])
            }
            
            // Use the deleteFriendship method to handle both local and remote deletion
            try await deleteFriendship(id: friendship.id)
        } catch {
            self.logger.error("Error removing friendship: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Special Operations
    
    func checkFriendshipExists(currentUserID: String, friendID: String) async throws -> Bool {
        do {
            let friendship = try await getFriendship(currentUserID: currentUserID, friendID: friendID)
            return friendship != nil
        } catch {
            self.logger.error("Error checking friendship existence: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Get all friends of the current user with their user profiles
    func getFriendsWithProfiles(currentUserID: String) async throws -> [(FriendshipModel, UserModel)] {
        self.logger.debug("Getting friends with profiles for user \(currentUserID)")
        
        do {
            // Get all friendships for the current user - this runs on the main thread because of @MainActor
            let descriptor = FetchDescriptor<FriendshipModel>(predicate: #Predicate { (friendship: FriendshipModel) -> Bool in 
                friendship.userID == currentUserID || friendship.friendID == currentUserID
            })
            
            let localFriendships = try modelContext.fetch(descriptor)
            
            // If no local friendships, fetch from Firebase
            let friendships = localFriendships.isEmpty ? 
                try await getFriendshipsForCurrentUser() : 
                localFriendships
            
            // Get the user repository once for all operations
            let userRepository = await getUserRepository()
            
            // Use a task group to fetch friend profiles in parallel
            return try await withThrowingTaskGroup(of: (FriendshipModel, UserModel)?.self) { group in
                // Capture friendships array for use in task group
                let friendshipsForTasks = friendships
                
                // Process friendships in parallel
                for friendship in friendshipsForTasks {
                    // Determine which ID is the friend's ID
                    let friendUserID = friendship.userID == currentUserID ? friendship.friendID : friendship.userID
                    
                    // Add a task for each friend profile to fetch
                    group.addTask {
                        do {
                            // Get the friend's profile
                            let friendProfile = try await userRepository.getUser(id: friendUserID)
                            return (friendship, friendProfile)
                        } catch {
                            self.logger.error("Error fetching friend profile for \(friendUserID): \(error.localizedDescription)")
                            return nil
                        }
                    }
                }
                
                // Collect results
                var result: [(FriendshipModel, UserModel)] = []
                for try await pair in group {
                    if let pair = pair {
                        result.append(pair)
                    }
                }
                
                self.logger.debug("Successfully loaded \(result.count) friends with profiles")
                return result
            }
        } catch {
            self.logger.error("Error getting friends with profiles: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Get count of pending friend requests for a user
    func getPendingFriendRequestsCount(for userID: String) async throws -> Int {
        self.logger.debug("Getting pending friend request count for user \(userID)")
        
        // Try to fetch from local database first
        let descriptor = FetchDescriptor<FriendshipModel>(predicate: #Predicate { (friendship: FriendshipModel) -> Bool in 
            friendship.friendID == userID && friendship.relationshipType == "pending"
        })
        
        do {
            let pendingRequests = try modelContext.fetch(descriptor)
            
            if !pendingRequests.isEmpty {
                self.logger.debug("Found \(pendingRequests.count) pending friend requests in local database")
                return pendingRequests.count
            }
            
            // If none found locally, try fetching from Firebase using background thread
            return try await performFirebaseOperation {
                do {
                    let snapshot = try await self.db.collection(self.friendshipsCollection)
                        .whereField("friendID", isEqualTo: userID)
                        .whereField("relationshipType", isEqualTo: "pending")
                        .getDocuments()
                    
                    self.logger.debug("Found \(snapshot.documents.count) pending friend requests in Firebase")
                    
                    // Store documents for processing if needed
                    let documents = snapshot.documents
                    
                    // If we have pending requests, we should store them in the local database for future lookups
                    if !documents.isEmpty {
                        return await MainActor.run {
                            for document in documents {
                                let data = document.data()
                                let friendship = self.createFriendshipModelFromFirebaseData(id: document.documentID, data: data)
                                self.modelContext.insert(friendship)
                            }
                            try? self.modelContext.save()
                            return documents.count
                        }
                    }
                    
                    return documents.count
                } catch {
                    self.logger.error("Error getting pending friend requests count: \(error.localizedDescription)")
                    throw error
                }
            }
        } catch {
            self.logger.error("Error getting pending friend requests count: \(error.localizedDescription)")
            throw error
        }
    }
    
    func syncLocalWithRemote(for userID: String) async throws {
        self.logger.debug("Syncing local friendships with remote data for user \(userID)")
        
        do {
            // Fetch all remote friendships
            let snapshot = try await self.db.collection(self.friendshipsCollection)
                .whereField("userID", isEqualTo: userID)
                .getDocuments()
            
            var remoteFriendshipIDs: [String] = []
            
            // Process all remote friendships
            for document in snapshot.documents {
                let data = document.data()
                let idString = data["id"] as? String ?? document.documentID
                remoteFriendshipIDs.append(idString)
                
                // Check if friendship exists locally
                let descriptor = FetchDescriptor<FriendshipModel>(predicate: #Predicate { (friendship: FriendshipModel) -> Bool in 
                    friendship.id.uuidString == idString
                })
                
                let localFriendships = try modelContext.fetch(descriptor)
                
                if let localFriendship = localFriendships.first {
                    // Update local friendship if remote data is newer
                    if let remoteUpdated = data["updatedAt"] as? TimeInterval,
                       Date(timeIntervalSince1970: remoteUpdated) > localFriendship.updatedAt {
                        
                        let updatedFriendship = self.createFriendshipModelFromFirebaseData(id: idString, data: data)
                        localFriendship.relationshipType = updatedFriendship.relationshipType
                        localFriendship.lastHangoutDate = updatedFriendship.lastHangoutDate
                        localFriendship.nextScheduledHangout = updatedFriendship.nextScheduledHangout
                        localFriendship.customNotes = updatedFriendship.customNotes
                        localFriendship.isFavorite = updatedFriendship.isFavorite
                        localFriendship.lastContactedDate = updatedFriendship.lastContactedDate
                        localFriendship.updatedAt = updatedFriendship.updatedAt
                    }
                } else {
                    // Create new local friendship
                    let newFriendship = self.createFriendshipModelFromFirebaseData(id: idString, data: data)
                    self.modelContext.insert(newFriendship)
                }
            }
            
            // Check reverse relationships (where user is the friend)
            let reverseSnapshot = try await self.db.collection(self.friendshipsCollection)
                .whereField("friendID", isEqualTo: userID)
                .getDocuments()
                
            for document in reverseSnapshot.documents {
                let data = document.data()
                let idString = data["id"] as? String ?? document.documentID
                
                // Skip if already processed
                if remoteFriendshipIDs.contains(idString) {
                    continue
                }
                
                remoteFriendshipIDs.append(idString)
                
                // Check if friendship exists locally
                let descriptor = FetchDescriptor<FriendshipModel>(predicate: #Predicate { (friendship: FriendshipModel) -> Bool in 
                    friendship.id.uuidString == idString
                })
                
                let localFriendships = try modelContext.fetch(descriptor)
                
                if let localFriendship = localFriendships.first {
                    // Update local friendship if remote data is newer
                    if let remoteUpdated = data["updatedAt"] as? TimeInterval,
                       Date(timeIntervalSince1970: remoteUpdated) > localFriendship.updatedAt {
                        
                        let updatedFriendship = self.createFriendshipModelFromFirebaseData(id: idString, data: data)
                        localFriendship.relationshipType = updatedFriendship.relationshipType
                        localFriendship.lastHangoutDate = updatedFriendship.lastHangoutDate
                        localFriendship.nextScheduledHangout = updatedFriendship.nextScheduledHangout
                        localFriendship.customNotes = updatedFriendship.customNotes
                        localFriendship.isFavorite = updatedFriendship.isFavorite
                        localFriendship.lastContactedDate = updatedFriendship.lastContactedDate
                        localFriendship.updatedAt = updatedFriendship.updatedAt
                    }
                } else {
                    // Create new local friendship
                    let newFriendship = self.createFriendshipModelFromFirebaseData(id: idString, data: data)
                    self.modelContext.insert(newFriendship)
                }
            }
            
            // Identify and remove local friendships that no longer exist remotely
            let allFriendshipsDescriptor = FetchDescriptor<FriendshipModel>(predicate: #Predicate { (friendship: FriendshipModel) -> Bool in 
                friendship.userID == userID || friendship.friendID == userID
            })
            
            let allLocalFriendships = try modelContext.fetch(allFriendshipsDescriptor)
            
            for localFriendship in allLocalFriendships {
                if !remoteFriendshipIDs.contains(localFriendship.id.uuidString) {
                    self.modelContext.delete(localFriendship)
                }
            }
            
            // Save all changes
            try self.modelContext.save()
            
            logger.info("Successfully synced friendships for user \(userID)")
        } catch {
            self.logger.error("Error syncing friendships: \(error.localizedDescription)")
            throw error
        }
    }
}
