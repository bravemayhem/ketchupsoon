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
    var originalHangoutId: UUID?  // Track if this is a rescheduled hangout
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
        self.originalHangoutId = nil
        self.friend = friend
    }
    
    // Create a new hangout as a reschedule of this one
    func createRescheduled(newDate: Date, duration: TimeInterval = 3600) -> Hangout? {
        guard let friend = self.friend else { return nil }
        
        let rescheduled = Hangout(
            date: newDate,
            activity: self.activity,
            location: self.location,
            isScheduled: true,
            friend: friend,
            duration: duration
        )
        rescheduled.originalHangoutId = self.id
        return rescheduled
    }
    
    // Check if this is a rescheduled hangout
    var isRescheduled: Bool {
        originalHangoutId != nil
    }
    
    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
    
    var calendarEventURL: URL? {
        // Format dates in iCal format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        let startDate = dateFormatter.string(from: date)
        let endDate = dateFormatter.string(from: endDate)
        
        // Create event description
        var description = "Hangout with"
        if let friendName = friend?.name {
            description += " \(friendName)"
        }
        
        // Create iCal content
        var iCalContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//FriendTracker//Hangout//EN
        CALSCALE:GREGORIAN
        METHOD:REQUEST
        BEGIN:VEVENT
        DTSTART:\(startDate)
        DTEND:\(endDate)
        DTSTAMP:\(dateFormatter.string(from: Date()))
        ORGANIZER;CN=FriendTracker:mailto:no-reply@friendtracker.app
        SUMMARY:\(activity)
        DESCRIPTION:\(description)
        """
        
        if !location.isEmpty {
            iCalContent += "\nLOCATION:\(location)"
        }
        
        // Add friend as attendee if they have an email
        if let email = friend?.email {
            iCalContent += "\nATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=TRUE;CN=\(friend?.name ?? "Friend"):mailto:\(email)"
        }
        
        iCalContent += """
        
        END:VEVENT
        END:VCALENDAR
        """
        
        // Encode the iCal content for URL
        let encodedContent = iCalContent
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .replacingOccurrences(of: "\n", with: "%0A") ?? ""
        
        // Use the data URL format that iOS recognizes for calendar events
        return URL(string: "data:text/calendar;charset=utf8,\(encodedContent)")
    }
}
