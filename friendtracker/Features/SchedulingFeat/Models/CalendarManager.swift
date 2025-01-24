import EventKit
import SwiftUI
import GoogleSignIn
import GoogleAPIClientForREST_Calendar

@MainActor
class CalendarManager: ObservableObject {
    private let eventStore = EKEventStore()
    private var googleService: GTLRCalendarService?
    
    @Published var isAuthorized = false
    @Published var isGoogleAuthorized = false
    @Published var connectedCalendars: [Friend.ConnectedCalendar] = []
    private var isInitialized = false
    
    init() {
        Task {
            await initialize()
        }
    }
    
    private func initialize() async {
        await requestAccess()
        await setupGoogleCalendar()
        isInitialized = true
    }
    
    func ensureInitialized() async {
        if !isInitialized {
            await initialize()
        }
    }
    
    private func setupGoogleCalendar() async {
        googleService = GTLRCalendarService()
        // Configure Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "144315286048-7jasampp9nttpd09rd3d31iui3j9stif.apps.googleusercontent.com")
        
        // Restore previous sign-in
        do {
            let currentUser = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            isGoogleAuthorized = true
            googleService?.authorizer = currentUser.fetcherAuthorizer
            await loadConnectedCalendars()
        } catch {
            print("Error restoring Google sign-in: \(error)")
            isGoogleAuthorized = false
        }
    }
    
