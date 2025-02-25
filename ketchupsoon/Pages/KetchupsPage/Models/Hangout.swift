import Foundation
import SwiftData

@Model
final class Hangout: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var endDate: Date
    var title: String
    var location: String
    var isScheduled: Bool
    var isCompleted: Bool
    var needsReschedule: Bool
    var originalHangoutId: UUID?  // Track if this is a rescheduled hangout
    var eventLink: String?  // Store the web link for the event
    var eventToken: String?  // Store the token for the event
    var googleEventId: String?  // Store the Google Calendar event ID
    var googleEventLink: String?  // Store the Google Calendar event link
    @Relationship(deleteRule: .cascade) var friends: [Friend]
    var attendeeEmails: [String] = []  // Store all attendee emails from calendar events
    
    init(date: Date, title: String, location: String, isScheduled: Bool, friends: [Friend], duration: TimeInterval = 3600) {
        self.id = UUID()
        self.date = date
        self.endDate = date.addingTimeInterval(duration)
        self.title = title
        self.location = location
        self.isScheduled = isScheduled
        self.isCompleted = false
        self.needsReschedule = false
        self.originalHangoutId = nil
        self.eventLink = nil
        self.eventToken = nil
        self.googleEventId = nil
        self.googleEventLink = nil
        self.friends = friends
        self.attendeeEmails = []
    }
    
    // Create a new hangout as a reschedule of this one
    func createRescheduled(newDate: Date, duration: TimeInterval = 3600) -> Hangout {
        let rescheduled = Hangout(
            date: newDate,
            title: self.title,
            location: self.location,
            isScheduled: true,
            friends: self.friends,
            duration: duration
        )
        rescheduled.originalHangoutId = self.id
        rescheduled.attendeeEmails = self.attendeeEmails
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
        let friendNames = friends.map(\.name).joined(separator: ", ")
        let description = "Hangout with \(friendNames)"
        
        // Create iCal content
        var iCalContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//ketchupsoon//Hangout//EN
        CALSCALE:GREGORIAN
        METHOD:REQUEST
        BEGIN:VEVENT
        DTSTART:\(startDate)
        DTEND:\(endDate)
        DTSTAMP:\(dateFormatter.string(from: Date()))
        ORGANIZER;CN=ketchupsoon:mailto:no-reply@ketchupsoon.app
        SUMMARY:\(title)
        DESCRIPTION:\(description)
        """
        
        if !location.isEmpty {
            iCalContent += "\nLOCATION:\(location)"
        }
        
        // Add all friends with emails as attendees
        for friend in friends {
            if let email = friend.email {
                iCalContent += "\nATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=TRUE;CN=\(friend.name):mailto:\(email)"
            }
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

final class ExternalContactArrayValueTransformer: ValueTransformer {
    static let name = NSValueTransformerName("ExternalContactArrayValueTransformer")
    
    override class func transformedValueClass() -> AnyClass {
        NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let contacts = value as? [ExternalContact] else { return nil }
        return try? JSONEncoder().encode(contacts)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? JSONDecoder().decode([ExternalContact].self, from: data)
    }
    
    static func register() {
        ValueTransformer.setValueTransformer(
            ExternalContactArrayValueTransformer(),
            forName: name
        )
    }
}

// MARK: - ExternalContact
struct ExternalContact: Identifiable, Equatable, Codable {
    var id: UUID
    var name: String
    var email: String
    
    init(id: UUID = UUID(), name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}
