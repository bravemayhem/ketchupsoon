import Foundation
import FirebaseFirestore
import SwiftData
import OSLog

/// A service for searching for and managing Firebase user profiles
@MainActor
class FirebaseUserSearchService: ObservableObject {
    static let shared = FirebaseUserSearchService()
    
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "FirebaseUserSearchService")
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    
    @Published var isSearching = false
    @Published var searchResults: [UserProfileModel] = []
    @Published var error: Error?
    
    // MARK: - Search Methods
    
    /// Search for users by email or phone number
    /// - Parameter query: The email or phone number to search for
    /// - Returns: True if users were found, false otherwise
    func searchUsers(byEmailOrPhone query: String) async -> Bool {
        guard !query.isEmpty else { return false }
        
        await MainActor.run {
            isSearching = true
            searchResults = []
            error = nil
        }
        
        do {
            // Search by email first
            let emailResults = try await searchByField("email", value: query)
            
            // Search by phone number if no email results
            let phoneResults = emailResults.isEmpty ? 
                try await searchByField("phoneNumber", value: query) : []
            
            // Combine results (removing duplicates) without using Set
            var uniqueProfiles: [String: UserProfileModel] = [:]
            for profile in emailResults + phoneResults {
                uniqueProfiles[profile.id] = profile
            }
            let allResults = Array(uniqueProfiles.values)
            
            await MainActor.run {
                searchResults = allResults
                isSearching = false
            }
            
            return !allResults.isEmpty
        } catch {
            await MainActor.run {
                self.error = error
                isSearching = false
                logger.error("Error searching for users: \(error.localizedDescription)")
            }
            return false
        }
    }
    
    /// Creates a Friend object from a UserProfile, with firebaseUserId linked
    /// - Parameters:
    ///   - profile: The Firebase UserProfile to convert
    ///   - modelContext: The SwiftData ModelContext to save to
    /// - Returns: The created Friend object
    func createFriendFromFirebaseUser(_ profile: UserProfileModel, in modelContext: ModelContext) -> FriendModel {
        // Check for existing friend with this Firebase ID
        // First fetch all friends with non-nil firebaseUserId
        let nonNilDescriptor = FetchDescriptor<FriendModel>(
            predicate: #Predicate<FriendModel> { $0.firebaseUserId != nil }
        )
        
        do {
            // Then manually filter for the matching ID
            let potentialFriends = try modelContext.fetch(nonNilDescriptor)
            if let existingFriend = potentialFriends.first(where: { $0.firebaseUserId == profile.id }) {
                logger.info("Found existing friend with Firebase ID \(profile.id)")
                return existingFriend
            }
        } catch {
            logger.error("Error fetching existing friends: \(error.localizedDescription)")
        }
        
        // Create new Friend using the convenience initializer
        let friend = FriendModel(from: profile)
        
        // Handle profile image if available
        if let profileImageURLString = profile.profileImageURL, 
           let url = URL(string: profileImageURLString) {
            // This is just a placeholder - you'd implement image loading separately
            // using URLSession or a library like Kingfisher
            logger.info("Profile image available at: \(url)")
        }
        
        modelContext.insert(friend)
        logger.info("Created new friend from Firebase user: \(profile.id)")
        
        return friend
    }
    
    /// Checks if any of the user's existing friends could be linked to Firebase users
    /// - Parameter modelContext: The SwiftData context containing friends
    func checkExistingFriendsForFirebaseUsers(in modelContext: ModelContext) async {
        // Get all friends without Firebase IDs
        let descriptor = FetchDescriptor<FriendModel>(
            predicate: #Predicate<FriendModel> {
                $0.firebaseUserId == nil
            }
        )
        
        guard let friends = try? modelContext.fetch(descriptor) else {
            logger.error("Failed to fetch friends from model context")
            return
        }
        
        // Filter friends with email or phone in-memory instead of in the predicate
        let friendsToCheck = friends.filter { 
            ($0.email != nil && !($0.email?.isEmpty ?? true)) || 
            ($0.phoneNumber != nil && !($0.phoneNumber?.isEmpty ?? true)) 
        }
        
        logger.info("Checking \(friendsToCheck.count) existing friends for Firebase user profiles")
        
        for friend in friendsToCheck {
            // Check by email
            if let email = friend.email, !email.isEmpty {
                if let profile = try? await findUserByEmail(email) {
                    friend.firebaseUserId = profile.id
                    logger.info("Linked friend \(friend.name) with Firebase user \(profile.id) by email")
                    continue
                }
            }
            
            // Check by phone if email didn't match
            if let phone = friend.phoneNumber, !phone.isEmpty {
                if let profile = try? await findUserByPhone(phone) {
                    friend.firebaseUserId = profile.id
                    logger.info("Linked friend \(friend.name) with Firebase user \(profile.id) by phone")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func searchByField(_ field: String, value: String) async throws -> [UserProfileModel] {
        let query = db.collection(usersCollection).whereField(field, isEqualTo: value)
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { document -> UserProfileModel? in
            // Use explicit type annotation to ensure it's treated as optional
            let documentData: [String: Any]? = document.data()
            if documentData == nil {
                return nil
            }
            
            // Access the data safely since we've checked it's not nil
            let data = documentData!
            guard let userId = data["id"] as? String else {
                return nil
            }
            
            return createUserProfile(from: data, with: userId)
        }
    }
    
    private func findUserByEmail(_ email: String) async throws -> UserProfileModel? {
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
        guard let userId = data["id"] as? String else {
            return nil
        }
        
        return createUserProfile(from: data, with: userId)
    }
    
    private func findUserByPhone(_ phone: String) async throws -> UserProfileModel? {
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
        guard let userId = data["id"] as? String else {
            return nil
        }
        
        return createUserProfile(from: data, with: userId)
    }
    
    private func createUserProfile(from data: [String: Any], with userId: String) -> UserProfileModel? {
        let name = data["name"] as? String
        let email = data["email"] as? String
        let phoneNumber = data["phoneNumber"] as? String
        let bio = data["bio"] as? String
        let profileImageURL = data["profileImageURL"] as? String
        
        // Handle timestamps
        var createdAt = Date()
        if let createdTimestamp = data["createdAt"] as? TimeInterval {
            createdAt = Date(timeIntervalSince1970: createdTimestamp)
        }
        
        var updatedAt = Date()
        if let updatedTimestamp = data["updatedAt"] as? TimeInterval {
            updatedAt = Date(timeIntervalSince1970: updatedTimestamp)
        }
        
        return UserProfileModel(
            id: userId,
            name: name,
            email: email,
            phoneNumber: phoneNumber,
            bio: bio,
            profileImageURL: profileImageURL,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
} 
