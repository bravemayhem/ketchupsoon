//
//  UserModel.swift
//  ketchupsoon
//
//  Created by Brooklyn Beltran on 3/11/25.
//  Primary purpose: Data persistence and Firebase integration
//  Represents a complete user profile with all attributes
//  Used for storage in SwiftData and Firebase

import Foundation
import SwiftData
import FirebaseAuth
import CoreData

@Model
final class UserModel: Codable {
    // Basic properties
    var id: String        // Firebase UID (using String to match Firebase)
    var name: String?
    var profileImageURL: String?
    
    // Contact information
    var email: String?
    var phoneNumber: String?
    
    // Personal information
    var bio: String?
    var birthday: Date?
    
    // Appearance
    var gradientIndex: Int
    
    // User preferences - stored as JSON string for SwiftData compatibility
    var preferencesJSON: String?
    @Attribute(.transformable(by: ArrayTransformer.self))
    var availabilityTimes: [String]?
    
    @Attribute(.transformable(by: ArrayTransformer.self))
    var availableDays: [String]?
    
    @Attribute(.transformable(by: ArrayTransformer.self))
    var favoriteActivities: [String]?
    
    @Attribute(.transformable(by: ArrayTransformer.self))
    var calendarConnections: [String]?
    var travelRadius: String?
    
    // Tracking data
    var createdAt: Date
    var updatedAt: Date
    
    // Main initializer
    init(
        id: String,
        name: String? = nil,
        profileImageURL: String? = nil,
        email: String? = nil,
        phoneNumber: String? = nil,
        bio: String? = nil,
        birthday: Date? = nil,
        gradientIndex: Int = 0,
        preferences: [String: Any]? = nil,
        availabilityTimes: [String]? = nil,
        availableDays: [String]? = nil,
        favoriteActivities: [String]? = nil,
        calendarConnections: [String]? = nil,
        travelRadius: String? = nil,
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
        self.gradientIndex = gradientIndex
        self.preferencesJSON = Self.encodePreferences(preferences)
        self.availabilityTimes = availabilityTimes
        self.availableDays = availableDays
        self.favoriteActivities = favoriteActivities
        self.calendarConnections = calendarConnections
        self.travelRadius = travelRadius
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Required empty initializer for SwiftData
    init() {
        self.id = UUID().uuidString
        self.gradientIndex = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Firebase integration methods
    
    // Convert to Firebase dictionary
    func toFirebaseDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "createdAt": createdAt.timeIntervalSince1970,
            "updatedAt": updatedAt.timeIntervalSince1970,
            "gradientIndex": gradientIndex
        ]
        
        if let name = name { dict["name"] = name }
        if let email = email { dict["email"] = email }
        if let phoneNumber = phoneNumber { dict["phoneNumber"] = phoneNumber }
        if let bio = bio { dict["bio"] = bio }
        if let profileImageURL = profileImageURL { dict["profileImageURL"] = profileImageURL }
        if let birthday = birthday { dict["birthday"] = birthday.timeIntervalSince1970 }
        
        // Add preference fields
        if let availabilityTimes = availabilityTimes { dict["availabilityTimes"] = availabilityTimes }
        if let availableDays = availableDays { dict["availableDays"] = availableDays }
        if let favoriteActivities = favoriteActivities { dict["favoriteActivities"] = favoriteActivities }
        if let calendarConnections = calendarConnections { dict["calendarConnections"] = calendarConnections }
        if let travelRadius = travelRadius { dict["travelRadius"] = travelRadius }
        
        // Add any additional preferences
        if let preferences = getPreferences() {
            dict["preferences"] = preferences
        }
        
        return dict
    }
    
    // Create from Firebase User
    static func from(firebaseUser: User, additionalData: [String: Any] = [:]) -> UserModel {
        let user = UserModel()
        user.id = firebaseUser.uid
        user.name = firebaseUser.displayName
        user.email = firebaseUser.email
        user.phoneNumber = firebaseUser.phoneNumber
        user.profileImageURL = firebaseUser.photoURL?.absoluteString
        
        // Set additional data from Firestore
        user.bio = additionalData["bio"] as? String
        
        if let birthdayTimestamp = additionalData["birthday"] as? TimeInterval {
            user.birthday = Date(timeIntervalSince1970: birthdayTimestamp)
        }
        
        if let createdTimestamp = additionalData["createdAt"] as? TimeInterval {
            user.createdAt = Date(timeIntervalSince1970: createdTimestamp)
        }
        
        if let updatedTimestamp = additionalData["updatedAt"] as? TimeInterval {
            user.updatedAt = Date(timeIntervalSince1970: updatedTimestamp)
        }
                
        user.gradientIndex = additionalData["gradientIndex"] as? Int ?? 0
        
        // Set preference fields
        user.availabilityTimes = additionalData["availabilityTimes"] as? [String]
        user.availableDays = additionalData["availableDays"] as? [String]
        user.favoriteActivities = additionalData["favoriteActivities"] as? [String]
        user.calendarConnections = additionalData["calendarConnections"] as? [String]
        user.travelRadius = additionalData["travelRadius"] as? String
        
        // Set any additional preferences
        if let prefs = additionalData["preferences"] as? [String: Any] {
            user.preferencesJSON = Self.encodePreferences(prefs)
        }
        
        return user
    }
    