    func requestAccess() async {
        // Request Apple Calendar access
        if #available(iOS 17.0, *) {
            do {
                try await eventStore.requestFullAccessToEvents()
                isAuthorized = true
                await loadConnectedCalendars()
            } catch {
                print("Error requesting calendar access: \(error)")
                isAuthorized = false
            }
        } else {
            do {
                let granted = try await eventStore.requestAccess(to: .event)
                isAuthorized = granted
                if granted {
                    await loadConnectedCalendars()
                }
            } catch {
                print("Error requesting calendar access: \(error)")
                isAuthorized = false
            }
        }
    }
    
    func requestGoogleAccess() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else { return }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController,
                hint: nil,
                additionalScopes: [
                    "https://www.googleapis.com/auth/calendar",
                    "https://www.googleapis.com/auth/calendar.events",
                    "https://www.googleapis.com/auth/calendar.readonly"
                ]
            )
            
            isGoogleAuthorized = true
            googleService?.authorizer = result.user.fetcherAuthorizer
            await loadConnectedCalendars()
        } catch {
            print("Error signing in with Google: \(error)")
            throw error
        }
    }
    
    func signOutGoogle() async {
        GIDSignIn.sharedInstance.signOut()
        isGoogleAuthorized = false
        googleService?.authorizer = nil
        await loadConnectedCalendars()
    }
    
    private func loadConnectedCalendars() async {
        var calendars: [Friend.ConnectedCalendar] = []
        
        // Load Apple Calendars
        if isAuthorized {
            let appleCalendars = eventStore.calendars(for: .event)
            calendars.append(contentsOf: appleCalendars.map { calendar in
                Friend.ConnectedCalendar(
                    id: calendar.calendarIdentifier,
                    type: .apple,
                    name: calendar.title,
                    isEnabled: true
                )
            })
        }
        
        // Load Google Calendars
        if isGoogleAuthorized, let service = googleService {
            do {
                let query = GTLRCalendarQuery_CalendarListList.query()
                let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRCalendar_CalendarList, Error>) in
                    service.executeQuery(query) { callbackTicket, response, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        if let calendarList = response as? GTLRCalendar_CalendarList {
                            continuation.resume(returning: calendarList)
                        } else {
                            continuation.resume(throwing: NSError(domain: "", code: -1))
                        }
                    }
                }
                
                if let items = response.items {
                    calendars.append(contentsOf: items.map { calendar in
                        Friend.ConnectedCalendar(
                            id: calendar.identifier ?? UUID().uuidString,
                            type: .google,
                            name: calendar.summary ?? "Untitled",
                            isEnabled: true
                        )
                    })
                }
            } catch {
                print("Error loading Google calendars: \(error)")
            }
        }
        
        await MainActor.run {
            self.connectedCalendars = calendars
        }
    }
    
    // MARK: - Event Management
    
    enum CalendarError: Error {
        case unauthorized
        case eventCreationFailed
        case eventNotFound
    }
    
    func createHangoutEvent(with friend: Friend, activity: String, location: String, date: Date, duration: TimeInterval, emailRecipients: [String] = []) async throws -> String {
        guard isAuthorized else { throw CalendarError.unauthorized }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = "\(activity) with \(friend.name)"
        event.location = location
        event.startDate = date
        event.endDate = date.addingTimeInterval(duration)
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Add friend's email if available
        var allRecipients = emailRecipients
        if let friendEmail = friend.email, !allRecipients.contains(friendEmail) {
            allRecipients.append(friendEmail)
        }
        
        // Add attendees using proper EKEventStore methods
        if !allRecipients.isEmpty {
            for email in allRecipients {
                let attendee = EKParticipant()
                attendee.setValue("mailto:\(email)", forKey: "emailAddress")
                attendee.setValue("REQ-PARTICIPANT", forKey: "participantRole")
                attendee.setValue("IND", forKey: "participantType")
                attendee.setValue("NEEDS-ACTION", forKey: "participantStatus")
                
                var attendees = event.value(forKey: "attendees") as? [EKParticipant] ?? []
                attendees.append(attendee)
                event.setValue(attendees, forKey: "attendees")
            }
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            throw CalendarError.eventCreationFailed
        }
    }
    
    // MARK: - Event Fetching
    
    struct CalendarEvent: Identifiable {
        let id: String
        let event: EKEvent
        let source: CalendarSource
        
        init(event: EKEvent, source: CalendarSource) {
            self.event = event
            self.source = source
            // Create a unique ID combining the event ID and source
            self.id = "\(source)_\(event.eventIdentifier ?? UUID().uuidString)"
        }
        
        enum CalendarSource: String {
            case apple
            case google
        }
    }
    
    func fetchEventsForDate(_ date: Date) async -> [CalendarEvent] {
        var allEvents: [CalendarEvent] = []
        let calendar = Calendar.current
        
        // Get start and end of the selected date
        guard let startDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date),
              let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) else {
            print("Failed to create date range for: \(date)")
            return []
        }
        
        print("Fetching events for date range: \(startDate) to \(endDate)")
        print("Calendar authorization status - Apple: \(isAuthorized), Google: \(isGoogleAuthorized)")
        
        // Fetch Apple Calendar events
        if isAuthorized {
            let calendars = eventStore.calendars(for: .event)
            print("Available Apple calendars: \(calendars.count)")
            let predicate = eventStore.predicateForEvents(
                withStart: startDate,
                end: endDate,
                calendars: calendars
            )
            let appleEvents = eventStore.events(matching: predicate)
            print("Found \(appleEvents.count) Apple Calendar events")
            allEvents.append(contentsOf: appleEvents.map { CalendarEvent(event: $0, source: .apple) })
        }
        
        // Fetch Google Calendar events
        if isGoogleAuthorized, let service = googleService {
            do {
                let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
                query.timeMin = GTLRDateTime(date: startDate)
                query.timeMax = GTLRDateTime(date: endDate)
                query.singleEvents = true
                query.orderBy = "startTime"
                
                let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRCalendar_Events, Error>) in
                    service.executeQuery(query) { callbackTicket, response, error in
                        if let error = error {
                            print("Error fetching Google Calendar events: \(error)")
                            continuation.resume(throwing: error)
                            return
                        }
                        if let events = response as? GTLRCalendar_Events {
                            continuation.resume(returning: events)
                        } else {
                            continuation.resume(throwing: NSError(domain: "", code: -1))
                        }
                    }
                }
                
                if let items = response.items {
                    print("Found \(items.count) Google Calendar events")
                    // Convert Google Calendar events to EKEvents
                    for googleEvent in items {
                        let event = EKEvent(eventStore: eventStore)
                        event.title = googleEvent.summary ?? "Untitled Event"
                        event.location = googleEvent.location
                        
                        if let start = googleEvent.start?.dateTime?.date {
                            event.startDate = start
                        } else if let startDate = googleEvent.start?.date?.date {
                            // Handle all-day events
                            event.startDate = startDate
                            event.isAllDay = true
                        }
                        
                        if let end = googleEvent.end?.dateTime?.date {
                            event.endDate = end
                        } else if let endDate = googleEvent.end?.date?.date {
                            // Handle all-day events
                            event.endDate = endDate
                            event.isAllDay = true
                        }
                        
                        allEvents.append(CalendarEvent(event: event, source: .google))
                    }
                }
            } catch {
                print("Error fetching Google Calendar events: \(error)")
            }
        }
        
        let sortedEvents = allEvents.sorted { $0.event.startDate < $1.event.startDate }
        print("Total events found: \(sortedEvents.count)")
        return sortedEvents
    }
}