import EventKit
import SwiftUI
import GoogleSignIn
import GoogleAPIClientForREST_Calendar
import FirebaseAuth
import FirebaseCore

// MARK: - Calendar Manager
@MainActor
class CalendarManager: ObservableObject, AppleCalendarServiceDelegate, GoogleCalendarServiceDelegate {
    static let shared = CalendarManager()
    
    // MARK: - Services
    private let eventStore = EKEventStore()
    private let googleService = GTLRCalendarService()
    
    private lazy var appleAuth: AppleCalendarAuth = {
        let auth = AppleCalendarAuth(eventStore: eventStore)
        return auth
    }()
    
    private lazy var appleEvents: AppleCalendarEvents = {
        let events = AppleCalendarEvents(eventStore: eventStore, auth: appleAuth)
        return events
    }()
    
    private lazy var appleMonitoring: AppleCalendarMonitoring = {
        let monitoring = AppleCalendarMonitoring(eventStore: eventStore, auth: appleAuth, delegate: self)
        return monitoring
    }()
    
    private lazy var googleAuth: GoogleCalendarAuth = {
        let auth = GoogleCalendarAuth(service: googleService)
        return auth
    }()
    
    private lazy var googleEvents: GoogleCalendarEvents = {
        let events = GoogleCalendarEvents(service: googleService, auth: googleAuth)
        return events
    }()
    
    private lazy var googleMonitoring: GoogleCalendarMonitoring = {
        let monitoring = GoogleCalendarMonitoring(service: googleService, auth: googleAuth, delegate: self)
        return monitoring
    }()
    
    // MARK: - Published State
    @Published var isAuthorized = false
    @Published var isGoogleAuthorized = false
    @Published var connectedCalendars: [Friend.ConnectedCalendar] = []
    @Published var selectedCalendarType: CalendarType = .apple {
        didSet {
            print("Calendar type changed to: \(selectedCalendarType)")
            UserDefaults.standard.set(selectedCalendarType == .google ? "google" : "apple", forKey: "defaultCalendarType")
        }
    }
    @Published var googleUserEmail: String?
    @Published var appleUserEmail: String?
    @Published private(set) var eventCache: [String: (date: Date, events: [CalendarEvent])] = [:]
    
    private var isInitialized = false
    
    var hasSelectedCalendarAccess: Bool {
        switch selectedCalendarType {
        case .apple: return isAuthorized
        case .google: return isGoogleAuthorized
        }
    }
    
    private init() {
        let defaultType = UserDefaults.standard.string(forKey: "defaultCalendarType") ?? "apple"
        self.selectedCalendarType = defaultType == "google" ? .google : .apple
    }
    
    // MARK: - Initialization
    
    private func initialize() async {
        guard !isInitialized else { return }
        
        if selectedCalendarType == .apple {
            await appleAuth.requestAccess()
            isAuthorized = await appleAuth.isAuthorized
            appleUserEmail = await appleAuth.userEmail
            await appleMonitoring.startEventMonitoring()
        }
        
        if selectedCalendarType == .google {
            do {
                try await googleAuth.setup()
                isGoogleAuthorized = await googleAuth.isAuthorized
                googleUserEmail = await googleAuth.userEmail
                await googleMonitoring.startEventMonitoring()
            } catch {
                print("❌ Failed to setup Google Calendar: \(error)")
                isGoogleAuthorized = false
                googleUserEmail = nil
            }
        }
        
        await loadConnectedCalendars()
        isInitialized = true
    }
    
    func ensureInitialized() async {
        if !isInitialized {
            await initialize()
        }
    }
    
    // MARK: - Calendar Change Delegate
    
    nonisolated func calendarEventsDidChange() {
        Task { @MainActor in
            await refreshTodaysEvents()
        }
    }
    
    private func refreshTodaysEvents() async {
        let today = Date()
        let calendar = Calendar.current
        let dateKey = calendar.startOfDay(for: today).ISO8601Format()
        eventCache.removeValue(forKey: dateKey)
        
        await preloadTodaysEvents()
    }
    
    // MARK: - Calendar Authorization
    