    // MARK: - Preferences Handling
    
    // Encode dictionary to JSON string
    private static func encodePreferences(_ preferences: [String: Any]?) -> String? {
        guard let preferences = preferences else { return nil }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: preferences, options: [])
            return String(data: data, encoding: .utf8)
        } catch {
            print("Failed to encode preferences: \(error)")
            return nil
        }
    }
    
    // Decode JSON string to dictionary
    func getPreferences() -> [String: Any]? {
        guard let jsonString = preferencesJSON,
              let data = jsonString.data(using: .utf8) else { return nil }
        
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print("Failed to decode preferences: \(error)")
            return nil
        }
    }
    
    // Convenience method to set preferences
    func setPreferences(_ preferences: [String: Any]?) {
        preferencesJSON = Self.encodePreferences(preferences)
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, name, profileImageURL, email, phoneNumber
        case bio, birthday, gradientIndex
        case availabilityTimes, availableDays, favoriteActivities, calendarConnections
        case travelRadius, createdAt, updatedAt, preferences
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(bio, forKey: .bio)
        
        if let birthday = birthday {
            try container.encode(birthday.timeIntervalSince1970, forKey: .birthday)
        }
        
        try container.encode(gradientIndex, forKey: .gradientIndex)
        try container.encodeIfPresent(availabilityTimes, forKey: .availabilityTimes)
        try container.encodeIfPresent(availableDays, forKey: .availableDays)
        try container.encodeIfPresent(favoriteActivities, forKey: .favoriteActivities)
        try container.encodeIfPresent(calendarConnections, forKey: .calendarConnections)
        try container.encodeIfPresent(travelRadius, forKey: .travelRadius)
        try container.encode(createdAt.timeIntervalSince1970, forKey: .createdAt)
        try container.encode(updatedAt.timeIntervalSince1970, forKey: .updatedAt)
        
        // Encode preferences as a JSON string
        try container.encodeIfPresent(preferencesJSON, forKey: .preferences)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        
        if let birthdayTimestamp = try container.decodeIfPresent(TimeInterval.self, forKey: .birthday) {
            birthday = Date(timeIntervalSince1970: birthdayTimestamp)
        } else {
            birthday = nil
        }
        
        gradientIndex = try container.decodeIfPresent(Int.self, forKey: .gradientIndex) ?? 0
        availabilityTimes = try container.decodeIfPresent([String].self, forKey: .availabilityTimes)
        availableDays = try container.decodeIfPresent([String].self, forKey: .availableDays)
        favoriteActivities = try container.decodeIfPresent([String].self, forKey: .favoriteActivities)
        calendarConnections = try container.decodeIfPresent([String].self, forKey: .calendarConnections)
        travelRadius = try container.decodeIfPresent(String.self, forKey: .travelRadius)
        
        // Handle dates with default values if not present
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
        
        // For preferences, try to decode either as a String (JSON) or as a dictionary
        if let prefsString = try container.decodeIfPresent(String.self, forKey: .preferences) {
            // If it's already a JSON string, use it directly
            preferencesJSON = prefsString
        } else {
            // If it's not found as a string, check if Firebase stored it as a map
            // This custom handling is needed since we can't directly decode [String: Any]
            // We'll need to handle this specially for Firebase's Firestore data
            preferencesJSON = nil
        }
    }
}

// MARK: - Array Value Transformer

@objc(ArrayTransformer)
class ArrayTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSArray.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let array = value as? [String] else { return nil }
        return try? NSKeyedArchiver.archivedData(withRootObject: array, requiringSecureCoding: true)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: data) as? [String]
    }
    
    static func register() {
        ValueTransformer.setValueTransformer(ArrayTransformer(), forName: NSValueTransformerName("ArrayTransformer"))
    }
}
