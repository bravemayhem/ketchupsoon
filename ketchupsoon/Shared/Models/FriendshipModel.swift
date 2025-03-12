//
//  FriendshipModel.swift
//  ketchupsoon
//
//  Created by Brooklyn Beltran on 3/11/25.
//
import Foundation
import SwiftData

@Model
final class FriendshipModel {
    // Relationship identifiers
    var id: UUID
    var userID: String    // Current user's Firebase UID
    var friendID: String  // Friend's Firebase UID
    
    // Relationship metadata
    var relationshipType: String
    var lastHangoutDate: Date?
    var nextScheduledHangout: Date?
    var customNotes: String?
    
    // Additional relationship data
    var isFavorite: Bool
    var lastContactedDate: Date?
    
    // Tracking
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        userID: String,
        friendID: String,
        relationshipType: String = "friend",
        lastHangoutDate: Date? = nil,
        nextScheduledHangout: Date? = nil,
        customNotes: String? = nil,
        isFavorite: Bool = false,
        lastContactedDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userID = userID
        self.friendID = friendID
        self.relationshipType = relationshipType
        self.lastHangoutDate = lastHangoutDate
        self.nextScheduledHangout = nextScheduledHangout
        self.customNotes = customNotes
        self.isFavorite = isFavorite
        self.lastContactedDate = lastContactedDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Required for SwiftData
    init() {
        self.id = UUID()
        self.userID = ""
        self.friendID = ""
        self.relationshipType = "friend"
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
