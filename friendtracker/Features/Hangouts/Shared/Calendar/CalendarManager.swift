import EventKit
import SwiftUI
import GoogleSignIn
import GoogleAPIClientForREST_Calendar
import FirebaseAuth
import FirebaseCore

@MainActor
class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    private let eventStore = EKEventStore()
    private var googleService: GTLRCalendarService?
    private let auth = Auth.auth()
    
    @Published var isAuthorized = false
    @Published var isGoogleAuthorized = false
    @Published var connectedCalendars: [Friend.ConnectedCalendar] = []
    @Published var selectedCalendarType: CalendarType = .apple
    @Published var googleUserEmail: String?
    @Published var appleUserEmail: String?
    @Published private(set) var eventCache: [String: (date: Date, events: [CalendarEvent])] = [:]
    private var isInitialized = false
    
    enum CalendarType {
        case apple
        case google
    }
    
    private init() {
        Task {
            await initialize()
        }
    }
    
    private func initialize() async {
        // Only setup Google Calendar initially, don't request access
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
        
        // Check if user is already signed in
        if let currentUser = auth.currentUser {
            do {
                // Try to restore previous Google Sign-In
                let signInResult = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                isGoogleAuthorized = true
                googleUserEmail = currentUser.email
                
                // Configure Google Calendar service with the restored session
                googleService?.authorizer = signInResult.fetcherAuthorizer
                
                await loadConnectedCalendars()
            } catch {
                print("Error restoring Google Sign-In: \(error)")
                isGoogleAuthorized = false
                googleUserEmail = nil
            }
        }
    }
    
    func requestAccess() async {
        // Request Apple Calendar access
        if #available(iOS 17.0, *) {
            do {
                try await eventStore.requestFullAccessToEvents()
                isAuthorized = true
                // Get the default calendar's source (which contains the user's email)
                if let defaultCalendar = eventStore.defaultCalendarForNewEvents,
                   let source = defaultCalendar.source {
                    appleUserEmail = source.title
                }
                await loadConnectedCalendars()
            } catch {
                print("Error requesting calendar access: \(error)")
                isAuthorized = false
                appleUserEmail = nil
            }
        } else {
            do {
                let granted = try await eventStore.requestAccess(to: .event)
                isAuthorized = granted
                if granted {
                    // Get the default calendar's source (which contains the user's email)
                    if let defaultCalendar = eventStore.defaultCalendarForNewEvents,
                       let source = defaultCalendar.source {
                        appleUserEmail = source.title
                    }
                    await loadConnectedCalendars()
                }
            } catch {
                print("Error requesting calendar access: \(error)")
                isAuthorized = false
                appleUserEmail = nil
            }
        }
    }
    
    func requestGoogleAccess() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else { return }
        
        do {
            // Configure Google Sign-In
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "144315286048-7jasampp9nttpd09rd3d31iui3j9stif.apps.googleusercontent.com")
            
            // Sign in with Google
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController,
                hint: nil,
                additionalScopes: [
                    "https://www.googleapis.com/auth/calendar",
                    "https://www.googleapis.com/auth/calendar.events",
                    "https://www.googleapis.com/auth/calendar.readonly"
                ]
            )
            
            // Get Google ID token and access token
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing ID token"])
            }
            
            // Create Firebase credential
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            // Sign in to Firebase with credential
            let authResult = try await auth.signIn(with: credential)
            
            isGoogleAuthorized = true
            googleUserEmail = authResult.user.email
            
            // Configure Google Calendar service
            googleService?.authorizer = result.user.fetcherAuthorizer
            
            await loadConnectedCalendars()
        } catch {
            print("Error signing in with Google: \(error)")
            isGoogleAuthorized = false
            googleUserEmail = nil
            throw error
        }
    }
    
    func signOutGoogle() async {
        do {
            try auth.signOut()
            isGoogleAuthorized = false
            googleService?.authorizer = nil
            googleUserEmail = nil
            await loadConnectedCalendars()
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    // Update token before each Google Calendar operation
    private func refreshGoogleAuthorization() async throws {
        guard let currentUser = auth.currentUser else {
            throw CalendarError.unauthorized
        }
        
        // Get fresh ID token but discard it since we don't need it
        _ = try await currentUser.getIDToken()
        
        // Update Google Calendar service authorization
        if let signInResult = try? await GIDSignIn.sharedInstance.restorePreviousSignIn() {
            googleService?.authorizer = signInResult.fetcherAuthorizer
        }
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
    
    struct CalendarEventResult {
        let eventId: String
        let htmlLink: String?
    }
    
    func createHangoutEvent(activity: String, location: String, date: Date, duration: TimeInterval, emailRecipients: [String] = [], attendeeNames: [String] = []) async throws -> CalendarEventResult {
        // For Google Calendar
        if selectedCalendarType == .google && isGoogleAuthorized {
            guard let service = googleService else { throw CalendarError.unauthorized }
            
            // Refresh token before operation
            try await refreshGoogleAuthorization()
            
            let event = GTLRCalendar_Event()
            event.summary = activity
            event.location = location
            event.descriptionProperty = "KetchupSoon Event\nAttendees: \(attendeeNames.joined(separator: ", "))"
            
            let startDateTime = GTLRDateTime(date: date)
            let endDateTime = GTLRDateTime(date: date.addingTimeInterval(duration))
            
            let start = GTLRCalendar_EventDateTime()
            start.dateTime = startDateTime
            event.start = start
            
            let end = GTLRCalendar_EventDateTime()
            end.dateTime = endDateTime
            event.end = end
            
            // Add all attendees from emailRecipients
            if !emailRecipients.isEmpty {
                let attendees = emailRecipients.map { email in
                    let attendee = GTLRCalendar_EventAttendee()
                    attendee.email = email
                    return attendee
                }
                event.attendees = attendees
            }
            
            let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: "primary")
            // Send email notifications to all attendees
            query.sendUpdates = "all"
            
            do {
                let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRCalendar_Event, Error>) in
                    service.executeQuery(query) { callbackTicket, response, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        if let event = response as? GTLRCalendar_Event {
                            continuation.resume(returning: event)
                        } else {
                            continuation.resume(throwing: NSError(domain: "", code: -1))
                        }
                    }
                }
                return CalendarEventResult(
                    eventId: response.identifier ?? UUID().uuidString,
                    htmlLink: response.htmlLink
                )
            } catch {
                print("Error creating Google Calendar event: \(error)")
                throw CalendarError.eventCreationFailed
            }
        }
        
        // For Apple Calendar
        guard isAuthorized else { throw CalendarError.unauthorized }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = activity
        event.location = location
        event.startDate = date
        event.endDate = date.addingTimeInterval(duration)
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Add notes with attendees and email recipients
        var notes = ["KetchupSoon Event"]
        notes.append("Attendees: \(attendeeNames.joined(separator: ", "))")
        if !emailRecipients.isEmpty {
            notes.append("Email Recipients: \(emailRecipients.joined(separator: ", "))")
        }
        event.notes = notes.joined(separator: "\n")
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return CalendarEventResult(
                eventId: event.eventIdentifier,
                htmlLink: nil
            )
        } catch {
            throw CalendarError.eventCreationFailed
        }
    }
    
    // MARK: - Event Fetching
    
    struct CalendarEvent: Identifiable {
        let id: String
        let event: EKEvent
        let source: CalendarSource
        let isKetchupEvent: Bool
        
        init(event: EKEvent, source: CalendarSource) {
            self.event = event
            self.source = source
            // Create a unique ID combining the event ID and source
            self.id = "\(source)_\(event.eventIdentifier ?? UUID().uuidString)"
            // Check if this is a Ketchup event by looking for a specific note or title pattern
            self.isKetchupEvent = event.notes?.contains("KetchupSoon Event") ?? false || 
                                 event.title.contains("with") // Simple heuristic for Ketchup events
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
    
    func preloadTodaysEvents() async {
        let today = Date()
        print("🗓 Preloading events for today: \(today)")
        
        let calendar = Calendar.current
        let dateKey = calendar.startOfDay(for: today).ISO8601Format()
        
        // Check if we already have fresh cached events
        if let cached = eventCache[dateKey],
           calendar.isDate(cached.date, inSameDayAs: today),
           Date().timeIntervalSince(cached.date) < 300 {
            print("✅ Using existing cache for today, last updated: \(cached.date)")
            return
        }
        
        print("🔄 Cache expired or not found, fetching fresh events")
        _ = await getEventsForDate(today)
        print("✅ Today's events cached successfully")
    }
    
    func getEventsForDate(_ date: Date) async -> [CalendarEvent] {
        await ensureInitialized()
        
        guard isAuthorized || isGoogleAuthorized else {
            print("❌ No calendar authorization")
            return []
        }
        
        let calendar = Calendar.current
        let dateKey = calendar.startOfDay(for: date).ISO8601Format()
        
        // Check if we have cached events for this date
        if let cached = eventCache[dateKey],
           calendar.isDate(cached.date, inSameDayAs: date) {
            // If the cache is less than 5 minutes old, use it
            if Date().timeIntervalSince(cached.date) < 300 {
                print("📅 Using cached events for \(dateKey), count: \(cached.events.count)")
                return cached.events
            }
            print("🕒 Cache expired for \(dateKey), last updated: \(cached.date)")
        }
        
        // If not cached or cache is old, fetch new events
        print("🔍 Fetching new events for \(dateKey)")
        let events = await fetchEventsForDate(date)
        print("📥 Fetched \(events.count) events for \(dateKey)")
        
        await MainActor.run {
            self.eventCache[dateKey] = (date: Date(), events: events)
        }
        return events
    }
    
    func clearCache() {
        eventCache.removeAll()
    }
}