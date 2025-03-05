import Foundation
import FirebaseAuth

struct UserProfile: Codable {
    var id: String  // Firebase Auth UID
    var name: String?
    var email: String?
    var phoneNumber: String?
    var bio: String?
    var profileImageURL: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Initialize from Firebase User
    init(from user: User, additionalData: [String: Any] = [:]) {
        self.id = user.uid
        self.name = user.displayName
        self.email = user.email
        self.phoneNumber = user.phoneNumber
        self.bio = additionalData["bio"] as? String
        self.profileImageURL = user.photoURL?.absoluteString
        
        if let createdTimestamp = additionalData["createdAt"] as? TimeInterval {
            self.createdAt = Date(timeIntervalSince1970: createdTimestamp)
        } else {
            self.createdAt = Date()
        }
        
        if let updatedTimestamp = additionalData["updatedAt"] as? TimeInterval {
            self.updatedAt = Date(timeIntervalSince1970: updatedTimestamp)
        } else {
            self.updatedAt = Date()
        }
    }
    
    // Initialize with custom data
    init(id: String, 
         name: String? = nil, 
         email: String? = nil, 
         phoneNumber: String? = nil, 
         bio: String? = nil, 
         profileImageURL: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "createdAt": createdAt.timeIntervalSince1970,
            "updatedAt": updatedAt.timeIntervalSince1970
        ]
        
        if let name = name { dict["name"] = name }
        if let email = email { dict["email"] = email }
        if let phoneNumber = phoneNumber { dict["phoneNumber"] = phoneNumber }
        if let bio = bio { dict["bio"] = bio }
        if let profileImageURL = profileImageURL { dict["profileImageURL"] = profileImageURL }
        
        return dict
    }
} 