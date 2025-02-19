import EventKit

// MARK: - Calendar Types
enum CalendarType {
    case apple
    case google
}

// MARK: - Calendar Errors
enum CalendarError: Error {
    case unauthorized
    case eventCreationFailed
    case eventNotFound
    case eventUpdateFailed
    case eventDeletionFailed
    case invalidResponse
}

// MARK: - Calendar Event Result
struct CalendarEventResult {
    let eventId: String
    let htmlLink: String?
    let isGoogleEvent: Bool
    let googleEventId: String?
}

// MARK: - Calendar Event
struct CalendarEvent: Identifiable {
    let id: String
    let event: EKEvent
    let source: CalendarSource
    let isKetchupEvent: Bool
    
    init(event: EKEvent, source: CalendarSource) {
        self.event = event
        self.source = source
        self.id = "\(source)_\(event.eventIdentifier ?? UUID().uuidString)"
        self.isKetchupEvent = event.notes?.contains("KetchupSoon Event") ?? false || 
                             event.title.contains("with")
    }
    
    enum CalendarSource: String {
        case apple
        case google
    }
} 