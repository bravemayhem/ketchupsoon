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
final class UserModel {
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
    
    // Social profile fields
    var isSocialProfileActive: Bool
    var socialAuthProvider: String?
    
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
        isSocialProfileActive: Bool = false,
        socialAuthProvider: String? = nil,
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
        self.isSocialProfileActive = isSocialProfileActive
        self.socialAuthProvider = socialAuthProvider
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
        self.isSocialProfileActive = false
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
            "isSocialProfileActive": isSocialProfileActive,
            "gradientIndex": gradientIndex
        ]
        
        if let name = name { dict["name"] = name }
        if let email = email { dict["email"] = email }
        if let phoneNumber = phoneNumber { dict["phoneNumber"] = phoneNumber }
        if let bio = bio { dict["bio"] = bio }
        if let profileImageURL = profileImageURL { dict["profileImageURL"] = profileImageURL }
        if let birthday = birthday { dict["birthday"] = birthday.timeIntervalSince1970 }
        if let socialAuthProvider = socialAuthProvider { dict["socialAuthProvider"] = socialAuthProvider }
        
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
        
        user.isSocialProfileActive = additionalData["isSocialProfileActive"] as? Bool ?? false
        user.socialAuthProvider = additionalData["socialAuthProvider"] as? String
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
