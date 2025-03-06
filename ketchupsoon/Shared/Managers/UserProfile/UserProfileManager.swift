import Foundation
import FirebaseAuth
import FirebaseFirestore
import OSLog

@MainActor
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "UserProfileManager")
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    
    @Published var currentUserProfile: UserProfile?
    @Published var isLoading = false
    @Published var error: Error?
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Set up Firebase Auth listener to keep profile in sync
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            if let user = user {
                Task {
                    await self.fetchUserProfile(userId: user.uid)
                }
            } else {
                // User signed out
                self.currentUserProfile = nil
            }
        }
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Profile Management
    
    /// Fetches a user profile from Firestore by user ID
    func fetchUserProfile(userId: String) async {
        guard Auth.auth().currentUser != nil else {
            self.error = NSError(domain: "UserProfileManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
            return
        }
        
        self.isLoading = true
        self.error = nil
        
        do {
            let document = try await db.collection(usersCollection).document(userId).getDocument()
            
            if document.exists, let data = document.data() {
                // Convert Firestore data to UserProfile
                if let profile = createUserProfile(from: data, with: userId) {
                    self.currentUserProfile = profile
                    self.logger.info("Successfully fetched user profile for \(userId)")
                }
            } else {
                // Profile doesn't exist, create one from Auth data
                if let user = Auth.auth().currentUser {
                    let newProfile = UserProfile(from: user)
                    try await createUserProfile(profile: newProfile)
                    self.currentUserProfile = newProfile
                    self.logger.info("Created new user profile for \(userId)")
                }
            }
        } catch {
            self.error = error
            self.logger.error("Error fetching user profile: \(error.localizedDescription)")
        }
        
        self.isLoading = false
    }
    
    /// Creates a new user profile in Firestore
    func createUserProfile(profile: UserProfile) async throws {
        guard Auth.auth().currentUser != nil else {
            throw NSError(domain: "UserProfileManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        let data = profile.toDictionary()
        
        try await db.collection(usersCollection).document(profile.id).setData(data)
        self.currentUserProfile = profile
        self.logger.info("Created user profile for \(profile.id)")
    }
    
    /// Updates an existing user profile in Firestore
    func updateUserProfile(updates: [String: Any]) async throws {
        guard let userId = Auth.auth().currentUser?.uid, 
              let currentProfile = currentUserProfile else {
            throw NSError(domain: "UserProfileManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user or profile"])
        }
        
        self.isLoading = true
        self.error = nil
        
        // Update the timestamp
        var updatesWithTimestamp = updates
        updatesWithTimestamp["updatedAt"] = Date().timeIntervalSince1970
        
        do {
            try await db.collection(usersCollection).document(userId).updateData(updatesWithTimestamp)
            
            // Update local profile copy
            var updatedProfile = currentProfile
            
            if let name = updates["name"] as? String {
                updatedProfile.name = name
            }
            
            if let email = updates["email"] as? String {
                updatedProfile.email = email
            }
            
            if let phoneNumber = updates["phoneNumber"] as? String {
                updatedProfile.phoneNumber = phoneNumber
            }
            
            if let bio = updates["bio"] as? String {
                updatedProfile.bio = bio
            }
            
            if let profileImageURL = updates["profileImageURL"] as? String {
                updatedProfile.profileImageURL = profileImageURL
            }
            
            // Handle birthday update
            if let birthdayTimestamp = updates["birthday"] as? TimeInterval {
                updatedProfile.birthday = Date(timeIntervalSince1970: birthdayTimestamp)
                logger.info("Updated local profile birthday: \(updatedProfile.birthday?.description ?? "nil")")
            }
            
            // Add handling for social profile fields
            if let isSocialProfileActive = updates["isSocialProfileActive"] as? Bool {
                updatedProfile.isSocialProfileActive = isSocialProfileActive
            }
            
            if let socialAuthProvider = updates["socialAuthProvider"] as? String {
                updatedProfile.socialAuthProvider = socialAuthProvider
            } else if updates["socialAuthProvider"] is NSNull {
                // Handle case when socialAuthProvider is set to null
                updatedProfile.socialAuthProvider = nil
            }
            
            updatedProfile.updatedAt = Date()
            self.currentUserProfile = updatedProfile
            
            self.logger.info("Updated user profile for \(userId)")
        } catch {
            self.error = error
            self.logger.error("Error updating user profile: \(error.localizedDescription)")
            throw error
        }
        
        self.isLoading = false
    }
    
    // MARK: - Helpers
    
    private func createUserProfile(from data: [String: Any], with userId: String) -> UserProfile? {
        let name = data["name"] as? String
        let email = data["email"] as? String
        let phoneNumber = data["phoneNumber"] as? String
        let bio = data["bio"] as? String
        let profileImageURL = data["profileImageURL"] as? String
        let isSocialProfileActive = data["isSocialProfileActive"] as? Bool ?? false
        let socialAuthProvider = data["socialAuthProvider"] as? String
        
        // Handle birthday
        var birthday: Date? = nil
        if let birthdayTimestamp = data["birthday"] as? TimeInterval {
            birthday = Date(timeIntervalSince1970: birthdayTimestamp)
            logger.info("Loaded birthday from Firestore: \(birthday?.description ?? "nil")")
        }
        
        // Handle timestamps
        var createdAt = Date()
        if let createdTimestamp = data["createdAt"] as? TimeInterval {
            createdAt = Date(timeIntervalSince1970: createdTimestamp)
        }
        
        var updatedAt = Date()
        if let updatedTimestamp = data["updatedAt"] as? TimeInterval {
            updatedAt = Date(timeIntervalSince1970: updatedTimestamp)
        }
        
        return UserProfile(
            id: userId,
            name: name,
            email: email,
            phoneNumber: phoneNumber,
            bio: bio,
            profileImageURL: profileImageURL,
            birthday: birthday,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isSocialProfileActive: isSocialProfileActive,
            socialAuthProvider: socialAuthProvider
        )
    }
    
    // MARK: - Sync with UserSettings
    
    /// Syncs the user profile with the local UserSettings
    func syncWithUserSettings() {
        let userSettings = UserSettings.shared
        
        // If we have a profile, update UserSettings
        if let profile = currentUserProfile {
            if let name = profile.name {
                userSettings.updateName(name)
            }
            
            if let email = profile.email {
                userSettings.updateEmail(email)
            }
            
            if let phoneNumber = profile.phoneNumber {
                userSettings.updatePhoneNumber(phoneNumber)
            }
        }
        
        // If UserSettings has data the profile doesn't, update the profile
        if currentUserProfile != nil {
            var updates: [String: Any] = [:]
            
            if let name = userSettings.name, currentUserProfile?.name == nil {
                updates["name"] = name
            }
            
            if let email = userSettings.email, currentUserProfile?.email == nil {
                updates["email"] = email
            }
            
            if let phoneNumber = userSettings.phoneNumber, currentUserProfile?.phoneNumber == nil {
                updates["phoneNumber"] = phoneNumber
            }
            
            if !updates.isEmpty {
                Task {
                    try? await updateUserProfile(updates: updates)
                }
            }
        }
    }
    
    // MARK: - Social Profile Features
    
    /// Checks if a user has an active social profile
    /// - Parameter userId: The user ID to check
    /// - Returns: Boolean indicating if the user has an active social profile
    func checkHasSocialProfile(userId: String) async -> Bool {
        do {
            let document = try await db.collection(usersCollection).document(userId).getDocument()
            if document.exists, let data = document.data() {
                return data["isSocialProfileActive"] as? Bool ?? false
            }
        } catch {
            self.logger.error("Error checking social profile status: \(error.localizedDescription)")
        }
        
        return false
    }
} 

