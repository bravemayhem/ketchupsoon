import Foundation
import FirebaseFirestore
import SwiftData
import OSLog
import FirebaseAuth

/// A service for searching for and managing Firebase user profiles
@MainActor
class FirebaseUserSearchService: ObservableObject {
    static let shared = FirebaseUserSearchService()
    
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "FirebaseUserSearchService")
    private lazy var db: Firestore = {
        return Firestore.firestore()
    }()
    private let usersCollection = "users"
    
    @Published var isSearching = false
    @Published var searchResults: [UserModel] = []
    @Published var error: Error?
    
    // MARK: - Search Methods
    
    /// Search for users by email or phone number
    /// - Parameter query: The email or phone number to search for
    /// - Returns: True if users were found, false otherwise
    func searchUsers(byEmailOrPhone query: String) async -> [UserModel] {
        guard !query.isEmpty else { return [] }
        
        await MainActor.run {
            isSearching = true
            error = nil
        }
        
        do {
            // Search by email first
            let emailResults = try await searchByField("email", value: query)
            
            // Search by phone number if no email results
            let phoneResults = emailResults.isEmpty ? 
                try await searchByField("phoneNumber", value: query) : []
            
            // Combine results (removing duplicates) without using Set
            var uniqueProfiles: [String: UserModel] = [:]
            for profile in emailResults + phoneResults {
                uniqueProfiles[profile.id] = profile
            }
            let allResults = Array(uniqueProfiles.values)
            
            await MainActor.run {
                isSearching = false
            }
            
            return allResults
        } catch {
            await MainActor.run {
                self.error = error
                isSearching = false
                logger.error("Error searching for users: \(error.localizedDescription)")
            }
            return []
        }
    }
    
    /// Creates a FriendshipModel from a UserModel, with Firebase relationship
    /// - Parameters:
    ///   - user: The Firebase user to create a friendship with
    ///   - modelContext: The SwiftData ModelContext to save to
    /// - Returns: The created FriendshipModel object
    func createFriendFromFirebaseUser(_ user: UserModel, in modelContext: ModelContext) -> FriendshipModel {
        // First get the current user ID - we need this to establish the relationship
        guard let currentUser = Auth.auth().currentUser else {
            logger.error("No current user logged in, cannot create friendship")
            fatalError("Cannot create friendship without current user")
        }
        
        let currentUserID = currentUser.uid
        
        // Check for existing friendship with this Firebase user
        // Store the user ID in a local variable for predicate use
        let friendUserID = user.id
        let friendshipDescriptor = FetchDescriptor<FriendshipModel>(
            predicate: #Predicate { (friendship: FriendshipModel) in 
                friendship.userID == currentUserID && friendship.friendID == friendUserID 
            }
        )
        
        do {
            let existingFriendships = try modelContext.fetch(friendshipDescriptor)
            if let existingFriendship = existingFriendships.first {
                logger.info("Found existing friendship with Firebase user \(user.id)")
                return existingFriendship
            }
        } catch {
            logger.error("Error fetching existing friendships: \(error.localizedDescription)")
        }
        
        // Create UserModel for the friend if it doesn't exist in local database
        let userID = user.id
        let userDescriptor = FetchDescriptor<UserModel>(
            predicate: #Predicate { (localUser: UserModel) in localUser.id == userID }
        )
        
        do {
            let users = try modelContext.fetch(userDescriptor)
            if users.isEmpty {
                // Insert the user into SwiftData
                modelContext.insert(user)
                logger.info("Created new user from Firebase profile: \(user.id)")
            }
        } catch {
            logger.error("Error checking for existing user: \(error.localizedDescription)")
        }
        
        // Create new FriendshipModel
        let friendship = FriendshipModel(
            userID: currentUserID,
            friendID: user.id
        )
        
        modelContext.insert(friendship)
        logger.info("Created new friendship with Firebase user: \(user.id)")
        
        return friendship
    }
    
    /// Checks for existing friendships that could be linked to Firebase users
    /// - Parameter modelContext: The SwiftData context containing friendships and users
    func checkExistingFriendsForFirebaseUsers(in modelContext: ModelContext) async {
        // First, get the current user - we need this to establish relationships
        guard let currentUser = Auth.auth().currentUser else {
            logger.error("No current user logged in, cannot check for Firebase users")
            return
        }
        
        let currentUserID = currentUser.uid
        logger.info("Checking for Firebase users for current user: \(currentUserID)")
        
        // Find all user entries in SwiftData that aren't the current user
        // and have email or phone but no corresponding friendship
        let localUserDescriptor = FetchDescriptor<UserModel>(
            predicate: #Predicate { (user: UserModel) in
                user.id != currentUserID && 
                (user.email != nil || user.phoneNumber != nil)
            }
        )
        
        guard let localUsers = try? modelContext.fetch(localUserDescriptor) else {
            logger.error("Failed to fetch local users from model context")
            return
        }
        
        // For each local user, check if we already have a friendship
        for localUser in localUsers {
            // Skip users without contact info
            guard localUser.email != nil || localUser.phoneNumber != nil else {
                continue
            }
            
            // Check if we already have a friendship with this user
            let userID = localUser.id
            let friendshipDescriptor = FetchDescriptor<FriendshipModel>(
                predicate: #Predicate { (friendship: FriendshipModel) in
                    friendship.userID == currentUserID && friendship.friendID == userID
                }
            )
            
            guard let existingFriendships = try? modelContext.fetch(friendshipDescriptor),
                  existingFriendships.isEmpty else {
                // We already have a friendship with this user, skip
                continue
            }
            
            // We don't have a friendship yet, check if this user exists in Firebase
            if let email = localUser.email, !email.isEmpty {
                if let firebaseUser = try? await findUserByEmail(email) {
                    // Create a friendship
                    createFriendship(
                        currentUserID: currentUserID,
                        friendID: firebaseUser.id, 
                        in: modelContext
                    )
                    logger.info("Created friendship with Firebase user \(firebaseUser.id) by email")
                    continue
                }
            }
            
            // Try by phone if email didn't match
            if let phone = localUser.phoneNumber, !phone.isEmpty {
                if let firebaseUser = try? await findUserByPhone(phone) {
                    // Create a friendship
                    createFriendship(
                        currentUserID: currentUserID,
                        friendID: firebaseUser.id, 
                        in: modelContext
                    )
                    logger.info("Created friendship with Firebase user \(firebaseUser.id) by phone")
                }
            }
        }
        
        // Also check for incomplete friendships (ones with empty friendID)
        let incompleteFriendshipDescriptor = FetchDescriptor<FriendshipModel>(
            predicate: #Predicate { (friendship: FriendshipModel) in
                friendship.userID == currentUserID && friendship.friendID == ""
            }
        )
        
        guard let incompleteFriendships = try? modelContext.fetch(incompleteFriendshipDescriptor) else {
            logger.error("Failed to fetch incomplete friendships from model context")
            return
        }
        
        logger.info("Found \(incompleteFriendships.count) incomplete friendships to resolve")
        
        // For each incomplete friendship, we need the friend's details to search Firebase
        // This assumes there's some other identifier stored that we can use to find the user
        // Since FriendshipModel doesn't contain this info directly, we'd need to adapt this part
        // based on how your app actually tracks unresolved friendships
    }
    
    /// Creates a friendship between the current user and a friend
    /// - Parameters:
    ///   - currentUserID: The ID of the current user
    ///   - friendID: The ID of the friend (Firebase user ID)
    ///   - modelContext: The SwiftData context to save to
    private func createFriendship(currentUserID: String, friendID: String, in modelContext: ModelContext) {
        let friendship = FriendshipModel(
            userID: currentUserID,
            friendID: friendID
        )
        
        modelContext.insert(friendship)
        logger.info("Created friendship between \(currentUserID) and \(friendID)")
    }
    
    // MARK: - Helper Methods
    
    private func searchByField(_ field: String, value: String) async throws -> [UserModel] {
        let query = db.collection(usersCollection).whereField(field, isEqualTo: value)
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { document -> UserModel? in
            // Use explicit type annotation to ensure it's treated as optional
            let documentData: [String: Any]? = document.data()
            if documentData == nil {
                return nil
            }
            
            // Access the data safely since we've checked it's not nil
            let data = documentData!
            
            // Use document ID if id field is missing
            let userId = (data["id"] as? String) ?? document.documentID
            
            // Create UserModel directly from the Firebase data
            return createUserModelFromFirebaseData(id: userId, data: data)
        }
    }
    
    private func findUserByEmail(_ email: String) async throws -> UserModel? {
        let query = db.collection(usersCollection).whereField("email", isEqualTo: email)
        let snapshot = try await query.getDocuments()
        
        guard let document = snapshot.documents.first else { return nil }
        
        // Use explicit type annotation to ensure it's treated as optional
        let documentData: [String: Any]? = document.data()
        if documentData == nil {
            return nil
        }
        
        // Access the data safely since we've checked it's not nil
        let data = documentData!
        
        // Use document ID if id field is missing
        let userId = (data["id"] as? String) ?? document.documentID
        
        return createUserModelFromFirebaseData(id: userId, data: data)
    }
    
    private func findUserByPhone(_ phone: String) async throws -> UserModel? {
        let query = db.collection(usersCollection).whereField("phoneNumber", isEqualTo: phone)
        let snapshot = try await query.getDocuments()
        
        guard let document = snapshot.documents.first else { return nil }
        
        // Use explicit type annotation to ensure it's treated as optional
        let documentData: [String: Any]? = document.data()
        if documentData == nil {
            return nil
        }
        
        // Access the data safely since we've checked it's not nil
        let data = documentData!
        
        // Use document ID if id field is missing
        let userId = (data["id"] as? String) ?? document.documentID
        
        return createUserModelFromFirebaseData(id: userId, data: data)
    }
    
    // Create a UserModel directly from Firebase data
    private func createUserModelFromFirebaseData(id: String, data: [String: Any]) -> UserModel {
        let user = UserModel(
            id: id,
            name: data["name"] as? String,
            profileImageURL: data["profileImageURL"] as? String,
            email: data["email"] as? String,
            phoneNumber: data["phoneNumber"] as? String,
            bio: data["bio"] as? String
        )
        
        // Handle timestamps
        if let createdTimestamp = data["createdAt"] as? TimeInterval {
            user.createdAt = Date(timeIntervalSince1970: createdTimestamp)
        }
        
        if let updatedTimestamp = data["updatedAt"] as? TimeInterval {
            user.updatedAt = Date(timeIntervalSince1970: updatedTimestamp)
        }
        
        // Handle additional fields that may be in the data
        if let birthdayTimestamp = data["birthday"] as? TimeInterval {
            user.birthday = Date(timeIntervalSince1970: birthdayTimestamp)
        }
                
        user.gradientIndex = data["gradientIndex"] as? Int ?? 0
        
        // Set preference fields if they exist
        user.availabilityTimes = data["availabilityTimes"] as? [String]
        user.availableDays = data["availableDays"] as? [String]
        user.favoriteActivities = data["favoriteActivities"] as? [String]
        user.calendarConnections = data["calendarConnections"] as? [String]
        user.travelRadius = data["travelRadius"] as? String
        
        return user
    }
} 
