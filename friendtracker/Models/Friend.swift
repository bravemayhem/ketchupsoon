import Foundation
import SwiftUI
import SwiftData

enum FriendLocation: String, Codable {
    case local = "Local"
    case remote = "Remote"
}

@Model
@MainActor
final class Friend {
    @Attribute(.unique) var id: UUID
    var name: String
    var lastSeen: Date?
    var location: String
    var phoneNumber: String?
    var photoData: Data?
    @Relationship(deleteRule: .cascade) var hangouts: [Hangout]
    
    init(
        id: UUID = UUID(),
        name: String,
        lastSeen: Date? = nil,
        location: String = FriendLocation.local.rawValue,
        phoneNumber: String? = nil,
        photoData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.lastSeen = lastSeen
        self.location = location
        self.phoneNumber = phoneNumber
        self.photoData = photoData
        self.hangouts = []
    }
    
    var lastSeenText: String {
        guard let lastSeen = lastSeen else {
            return "Never"
        }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.month, .weekOfYear, .day], from: lastSeen, to: now)
        
        if let months = components.month, months > 0 {
            return "\(months) month\(months == 1 ? "" : "s") ago"
        } else if let weeks = components.weekOfYear, weeks > 0 {
            return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
        } else if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else {
            return "Today"
        }
    }
    
    var needsToConnect: Bool {
        guard let lastSeen = lastSeen else {
            return true
        }
        let weeksSinceLastSeen = Calendar.current.dateComponents([.weekOfYear], from: lastSeen, to: Date()).weekOfYear ?? 0
        return weeksSinceLastSeen >= 3
    }
    
    var scheduledHangouts: [Hangout] {
        return hangouts
            .filter { $0.isScheduled && $0.date > Date() }
            .sorted { $0.date < $1.date }
    }
    
    var profileImage: Image? {
        guard let data = photoData,
              let uiImage = UIImage(data: data) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
}