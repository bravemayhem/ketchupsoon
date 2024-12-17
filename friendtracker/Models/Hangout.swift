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
    var friend: Friend?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        activity: String = "",
        location: String = "",
        isScheduled: Bool = false,
        friend: Friend? = nil
    ) {
        self.id = id
        self.date = date
        self.activity = activity
        self.location = location
        self.isScheduled = isScheduled
        self.friend = friend
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}