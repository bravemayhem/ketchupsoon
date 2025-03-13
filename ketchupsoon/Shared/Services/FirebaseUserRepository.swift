import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import OSLog

/// Firebase implementation of the UserRepository protocol
/// Handles user data operations with Firebase and syncs with SwiftData
class FirebaseUserRepository: UserRepository {
    // MARK: - Properties
    
    private lazy var db: Firestore = {
        return Firestore.firestore()
    }()
    private lazy var storage: Storage = {
        return Storage.storage()
    }()
    private let usersCollection = "users"
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "FirebaseUserRepository")
    private let modelContext: ModelContext
    
    // Operation coordinator
    private let operationCoordinator: FirebaseOperationCoordinator
    
    // Last refresh time tracking
    private var lastRefreshTime: Date?
    
    // MARK: - Initialization
    
    @MainActor
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.operationCoordinator = FirebaseOperationCoordinator.shared
    }
    
    // MARK: - User Fetching Methods

    func getUser(id: String) async throws -> UserModel {
        let userId = id
        // First check if user exists in SwiftData
        let descriptor = FetchDescriptor<UserModel>(predicate: #Predicate { (user: UserModel) -> Bool in user.id == userId })
        
        do {
            let localUsers = try modelContext.fetch(descriptor)
            if let existingUser = localUsers.first {
                logger.debug("Found user \(id) in local database")
                return existingUser
            }
        } catch {
            logger.error("Error fetching user from SwiftData: \(error.localizedDescription)")
            // Continue to fetch from Firebase rather than throwing
        }
        
        // Not found locally, fetch from Firebase
        logger.debug("Fetching user \(id) from Firebase")
        
        do {
            let documentSnapshot = try await db.collection(usersCollection).document(id).getDocument()
            
            guard documentSnapshot.exists else {
                throw NSError(domain: "com.ketchupsoon", code: 404, 
                             userInfo: [NSLocalizedDescriptionKey: "User not found"])
            }
            
            guard let data = documentSnapshot.data() else {
                throw NSError(domain: "com.ketchupsoon", code: 500, 
                             userInfo: [NSLocalizedDescriptionKey: "Invalid user data"])
            }
            
            // Create a new user and save it to SwiftData
            let user = createUserModelFromFirebaseData(id: id, data: data)
            
            // Save to local database
            modelContext.insert(user)
            try modelContext.save()
            
            return user
        } catch {
            logger.error("Error fetching user from Firebase: \(error.localizedDescription)")
            throw error
        }
    }

    @MainActor
    func getCurrentUser() async throws -> UserModel? {
        // Check if there's a logged in user
        guard let currentUser = Auth.auth().currentUser else {
            logger.info("No user currently logged in")
            return nil
        }
        
        // Try to get user from local database first
        do {
            let userID = currentUser.uid // Store the ID in a local variable
            
            // Create a simpler fetch descriptor to avoid EXC_BAD_ACCESS
            var descriptor = FetchDescriptor<UserModel>()
            descriptor.predicate = #Predicate<UserModel> { user in
                user.id == userID
            }
            descriptor.fetchLimit = 1
            
            // Execute fetch on the main actor to prevent thread safety issues
            let localUsers = try await MainActor.run {
                try modelContext.fetch(descriptor)
            }
            
            if let existingUser = localUsers.first {
                logger.debug("Found current user in local database")
                return existingUser
            }
        } catch {
            logger.error("Error fetching current user from SwiftData: \(error.localizedDescription)")
            // Continue to fetch from Firebase
        }
        
        // Not found locally, get from Firebase
        logger.debug("Fetching current user from Firebase")
        
        do {
            // First try to get additional data from Firestore
            let documentSnapshot = try await db.collection(usersCollection).document(currentUser.uid).getDocument()
            
            if documentSnapshot.exists, let data = documentSnapshot.data() {
                // We have additional data in Firestore
                let user = UserModel.from(firebaseUser: currentUser, additionalData: data)
                
                // Save to local database
                modelContext.insert(user)
                try modelContext.save()
                
                return user
            } else {
                // No additional data in Firestore, just use Auth data
                let user = UserModel.from(firebaseUser: currentUser)
                
                // Save to local database
                modelContext.insert(user)
                try modelContext.save()
                
                return user
            }
        } catch {
            logger.error("Error fetching current user from Firebase: \(error.localizedDescription)")
            throw error
        }
    }

    func searchUsers(query: String) async throws -> [UserModel] {
        guard !query.isEmpty else {
            return []
        }
        
        // For simplicity, we'll just search by name
        // In a real app, you might want to use Firebase's search capabilities or Algolia
        logger.debug("Searching for users with query: \(query)")
        
        do {
            // Convert query to lowercase for case-insensitive search
            let lowerQuery = query.lowercased()
            
            // Get all users where name contains the query
            let snapshot = try await db.collection(usersCollection)
                .whereField("name", isGreaterThanOrEqualTo: lowerQuery)
                .whereField("name", isLessThanOrEqualTo: lowerQuery + "\u{f8ff}")
                .limit(to: 20)
                .getDocuments()
            
            var users: [UserModel] = []
            
            for document in snapshot.documents {
                let data = document.data()
                let user = createUserModelFromFirebaseData(id: document.documentID, data: data)
                users.append(user)
            }
            
            return users
        } catch {
            logger.error("Error searching for users: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - User Management Methods

    func createUser(user: UserModel) async throws {
        logger.debug("Creating user \(user.id) in Firebase")
        
        do {
            // Convert to Firebase data
            let userData = user.toFirebaseDictionary()
            
            // Save to Firestore
            try await db.collection(usersCollection).document(user.id).setData(userData)
            
            // Save to local database if not already there
            let userId = user.id
            let descriptor = FetchDescriptor<UserModel>(predicate: #Predicate { (u: UserModel) -> Bool in
                u.id == userId
            })
            let existingUsers = try modelContext.fetch(descriptor)
            
            if existingUsers.isEmpty {
                modelContext.insert(user)
                try modelContext.save()
            }
            
            logger.info("Successfully created user \(user.id)")
        } catch {
            logger.error("Error creating user in Firebase: \(error.localizedDescription)")
            throw error
        }
    }

    func updateUser(user: UserModel) async throws {
        logger.debug("Updating user \(user.id) in Firebase")
        
        do {
            // First, check if the user exists in Firestore
            let document = try await db.collection(usersCollection).document(user.id).getDocument()
            
            guard document.exists else {
                throw NSError(domain: "com.ketchupsoon", code: 404, 
                             userInfo: [NSLocalizedDescriptionKey: "User not found in Firestore"])
            }
            
            // Update updatedAt timestamp
            user.updatedAt = Date()
            
            // Convert to Firebase data
            let userData = user.toFirebaseDictionary()
            
            // Update in Firestore
            try await db.collection(usersCollection).document(user.id).updateData(userData)
            
            // Update in local database - SwiftData should automatically track changes
            try modelContext.save()
            
            logger.info("Successfully updated user \(user.id)")
        } catch {
            logger.error("Error updating user in Firebase: \(error.localizedDescription)")
            throw error
        }
    }

    func deleteUser(id: String) async throws {
        logger.debug("Deleting user \(id)")
        
        do {
            // First check if user exists in Firestore
            let document = try await db.collection(usersCollection).document(id).getDocument()
            
            guard document.exists else {
                throw NSError(domain: "com.ketchupsoon", code: 404, 
                             userInfo: [NSLocalizedDescriptionKey: "User not found in Firestore"])
            }
            
            // Delete from Firestore
            try await db.collection(usersCollection).document(id).delete()
            
            // Delete from local database
            let userId = id
            let descriptor = FetchDescriptor<UserModel>(predicate: #Predicate { (user: UserModel) -> Bool in
                user.id == userId
            })
            let localUsers = try modelContext.fetch(descriptor)
            
            if let user = localUsers.first {
                modelContext.delete(user)
                try modelContext.save()
            }
            
            logger.info("Successfully deleted user \(id)")
        } catch {
            logger.error("Error deleting user: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Special Operations

    func linkUserWithFirebase(email: String, phoneNumber: String) async throws -> UserModel? {
        logger.debug("Searching for Firebase user with email: \(email) or phone: \(phoneNumber)")
        
        do {
            // First try to find by email
            if !email.isEmpty {
                let emailQuery = try await db.collection(usersCollection)
                    .whereField("email", isEqualTo: email)
                    .limit(to: 1)
                    .getDocuments()
                
                if let document = emailQuery.documents.first, document.exists {
                    let data = document.data()
                    let user = createUserModelFromFirebaseData(id: document.documentID, data: data)
                    
                    // Save to local database
                    modelContext.insert(user)
                    try modelContext.save()
                    
                    logger.info("Found and linked user by email: \(email)")
                    return user
                }
            }
            
            // Then try to find by phone
            if !phoneNumber.isEmpty {
                let phoneQuery = try await db.collection(usersCollection)
                    .whereField("phoneNumber", isEqualTo: phoneNumber)
                    .limit(to: 1)
                    .getDocuments()
                
                if let document = phoneQuery.documents.first, document.exists {
                    let data = document.data()
                    let user = createUserModelFromFirebaseData(id: document.documentID, data: data)
                    
                    // Save to local database
                    modelContext.insert(user)
                    try modelContext.save()
                    
                    logger.info("Found and linked user by phone: \(phoneNumber)")
                    return user
                }
            }
            
            // No user found
            logger.info("No user found with email: \(email) or phone: \(phoneNumber)")
            return nil
        } catch {
            logger.error("Error linking user with Firebase: \(error.localizedDescription)")
            throw error
        }
    }

    func refreshCurrentUser() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            logger.warning("Cannot refresh - no current user")
            throw NSError(domain: "com.ketchupsoon", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        // Use a unique key for this user's refresh operation
        let operationKey = "refresh_user_\(currentUser.uid)"
        
        return try await withCheckedThrowingContinuation { continuation in
            // Schedule the operation through the coordinator
            Task { @MainActor [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "com.ketchupsoon", code: 500, 
                                                  userInfo: [NSLocalizedDescriptionKey: "Repository was deallocated"]))
                    return
                }
                
                self.operationCoordinator.scheduleOperation(
                    name: "Refresh Current User",
                    key: operationKey,
                    priority: .normal,
                    minInterval: 3.0, // 3 seconds minimum between refreshes for the same user
                    operation: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    do {
                        // Get fresh data from Firestore
                        let document = try await db.collection(usersCollection).document(currentUser.uid).getDocument()
                        
                        if document.exists, let data = document.data() {
                            // Update user in SwiftData
                            let userId = currentUser.uid
                            let descriptor = FetchDescriptor<UserModel>(predicate: #Predicate { (user: UserModel) -> Bool in
                                user.id == userId
                            })
                            let localUsers = try modelContext.fetch(descriptor)
                            
                            if let existingUser = localUsers.first {
                                // Update existing user
                                updateUserModelFromFirebaseData(user: existingUser, data: data)
                            } else {
                                // Create new user if not found locally
                                let user = UserModel.from(firebaseUser: currentUser, additionalData: data)
                                modelContext.insert(user)
                            }
                            
                            try modelContext.save()
                            lastRefreshTime = Date()
                            continuation.resume(returning: ())
                        } else {
                            let error = NSError(domain: "com.ketchupsoon", code: 404, 
                                       userInfo: [NSLocalizedDescriptionKey: "Current user not found in Firestore"])
                            continuation.resume(throwing: error)
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                },
                errorHandler: { error in
                    continuation.resume(throwing: error)
                }
                )
            }
        }
    }

    func syncLocalWithRemote() async throws {
        logger.debug("Syncing local users with remote")
        
        guard Auth.auth().currentUser != nil else {
            logger.warning("Cannot sync - no current user")
            throw NSError(domain: "com.ketchupsoon", code: 401, 
                         userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }
        
        // First, make sure the current user is synced
        try await refreshCurrentUser()
        
        // Then, sync all friend relationships
        // You could add friendship sync code here using your FriendshipModel
        
        logger.info("Local-remote sync completed")
    }

    // MARK: - Helper Methods
    
    // Helper method to create a UserModel from Firebase data
    private func createUserModelFromFirebaseData(id: String, data: [String: Any]) -> UserModel {
        let user = UserModel()
        user.id = id
        
        // Update all properties
        updateUserModelFromFirebaseData(user: user, data: data)
        
        return user
    }
    
    // Helper method to update a user model from Firebase data
    private func updateUserModelFromFirebaseData(user: UserModel, data: [String: Any]) {
        // Basic info
        user.name = data["name"] as? String
        user.email = data["email"] as? String
        user.phoneNumber = data["phoneNumber"] as? String
        user.bio = data["bio"] as? String
        user.profileImageURL = data["profileImageURL"] as? String
        
        // Personal info
        if let birthdayTimestamp = data["birthday"] as? TimeInterval {
            user.birthday = Date(timeIntervalSince1970: birthdayTimestamp)
        }
        
        // Dates
        if let createdTimestamp = data["createdAt"] as? TimeInterval {
            user.createdAt = Date(timeIntervalSince1970: createdTimestamp)
        }
        
        if let updatedTimestamp = data["updatedAt"] as? TimeInterval {
            user.updatedAt = Date(timeIntervalSince1970: updatedTimestamp)
        } else {
            user.updatedAt = Date() // Set to now if no timestamp
        }
        
        // Social profile fields
        user.isSocialProfileActive = data["isSocialProfileActive"] as? Bool ?? false
        user.socialAuthProvider = data["socialAuthProvider"] as? String
        user.gradientIndex = data["gradientIndex"] as? Int ?? 0
        
        // Preferences
        user.availabilityTimes = data["availabilityTimes"] as? [String]
        user.availableDays = data["availableDays"] as? [String]
        user.favoriteActivities = data["favoriteActivities"] as? [String]
        user.calendarConnections = data["calendarConnections"] as? [String]
        user.travelRadius = data["travelRadius"] as? String
    }
} 