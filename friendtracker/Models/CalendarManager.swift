import EventKit
import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import GoogleAPIClientForREST_Calendar

@MainActor
class CalendarManager: ObservableObject {
    private let eventStore = EKEventStore()
    private var googleService: GTLRCalendarService?
    
    @Published var isAuthorized = false
    @Published var isGoogleAuthorized = false
    @Published var busyTimeSlots: [DateInterval] = []
    @Published var connectedCalendars: [Friend.ConnectedCalendar] = []
    
    init() {
        Task {
            await requestAccess()
            setupGoogleCalendar()
        }
    }
    
    private func setupGoogleCalendar() {
        googleService = GTLRCalendarService()
        // Configure Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "144315286048-7jasampp9nttpd09rd3d31iui3j9stif.apps.googleusercontent.com")
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
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "144315286048-7jasampp9nttpd09rd3d31iui3j9stif.apps.googleusercontent.com")
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
    
    private func fetchFriendAvailability(friend: Friend, start: Date, end: Date) async -> [DateInterval] {
        guard isGoogleAuthorized, let service = googleService else { return [] }
        
        do {
            // Create the FreeBusy request body
            let freeBusyRequest = GTLRCalendar_FreeBusyRequest()
            freeBusyRequest.timeMin = GTLRDateTime(date: start)
            freeBusyRequest.timeMax = GTLRDateTime(date: end)
            
            // Add the calendar to check
            let requestItem = GTLRCalendar_FreeBusyRequestItem()
            requestItem.identifier = "primary"
            freeBusyRequest.items = [requestItem]
            
            // Create the query with the request
            let query = GTLRCalendarQuery_FreebusyQuery(object: freeBusyRequest)
            
            // Execute the query
            let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any, Error>) in
                service.executeQuery(query) { callbackTicket, response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: response ?? NSNull())
                }
            }
            
            // Process the response
            guard let freeBusyResponse = response as? GTLRCalendar_FreeBusyResponse,
                  let calendars = freeBusyResponse.calendars?.additionalProperties(),
                  let primaryCalendar = calendars["primary"] as? GTLRCalendar_FreeBusyCalendar,
                  let busyPeriods = primaryCalendar.busy else {
                return []
            }
            
            // Convert to DateIntervals
            return busyPeriods.compactMap { period -> DateInterval? in
                guard let startDate = period.start?.date,
                      let endDate = period.end?.date else {
                    return nil
                }
                return DateInterval(start: startDate, end: endDate)
            }
        } catch {
            print("Error fetching freebusy data: \(error)")
            return []
        }
    }
    
    func fetchBusyTimeSlots(for date: Date, friends: [Friend]) async {
        guard isAuthorized else { return }
        
        var allBusySlots: [DateInterval] = []
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        
        // Fetch local calendar busy times
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        allBusySlots.append(contentsOf: events.map { DateInterval(start: $0.startDate, end: $0.endDate) })
        
        // Fetch friends' busy times
        for friend in friends where friend.calendarIntegrationEnabled {
            if friend.calendarVisibilityPreference != .none {
                let busySlots = await fetchFriendAvailability(friend: friend, start: startOfDay, end: endOfDay)
                allBusySlots.append(contentsOf: busySlots)
            }
        }
        
        await MainActor.run {
            self.busyTimeSlots = allBusySlots
        }
    }
    
    func suggestAvailableTimeSlots(with friends: [Friend], duration: TimeInterval = 3600, limit: Int = 3) async -> [Date] {
        guard isAuthorized else { return [] }
        
        // Fetch busy times for all participants
        await fetchBusyTimeSlots(for: Date(), friends: friends)
        
        let calendar = Calendar.current
        var suggestedTimes: [Date] = []
        var currentDate = Date()
        
        while suggestedTimes.count < limit && 
              currentDate < calendar.date(byAdding: .day, value: 14, to: Date())! {
            
            if let startOfDay = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: currentDate),
               let endOfDay = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: currentDate) {
                
                var timeToCheck = startOfDay
                while timeToCheck < endOfDay {
                    if isTimeSlotAvailable(timeToCheck, duration: duration) {
                        suggestedTimes.append(timeToCheck)
                        if suggestedTimes.count >= limit {
                            break
                        }
                    }
                    timeToCheck = calendar.date(byAdding: .hour, value: 1, to: timeToCheck) ?? endOfDay
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? Date()
        }
        
        return suggestedTimes
    }
    
    // MARK: - Event Management
    
    enum CalendarError: Error {
        case unauthorized
        case eventCreationFailed
        case eventNotFound
        case calendarAccessDenied
    }
    
    func createHangoutEvent(with friend: Friend, activity: String, location: String, date: Date, duration: TimeInterval) async throws -> EKEvent {
        guard isAuthorized else {
            throw CalendarError.unauthorized
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = "\(activity) with \(friend.name)"
        event.location = location
        event.startDate = date
        event.endDate = date.addingTimeInterval(duration)
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.notes = "Hangout scheduled via FriendTracker"
        
        try eventStore.save(event, span: .thisEvent)
        return event
    }
    
    func deleteHangoutEvent(_ event: EKEvent) throws {
        try eventStore.remove(event, span: .thisEvent)
    }
    
    func getUpcomingHangouts(with friend: Friend) async -> [EKEvent] {
        guard isAuthorized else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        guard let threeMonthsFromNow = calendar.date(byAdding: .month, value: 3, to: now) else { return [] }
        
        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: threeMonthsFromNow,
            calendars: [eventStore.defaultCalendarForNewEvents].compactMap { $0 }
        )
        
        return eventStore.events(matching: predicate)
            .filter { $0.title?.contains(friend.name) ?? false }
            .prefix(5)
            .map { $0 }
    }
    
    func isTimeSlotAvailable(_ date: Date, duration: TimeInterval = 3600) -> Bool {
        let proposedInterval = DateInterval(start: date, duration: duration)
        return !busyTimeSlots.contains { busySlot in
            busySlot.intersects(proposedInterval)
        }
    }
}