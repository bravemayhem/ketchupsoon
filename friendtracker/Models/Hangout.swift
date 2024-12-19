import Foundation
import SwiftData

@Model
@preconcurrency
final class Hangout {
    @Attribute(.unique) var id: UUID
    var date: Date
    var activity: String
    var location: String
    var isScheduled: Bool
    var needsReschedule: Bool?
    var isCompleted: Bool = false
    var duration: TimeInterval?  // Optional duration in minutes
    var friend: Friend?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        activity: String = "",
        location: String = "",
        isScheduled: Bool = false,
        needsReschedule: Bool? = false,
        isCompleted: Bool = false,
        duration: TimeInterval? = nil,
        friend: Friend? = nil
    ) {
        self.id = id
        self.date = date
        self.activity = activity
        self.location = location
        self.isScheduled = isScheduled
        self.needsReschedule = needsReschedule
        self.isCompleted = isCompleted
        self.duration = duration
        self.friend = friend
    }
    
    var endDate: Date {
        if let duration = duration {
            return date.addingTimeInterval(duration * 60)  // Convert minutes to seconds
        } else {
            // Default to 1 hour if no duration specified
            return date.addingTimeInterval(3600)  // 3600 seconds = 1 hour
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}