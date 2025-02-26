import EventKit
import Foundation

protocol AppleCalendarServiceDelegate: AnyObject {
    func calendarEventsDidChange()
}

protocol AppleCalendarEventsProtocol: Actor {
    func createEvent(activity: String, location: String, date: Date, duration: TimeInterval) async throws -> CalendarEventResult
    func updateEvent(eventId: String, title: String, location: String, date: Date, duration: TimeInterval) async throws
    func deleteEvent(eventId: String) async throws
    func fetchEvents(for date: Date) async -> [EKEvent]
    func fetchCalendars() async -> [EKCalendar]
}

protocol AppleCalendarAuthProtocol: Actor {
    var isAuthorized: Bool { get }
    var userEmail: String? { get }
    func checkAuthorizationStatus() async
    func requestAccess() async
}

protocol AppleCalendarMonitoringProtocol: Actor {
    func startEventMonitoring(notificationCenter: NotificationCenter) async
    func stopEventMonitoring() async
} 