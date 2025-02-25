import Foundation
import GoogleAPIClientForREST_Calendar
import FirebaseAuth
import GoogleSignIn

actor GoogleCalendarService {
    static let shared = GoogleCalendarService()
    
    private let calendarService = GTLRCalendarService()
    private var isConfigured = false
    
    private init() {
        // Initialize with default configuration
        calendarService.shouldFetchNextPages = true
        calendarService.isRetryEnabled = true
    }
    
    // MARK: - Configuration
    
    func configure() async throws {
        guard let user = await AuthManager.shared.googleUser else {
            throw CalendarError.unauthorized
        }
        
        // Set up the calendar service with the user's authorizer
        calendarService.authorizer = user.fetcherAuthorizer
        isConfigured = true
        print("Google Calendar service configured successfully")
    }
    
    // MARK: - Calendar Operations
    
    func listEvents(startDate: Date, endDate: Date) async throws -> [GTLRCalendar_Event] {
        try await ensureConfigured()
        
        // Set up the query
        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
        query.timeMin = GTLRDateTime(date: startDate)
        query.timeMax = GTLRDateTime(date: endDate)
        query.singleEvents = true
        query.orderBy = "startTime"
        
        // Execute the query
        let result: [GTLRCalendar_Event] = try await withCheckedThrowingContinuation { continuation in
            calendarService.executeQuery(query) { (ticket, result, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let eventList = result as? GTLRCalendar_Events else {
                    continuation.resume(throwing: CalendarError.invalidResponse)
                    return
                }
                
                continuation.resume(returning: eventList.items ?? [])
            }
        }
        
        return result
    }
    
    func createEvent(title: String, startDate: Date, endDate: Date, description: String? = nil, location: String? = nil, attendees: [String]? = nil) async throws -> GTLRCalendar_Event {
        try await ensureConfigured()
        
        // Create a new event
        let event = GTLRCalendar_Event()
        event.summary = title
        
        // Set the start time
        let startDateTime = GTLRDateTime(date: startDate)
        let startEventDateTime = GTLRCalendar_EventDateTime()
        startEventDateTime.dateTime = startDateTime
        event.start = startEventDateTime
        
        // Set the end time
        let endDateTime = GTLRDateTime(date: endDate)
        let endEventDateTime = GTLRCalendar_EventDateTime()
        endEventDateTime.dateTime = endDateTime
        event.end = endEventDateTime
        
        // Add description if provided
        if let description = description {
            event.descriptionProperty = description
        }
        
        // Add location if provided
        if let location = location {
            event.location = location
        }
        
        // Add attendees if provided
        if let attendees = attendees, !attendees.isEmpty {
            event.attendees = attendees.map { email in
                let attendee = GTLRCalendar_EventAttendee()
                attendee.email = email
                return attendee
            }
        }
        
        // Set up the insert query
        let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: "primary")
        query.sendUpdates = "all" // Send notifications to attendees
        
        // Execute the query
        let result: GTLRCalendar_Event = try await withCheckedThrowingContinuation { continuation in
            calendarService.executeQuery(query) { (ticket, result, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let createdEvent = result as? GTLRCalendar_Event else {
                    continuation.resume(throwing: CalendarError.invalidResponse)
                    return
                }
                
                continuation.resume(returning: createdEvent)
            }
        }
        
        return result
    }
    
    func updateEvent(eventId: String, title: String? = nil, startDate: Date? = nil, endDate: Date? = nil, description: String? = nil, location: String? = nil, attendees: [String]? = nil) async throws -> GTLRCalendar_Event {
        try await ensureConfigured()
        
        // First, get the current event to update
        let getQuery = GTLRCalendarQuery_EventsGet.query(withCalendarId: "primary", eventId: eventId)
        
        let event: GTLRCalendar_Event = try await withCheckedThrowingContinuation { continuation in
            calendarService.executeQuery(getQuery) { (ticket, result, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let event = result as? GTLRCalendar_Event else {
                    continuation.resume(throwing: CalendarError.invalidResponse)
                    return
                }
                
                continuation.resume(returning: event)
            }
        }
        
        // Update the event with new values
        if let title = title {
            event.summary = title
        }
        
        if let startDate = startDate {
            let startDateTime = GTLRDateTime(date: startDate)
            let startEventDateTime = GTLRCalendar_EventDateTime()
            startEventDateTime.dateTime = startDateTime
            event.start = startEventDateTime
        }
        
        if let endDate = endDate {
            let endDateTime = GTLRDateTime(date: endDate)
            let endEventDateTime = GTLRCalendar_EventDateTime()
            endEventDateTime.dateTime = endDateTime
            event.end = endEventDateTime
        }
        
        if let description = description {
            event.descriptionProperty = description
        }
        
        if let location = location {
            event.location = location
        }
        
        if let attendees = attendees {
            event.attendees = attendees.map { email in
                let attendee = GTLRCalendar_EventAttendee()
                attendee.email = email
                return attendee
            }
        }
        
        // Set up the update query
        let updateQuery = GTLRCalendarQuery_EventsUpdate.query(withObject: event, calendarId: "primary", eventId: eventId)
        updateQuery.sendUpdates = "all" // Send notifications to attendees
        
        // Execute the query
        let result: GTLRCalendar_Event = try await withCheckedThrowingContinuation { continuation in
            calendarService.executeQuery(updateQuery) { (ticket, result, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let updatedEvent = result as? GTLRCalendar_Event else {
                    continuation.resume(throwing: CalendarError.invalidResponse)
                    return
                }
                
                continuation.resume(returning: updatedEvent)
            }
        }
        
        return result
    }
    
    func deleteEvent(eventId: String) async throws {
        try await ensureConfigured()
        
        // Set up the delete query
        let query = GTLRCalendarQuery_EventsDelete.query(withCalendarId: "primary", eventId: eventId)
        query.sendUpdates = "all" // Send notifications to attendees
        
        // Execute the query
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            calendarService.executeQuery(query) { (ticket, result, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume(returning: ())
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func ensureConfigured() async throws {
        // Check if token needs refresh
        _ = try await AuthManager.shared.refreshGoogleToken()
        
        // Configure if not already
        if !isConfigured {
            try await configure()
        }
    }
}

// MARK: - Calendar Errors

enum CalendarError: Error {
    case unauthorized
    case invalidResponse
    case eventCreationFailed
    case eventUpdateFailed
    case eventDeletionFailed
    case eventFetchFailed
    case eventNotFound
}

extension CalendarError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Not authorized to access calendar. Please sign in with your Google account."
        case .invalidResponse:
            return "Received an invalid response from the calendar service."
        case .eventCreationFailed:
            return "Failed to create the calendar event."
        case .eventUpdateFailed:
            return "Failed to update the calendar event."
        case .eventDeletionFailed:
            return "Failed to delete the calendar event."
        case .eventFetchFailed:
            return "Failed to fetch calendar events."
        case .eventNotFound:
            return "The calendar event was not found."
        }
    }
} 