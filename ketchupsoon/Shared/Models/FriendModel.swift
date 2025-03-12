import Foundation
import SwiftData

@Model
final class FriendModel {
    // Basic properties
    var id: UUID
    var name: String
    var profileImageURL: String?
    
    // Contact information
    var email: String?
    var phoneNumber: String?
    
    // Personal information
    var bio: String?
    var birthday: Date?
    
    // App integration
    var firebaseUserId: String?
    
    // Relationship tracking
    var createdAt: Date
    var updatedAt: Date
    
    // Add more properties as needed for your new implementation
    
    init(
        id: UUID = UUID(),
        name: String,
        profileImageURL: String? = nil,
        email: String? = nil,
        phoneNumber: String? = nil,
        bio: String? = nil,
        birthday: Date? = nil,        
        firebaseUserId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.profileImageURL = profileImageURL
        self.email = email
        self.phoneNumber = phoneNumber
        self.bio = bio
        self.birthday = birthday
        self.firebaseUserId = firebaseUserId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Convenience initializer from UserProfile
    convenience init(from userProfile: UserProfileModel) {
        self.init(
            name: userProfile.name ?? "Unknown",
            profileImageURL: userProfile.profileImageURL,
            email: userProfile.email,
            phoneNumber: userProfile.phoneNumber,
            bio: userProfile.bio,
            birthday: userProfile.birthday,
            firebaseUserId: userProfile.id,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
} 
