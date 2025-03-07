import Foundation
import SwiftData

/// A model for storing global app statistics
@Model
final class GlobalStats {
    // Unique identifier for this stats record
    @Attribute(.unique) var id: UUID
    
    // App usage stats
    var totalFriendsAdded: Int
    var totalHangoutsScheduled: Int
    var totalHangoutsCompleted: Int
    
    // Feature usage stats
    var calendarIntegrationsEnabled: Int
    var wishlistFriendsCount: Int
    
    // Time stats
    var lastStatsReset: Date
    var createdAt: Date
    var lastUpdated: Date
    
    init(id: UUID = UUID()) {
        self.id = id
        self.totalFriendsAdded = 0
        self.totalHangoutsScheduled = 0
        self.totalHangoutsCompleted = 0
        self.calendarIntegrationsEnabled = 0
        self.wishlistFriendsCount = 0
        self.lastStatsReset = Date()
        self.createdAt = Date()
        self.lastUpdated = Date()
    }
    
    /// Increment a specific counter field
    func increment(field: String, by amount: Int = 1) {
        switch field {
        case "friends":
            totalFriendsAdded += amount
        case "scheduledHangouts":
            totalHangoutsScheduled += amount
        case "completedHangouts":
            totalHangoutsCompleted += amount
        case "calendarIntegrations":
            calendarIntegrationsEnabled += amount
        case "wishlistFriends":
            wishlistFriendsCount += amount
        default:
            break
        }
        
        lastUpdated = Date()
    }
} 