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
    
    init() {
        Task {
            await requestAccess()
            await setupGoogleCalendar()
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
}