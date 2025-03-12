import Foundation
import FirebaseAuth

struct UserProfileModel: Codable {
    var id: String  // Firebase Auth UID
    var name: String?
    var email: String?
    var phoneNumber: String?
    var bio: String?
    var profileImageURL: String?
    var birthday: Date?
    var createdAt: Date
    var updatedAt: Date
    
    // Social profile fields
    var isSocialProfileActive: Bool
    var socialAuthProvider: String?  // Added to track which auth provider is used
    
    // User preferences fields
    var availabilityTimes: [String]?  // e.g. ["mornings", "evenings", "weekends"]
    var availableDays: [String]?      // e.g. ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    var favoriteActivities: [String]? // e.g. ["coffee", "food", "outdoors", "games"]
    var calendarConnections: [String]? // e.g. ["Google"]
    var travelRadius: String?         // e.g. "5 miles"
    
    // Initialize from Firebase User
    init(from user: User, additionalData: [String: Any] = [:]) {
        self.id = user.uid
        self.name = user.displayName
        self.email = user.email
        self.phoneNumber = user.phoneNumber
        self.bio = additionalData["bio"] as? String
        self.profileImageURL = user.photoURL?.absoluteString
        
        // Personal info
        if let birthdayTimestamp = additionalData["birthday"] as? TimeInterval {
            self.birthday = Date(timeIntervalSince1970: birthdayTimestamp)
        }
        
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
        
        // Initialize social profile fields
        self.isSocialProfileActive = additionalData["isSocialProfileActive"] as? Bool ?? false
        self.socialAuthProvider = additionalData["socialAuthProvider"] as? String
        
        // Initialize preference fields
        self.availabilityTimes = additionalData["availabilityTimes"] as? [String]
        self.availableDays = additionalData["availableDays"] as? [String]
        self.favoriteActivities = additionalData["favoriteActivities"] as? [String]
        self.calendarConnections = additionalData["calendarConnections"] as? [String]
        self.travelRadius = additionalData["travelRadius"] as? String
    }
    
    // Custom Decodable initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode basic properties
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        birthday = try container.decodeIfPresent(Date.self, forKey: .birthday)
        
        // Decode dates
        if let createdTimestamp = try container.decodeIfPresent(TimeInterval.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: createdTimestamp)
        } else {
            createdAt = Date()
        }
        
        if let updatedTimestamp = try container.decodeIfPresent(TimeInterval.self, forKey: .updatedAt) {
            updatedAt = Date(timeIntervalSince1970: updatedTimestamp)
        } else {
            updatedAt = Date()
        }
        
        // Decode social profile fields
        isSocialProfileActive = try container.decodeIfPresent(Bool.self, forKey: .isSocialProfileActive) ?? false
        socialAuthProvider = try container.decodeIfPresent(String.self, forKey: .socialAuthProvider)
        
        // Decode preference fields
        availabilityTimes = try container.decodeIfPresent([String].self, forKey: .availabilityTimes)
        availableDays = try container.decodeIfPresent([String].self, forKey: .availableDays)
        favoriteActivities = try container.decodeIfPresent([String].self, forKey: .favoriteActivities)
        calendarConnections = try container.decodeIfPresent([String].self, forKey: .calendarConnections)
        travelRadius = try container.decodeIfPresent(String.self, forKey: .travelRadius)
    }
    
    // Custom Encodable implementation
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode basic properties
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        try container.encodeIfPresent(birthday, forKey: .birthday)
        
        // Encode dates as timestamps
        try container.encode(createdAt.timeIntervalSince1970, forKey: .createdAt)
        try container.encode(updatedAt.timeIntervalSince1970, forKey: .updatedAt)
        
        // Encode social profile fields
        try container.encode(isSocialProfileActive, forKey: .isSocialProfileActive)
        try container.encodeIfPresent(socialAuthProvider, forKey: .socialAuthProvider)
        
        // Encode preference fields
        try container.encodeIfPresent(availabilityTimes, forKey: .availabilityTimes)
        try container.encodeIfPresent(availableDays, forKey: .availableDays)
        try container.encodeIfPresent(favoriteActivities, forKey: .favoriteActivities)
        try container.encodeIfPresent(calendarConnections, forKey: .calendarConnections)
        try container.encodeIfPresent(travelRadius, forKey: .travelRadius)
    }
    
    // Initialize with custom data
    init(id: String, 
         name: String? = nil, 
         email: String? = nil, 
         phoneNumber: String? = nil, 
         bio: String? = nil, 
         profileImageURL: String? = nil,
         birthday: Date? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         isSocialProfileActive: Bool = false,
         socialAuthProvider: String? = nil,
         availabilityTimes: [String]? = nil,
         availableDays: [String]? = nil,
         favoriteActivities: [String]? = nil,
         calendarConnections: [String]? = nil,
         travelRadius: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.birthday = birthday
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isSocialProfileActive = isSocialProfileActive
        self.socialAuthProvider = socialAuthProvider
        self.availabilityTimes = availabilityTimes
        self.availableDays = availableDays
        self.favoriteActivities = favoriteActivities
        self.calendarConnections = calendarConnections
        self.travelRadius = travelRadius
    }
    
    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "createdAt": createdAt.timeIntervalSince1970,
            "updatedAt": updatedAt.timeIntervalSince1970,
            "isSocialProfileActive": isSocialProfileActive
        ]
        
        if let name = name { dict["name"] = name }
        if let email = email { dict["email"] = email }
        if let phoneNumber = phoneNumber { dict["phoneNumber"] = phoneNumber }
        if let bio = bio { dict["bio"] = bio }
        if let profileImageURL = profileImageURL { dict["profileImageURL"] = profileImageURL }
        if let birthday = birthday { dict["birthday"] = birthday.timeIntervalSince1970 }
        if let socialAuthProvider = socialAuthProvider { dict["socialAuthProvider"] = socialAuthProvider }
        
        // Add preference fields to dictionary
        if let availabilityTimes = availabilityTimes { dict["availabilityTimes"] = availabilityTimes }
        if let availableDays = availableDays { dict["availableDays"] = availableDays }
        if let favoriteActivities = favoriteActivities { dict["favoriteActivities"] = favoriteActivities }
        if let calendarConnections = calendarConnections { dict["calendarConnections"] = calendarConnections }
        if let travelRadius = travelRadius { dict["travelRadius"] = travelRadius }
        
        return dict
    }
    
    // CodingKeys for Codable implementation
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phoneNumber
        case bio
        case profileImageURL
        case birthday        
        case createdAt
        case updatedAt
        case isSocialProfileActive
        case socialAuthProvider
        case availabilityTimes
        case availableDays
        case favoriteActivities
        case calendarConnections
        case travelRadius
    }
} 
