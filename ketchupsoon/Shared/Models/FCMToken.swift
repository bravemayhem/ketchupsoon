import Foundation
import SwiftData

/// A model for storing Firebase Cloud Messaging tokens
@Model
final class FCMToken {
    // Unique identifier for the token record
    @Attribute(.unique) var id: UUID
    
    // The FCM token value
    var token: String
    
    // Device information
    var deviceId: String?
    var deviceName: String?
    var deviceModel: String?
    var appVersion: String?
    
    // Timestamps
    var createdAt: Date
    var lastUsed: Date?
    
    // Status flags
    var isActive: Bool
    
    init(id: UUID = UUID(),
         token: String,
         deviceId: String? = nil,
         deviceName: String? = nil,
         deviceModel: String? = nil,
         appVersion: String? = nil,
         isActive: Bool = true) {
        self.id = id
        self.token = token
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.deviceModel = deviceModel
        self.appVersion = appVersion
        self.createdAt = Date()
        self.lastUsed = Date()
        self.isActive = isActive
    }
} 