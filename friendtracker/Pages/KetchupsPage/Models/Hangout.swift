import Foundation
import SwiftData

@Model
final class Hangout: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var endDate: Date
    var activity: String
    var location: String
    var isScheduled: Bool
    var isCompleted: Bool
    var needsReschedule: Bool
    @Relationship(deleteRule: .nullify, inverse: \Friend.hangouts) var friend: Friend?
    
    init(date: Date, activity: String, location: String, isScheduled: Bool, friend: Friend, duration: TimeInterval = 3600) {
        self.id = UUID()
        self.date = date
        self.endDate = date.addingTimeInterval(duration)
        self.activity = activity
        self.location = location
        self.isScheduled = isScheduled
        self.isCompleted = false
        self.needsReschedule = false
        self.friend = friend
    }
    
    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}
