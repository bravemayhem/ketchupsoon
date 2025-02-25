import EventKit
import Foundation

actor AppleCalendarEvents: AppleCalendarEventsProtocol {
    private let eventStore: EKEventStore
    private let auth: AppleCalendarAuthProtocol
    
    init(eventStore: EKEventStore, auth: AppleCalendarAuthProtocol) {
        self.eventStore = eventStore
        self.auth = auth
    }
    
    func createEvent(activity: String, location: String, date: Date, duration: TimeInterval) async throws -> CalendarEventResult {
        guard await auth.isAuthorized else {
            throw CalendarError.unauthorized
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = activity
        event.location = location
        event.startDate = date
        event.endDate = date.addingTimeInterval(duration)
        event.notes = "KetchupSoon Event 🍅"
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return CalendarEventResult(
                eventId: event.eventIdentifier ?? UUID().uuidString,
                htmlLink: nil,
                isGoogleEvent: false,
                googleEventId: nil
            )
        } catch {
            throw CalendarError.eventCreationFailed
        }
    }
    
    func updateEvent(eventId: String, title: String, location: String, date: Date, duration: TimeInterval) async throws {
        guard await auth.isAuthorized else {
            throw CalendarError.unauthorized
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw CalendarError.eventNotFound
        }
        
        event.title = title
        event.location = location
        event.startDate = date
        event.endDate = date.addingTimeInterval(duration)
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw CalendarError.eventUpdateFailed
        }
    }
    
    func deleteEvent(eventId: String) async throws {
        guard await auth.isAuthorized else {
            throw CalendarError.unauthorized
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw CalendarError.eventNotFound
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch {
            throw CalendarError.eventDeletionFailed
        }
    }
    
    func fetchEvents(for date: Date) async -> [EKEvent] {
        guard await auth.isAuthorized else { return [] }
        
        let calendar = Calendar.current
        guard let startDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date),
              let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) else {
            return []
        }
        
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )
        
        return eventStore.events(matching: predicate)
    }
    
    func fetchCalendars() async -> [EKCalendar] {
        guard await auth.isAuthorized else { return [] }
        return eventStore.calendars(for: .event)
    }
} 