import Foundation
import GoogleAPIClientForREST_Calendar
import FirebaseAuth

protocol GoogleCalendarServiceDelegate: AnyObject {
    func googleCalendarEventsDidChange() async
}

protocol GoogleCalendarEventsProtocol: Actor {
    var currentCalendarId: String { get }
    func createEvent(activity: String, location: String, date: Date, duration: TimeInterval, emailRecipients: [String]) async throws -> CalendarEventResult
    func updateEvent(eventId: String, title: String, location: String, date: Date, duration: TimeInterval, emailRecipients: [String]) async throws
    func deleteEvent(eventId: String) async throws
    func fetchEvents(for date: Date) async throws -> [GTLRCalendar_Event]
    func fetchCalendars() async throws -> [GTLRCalendar_CalendarListEntry]
    func fetchEvent(eventId: String) async throws -> GTLRCalendar_Event
}

protocol GoogleCalendarAuthProtocol: Actor {
    var isAuthorized: Bool { get }
    var userEmail: String? { get }
    func setup() async throws
    func requestAccess(from viewController: UIViewController) async throws
    func signOut() async
    func refreshAuthorization() async throws
}

protocol GoogleCalendarMonitoringProtocol: Actor {
    func startEventMonitoring() async
    func stopEventMonitoring()
} 