    func requestAccess() async {
        if selectedCalendarType == .apple {
            await appleAuth.requestAccess()
            isAuthorized = await appleAuth.isAuthorized
            appleUserEmail = await appleAuth.userEmail
            await appleMonitoring.startEventMonitoring()
        }
        await loadConnectedCalendars()
    }
    
    func requestGoogleAccess(from viewController: UIViewController) async throws {
        // Wait for the Google auth process to complete
        try await googleAuth.requestAccess(from: viewController)
        
        // Update UI state on main actor
        isGoogleAuthorized = await googleAuth.isAuthorized
        googleUserEmail = await googleAuth.userEmail
        
        if isGoogleAuthorized {
            await googleMonitoring.startEventMonitoring()
            // If Google was authorized successfully, update the selected calendar type
            selectedCalendarType = .google
            UserDefaults.standard.set("google", forKey: "defaultCalendarType")
            print("✅ Google Calendar authorized and set as default")
        }
        
        await loadConnectedCalendars()
    }
    
    func signOutGoogle() async {
        await googleAuth.signOut()
        isGoogleAuthorized = await googleAuth.isAuthorized
        googleUserEmail = nil
        await googleMonitoring.stopEventMonitoring()
        await loadConnectedCalendars()
    }
    
    // MARK: - Event Management
    
    func createHangoutEvent(activity: String, location: String, date: Date, duration: TimeInterval, emailRecipients: [String] = []) async throws -> CalendarEventResult {
        switch selectedCalendarType {
        case .apple:
            return try await appleEvents.createEvent(
                activity: activity,
                location: location,
                date: date,
                duration: duration
            )
        case .google:
            return try await googleEvents.createEvent(
                activity: activity,
                location: location,
                date: date,
                duration: duration,
                emailRecipients: emailRecipients
            )
        }
    }
    
    func updateEvent(eventId: String, isGoogleEvent: Bool, title: String, location: String, date: Date, duration: TimeInterval, emailRecipients: [String]) async throws {
        if isGoogleEvent {
            try await googleEvents.updateEvent(
                eventId: eventId,
                title: title,
                location: location,
                date: date,
                duration: duration,
                emailRecipients: emailRecipients
            )
        } else {
            try await appleEvents.updateEvent(
                eventId: eventId,
                title: title,
                location: location,
                date: date,
                duration: duration
            )
        }
    }
    
    func deleteEvent(eventId: String, isGoogleEvent: Bool) async throws {
        if isGoogleEvent {
            try await googleEvents.deleteEvent(eventId: eventId)
        } else {
            try await appleEvents.deleteEvent(eventId: eventId)
        }
    }
    
    // MARK: - Event Fetching and Caching
    
    func fetchEventsForDate(_ date: Date) async -> [CalendarEvent] {
        var allEvents: [CalendarEvent] = []
        
        if isAuthorized {
            let appleEvents = await self.appleEvents.fetchEvents(for: date)
            allEvents.append(contentsOf: appleEvents.map { CalendarEvent(event: $0, source: .apple) })
        }
        
        if isGoogleAuthorized {
            do {
                let googleEvents = try await self.googleEvents.fetchEvents(for: date)
                for googleEvent in googleEvents {
                    let event = EKEvent(eventStore: eventStore)
                    event.title = googleEvent.summary ?? "Untitled Event"
                    event.location = googleEvent.location
                    
                    if let start = googleEvent.start?.dateTime?.date {
                        event.startDate = start
                    } else if let startDate = googleEvent.start?.date?.date {
                        event.startDate = startDate
                        event.isAllDay = true
                    }
                    
                    if let end = googleEvent.end?.dateTime?.date {
                        event.endDate = end
                    } else if let endDate = googleEvent.end?.date?.date {
                        event.endDate = endDate
                        event.isAllDay = true
                    }
                    
                    allEvents.append(CalendarEvent(event: event, source: .google))
                }
            } catch {
                print("Error fetching Google Calendar events: \(error)")
            }
        }
        
        return allEvents.sorted { $0.event.startDate < $1.event.startDate }
    }
    
