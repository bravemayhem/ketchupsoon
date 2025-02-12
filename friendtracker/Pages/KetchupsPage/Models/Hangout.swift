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
    @Relationship(deleteRule: .cascade) var friends: [Friend]
    @Attribute(.transformable(by: ManualAttendeeArrayValueTransformer.self)) private var _manualAttendees: Data?
    
    var manualAttendees: [ManualAttendee] {
        get {
            guard let data = _manualAttendees else { return [] }
            return (try? JSONDecoder().decode([ManualAttendee].self, from: data)) ?? []
        }
        set {
            _manualAttendees = try? JSONEncoder().encode(newValue)
        }
    }
    
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
        self.friends = friends
        self._manualAttendees = nil
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
        rescheduled.manualAttendees = self.manualAttendees
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
        PRODID:-//FriendTracker//Hangout//EN
        CALSCALE:GREGORIAN
        METHOD:REQUEST
        BEGIN:VEVENT
        DTSTART:\(startDate)
        DTEND:\(endDate)
        DTSTAMP:\(dateFormatter.string(from: Date()))
        ORGANIZER;CN=FriendTracker:mailto:no-reply@friendtracker.app
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

final class ManualAttendeeArrayValueTransformer: ValueTransformer {
    static let name = NSValueTransformerName("ManualAttendeeArrayValueTransformer")
    
    override class func transformedValueClass() -> AnyClass {
        NSData.self
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        // Handle both array and data input for backward compatibility
        if let data = value as? Data {
            return data
        }
        if let attendees = value as? [ManualAttendee] {
            return try? JSONEncoder().encode(attendees)
        }
        return nil
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        // Try to decode as array first
        if let attendees = try? JSONDecoder().decode([ManualAttendee].self, from: data) {
            return attendees
        }
        // If that fails, return the raw data (for backward compatibility)
        return data
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    static func register() {
        if !ValueTransformer.valueTransformerNames().contains(name) {
            ValueTransformer.setValueTransformer(
                ManualAttendeeArrayValueTransformer(),
                forName: name
            )
        }
    }
}
