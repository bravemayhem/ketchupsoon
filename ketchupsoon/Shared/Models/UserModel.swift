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
    
    // User preferences
    var availabilityTimes: [String]?
    var availableDays: [String]?
    var favoriteActivities: [String]?
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
        
        return user
    }
}