    func getEventsForDate(_ date: Date) async -> [CalendarEvent] {
        await ensureInitialized()
        
        guard isAuthorized || isGoogleAuthorized else { return [] }
        
        let calendar = Calendar.current
        let dateKey = calendar.startOfDay(for: date).ISO8601Format()
        
        if let cached = eventCache[dateKey],
           calendar.isDate(cached.date, inSameDayAs: date),
           Date().timeIntervalSince(cached.date) < 300 {
            return cached.events
        }
        
        let events = await fetchEventsForDate(date)
        
        await MainActor.run {
            self.eventCache[dateKey] = (date: Date(), events: events)
        }
        return events
    }
    
    func preloadTodaysEvents() async {
        let today = Date()
        let calendar = Calendar.current
        let dateKey = calendar.startOfDay(for: today).ISO8601Format()
        
        if let cached = eventCache[dateKey],
           calendar.isDate(cached.date, inSameDayAs: today),
           Date().timeIntervalSince(cached.date) < 300 {
            return
        }
        
        _ = await getEventsForDate(today)
    }
    
    func clearCache() {
        eventCache.removeAll()
    }
    
    // MARK: - Event Syncing
    
    func syncGoogleEventAttendees(for hangout: Hangout) async throws {
        guard let googleEventId = hangout.googleEventId else {
            print("⚠️ CalendarManager: No Google Event ID provided")
            return
        }
        
        print("🔄 CalendarManager: Fetching Google Calendar event: \(googleEventId)")
        
        let event = try await googleEvents.fetchEvent(eventId: googleEventId)
        print("✅ CalendarManager: Successfully fetched event")
        
        guard let attendees = event.attendees else {
            print("ℹ️ CalendarManager: No attendees found in Google Calendar event")
            return
        }
        
        print("👥 CalendarManager: Found \(attendees.count) attendees in Google Calendar")
        
        // Simply sync all attendee emails
        let newAttendeeEmails = attendees.compactMap { attendee -> String? in
            guard let email = attendee.email else {
                print("⚠️ CalendarManager: Attendee missing email")
                return nil
            }
            print("👤 CalendarManager: Processing attendee: \(email)")
            return email
        }
        
        // Update attendee emails if there are changes
        if Set(newAttendeeEmails) != Set(hangout.attendeeEmails) {
            print("✅ CalendarManager: Updating hangout with \(newAttendeeEmails.count) attendee emails")
            hangout.attendeeEmails = newAttendeeEmails
        } else {
            print("ℹ️ CalendarManager: No changes in attendee emails")
        }
    }
    
    // MARK: - Calendar Loading
    
    private func loadConnectedCalendars() async {
        var calendars: [Friend.ConnectedCalendar] = []
        
        if isAuthorized {
            let appleCalendars = await appleEvents.fetchCalendars()
            calendars.append(contentsOf: appleCalendars.map { calendar in
                Friend.ConnectedCalendar(
                    id: calendar.calendarIdentifier,
                    type: .apple,
                    name: calendar.title,
                    isEnabled: true
                )
            })
        }
        
        if isGoogleAuthorized {
            do {
                let googleCalendars = try await googleEvents.fetchCalendars()
                
                for calendar in googleCalendars {
                    // Add more defensive coding to handle potential type issues
                    let id = calendar.identifier ?? UUID().uuidString
                    let name = calendar.summary ?? "Untitled"
                    
                    print("Google Calendar: id=\(id), name=\(name)")
                    
                    calendars.append(Friend.ConnectedCalendar(
                        id: id,
                        type: .google,
                        name: name,
                        isEnabled: true
                    ))
                }
            } catch {
                print("Error loading Google calendars: \(error)")
            }
        }
        
        await MainActor.run {
            self.connectedCalendars = calendars
        }
    }
}

// MARK: - Event Monitoring
extension CalendarManager {
    func startEventMonitoring() async {
        if selectedCalendarType == .apple {
            await appleMonitoring.startEventMonitoring()
        } else if selectedCalendarType == .google {
            await googleMonitoring.startEventMonitoring()
        }
    }
    
    func stopEventMonitoring() async {
        if selectedCalendarType == .google {
            await googleMonitoring.stopEventMonitoring()
        }
    }
}

// MARK: - Event Monitoring Delegate
extension CalendarManager {
    nonisolated func googleCalendarEventsDidChange() async {
        Task { @MainActor in
            await refreshTodaysEvents()
        }
    }
}