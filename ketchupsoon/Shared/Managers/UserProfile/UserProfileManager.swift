/*
 Long-Term Strategy
 In the future, you might consider a more significant architectural refactoring to merge UserProfileManager functionality into FirebaseUserRepository, but this would be best approached as a separate task after you've fully transitioned to using UserModel throughout your app
 */

import Foundation
import FirebaseAuth
import FirebaseFirestore
import OSLog
import SwiftData

@MainActor
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "UserProfileManager")
    private lazy var db: Firestore = {
        return Firestore.firestore()
    }()
    private let usersCollection = "users"
    
    @Published var currentUserProfile: UserModel?
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
                // Convert Firestore data to UserModel
                if let profile = createUserModel(from: data, with: userId) {
                    self.currentUserProfile = profile
                    self.logger.info("Successfully fetched user profile for \(userId)")
                }
            } else {
                // Profile doesn't exist, create one from Auth data
                if let user = Auth.auth().currentUser {
                    let newProfile = UserModel.from(firebaseUser: user)
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
    func createUserProfile(profile: UserModel) async throws {
        guard Auth.auth().currentUser != nil else {
            throw NSError(domain: "UserProfileManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        let data = profile.toFirebaseDictionary()
        
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
            // Since UserModel is a class, we can directly update its properties
            
            if let name = updates["name"] as? String {
                currentProfile.name = name
            }
            
            if let email = updates["email"] as? String {
                currentProfile.email = email
            }
            
            if let phoneNumber = updates["phoneNumber"] as? String {
                currentProfile.phoneNumber = phoneNumber
            }
            
            if let bio = updates["bio"] as? String {
                currentProfile.bio = bio
            }
            
            if let profileImageURL = updates["profileImageURL"] as? String {
                currentProfile.profileImageURL = profileImageURL
            }
            
            // Handle birthday update
            if let birthdayTimestamp = updates["birthday"] as? TimeInterval {
                currentProfile.birthday = Date(timeIntervalSince1970: birthdayTimestamp)
                logger.info("Updated local profile birthday: \(currentProfile.birthday?.description ?? "nil")")
            }
            
            // Handle user preference updates
            if let availabilityTimes = updates["availabilityTimes"] as? [String] {
                currentProfile.availabilityTimes = availabilityTimes
            }
            
            if let availableDays = updates["availableDays"] as? [String] {
                currentProfile.availableDays = availableDays
            }
            
            if let favoriteActivities = updates["favoriteActivities"] as? [String] {
                currentProfile.favoriteActivities = favoriteActivities
            }
            
            if let calendarConnections = updates["calendarConnections"] as? [String] {
                currentProfile.calendarConnections = calendarConnections
            }
            
            if let travelRadius = updates["travelRadius"] as? String {
                currentProfile.travelRadius = travelRadius
            }
            
            currentProfile.updatedAt = Date()
            // We don't need to reassign currentUserProfile since we're updating the existing object
            
            self.logger.info("Updated user profile for \(userId)")
        } catch {
            self.error = error
            self.logger.error("Error updating user profile: \(error.localizedDescription)")
            throw error
        }
        
        self.isLoading = false
    }
    
    // MARK: - Helpers
    
    private func createUserModel(from data: [String: Any], with userId: String) -> UserModel? {
        let user = UserModel(id: userId)
        
        user.name = data["name"] as? String
        user.email = data["email"] as? String
        user.phoneNumber = data["phoneNumber"] as? String
        user.bio = data["bio"] as? String
        user.profileImageURL = data["profileImageURL"] as? String        
        user.gradientIndex = data["gradientIndex"] as? Int ?? 0
        
        // User preferences
        user.availabilityTimes = data["availabilityTimes"] as? [String]
        user.availableDays = data["availableDays"] as? [String]
        user.favoriteActivities = data["favoriteActivities"] as? [String]
        user.calendarConnections = data["calendarConnections"] as? [String]
        user.travelRadius = data["travelRadius"] as? String
        
        // Handle birthday
        if let birthdayTimestamp = data["birthday"] as? TimeInterval {
            user.birthday = Date(timeIntervalSince1970: birthdayTimestamp)
            logger.info("Loaded birthday from Firestore: \(user.birthday?.description ?? "nil")")
        }
        
        // Handle timestamps
        if let createdTimestamp = data["createdAt"] as? TimeInterval {
            user.createdAt = Date(timeIntervalSince1970: createdTimestamp)
        }
        
        if let updatedTimestamp = data["updatedAt"] as? TimeInterval {
            user.updatedAt = Date(timeIntervalSince1970: updatedTimestamp)
        }
        
        return user
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
}
