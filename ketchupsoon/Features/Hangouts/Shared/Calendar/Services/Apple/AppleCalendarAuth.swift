import EventKit
import Foundation

actor AppleCalendarAuth: AppleCalendarAuthProtocol {
    private let eventStore: EKEventStore
    
    var isAuthorized = false
    var userEmail: String?
    
    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
        // Initially just check the current status without requesting
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    func checkAuthorizationStatus() async {
        // Just check current status without requesting access
        if #available(iOS 17.0, *) {
            let status = EKEventStore.authorizationStatus(for: .event)
            isAuthorized = (status == .fullAccess)
            print("📅 AppleCalendarAuth: iOS 17+ authorization status: \(status.rawValue), isAuthorized: \(isAuthorized)")
        } else {
            let status = EKEventStore.authorizationStatus(for: .event)
            isAuthorized = (status == .authorized)
            print("📅 AppleCalendarAuth: pre-iOS 17 authorization status: \(status.rawValue), isAuthorized: \(isAuthorized)")
        }
        
        // Update email if we have access
        if isAuthorized {
            if let defaultCalendar = eventStore.defaultCalendarForNewEvents,
               let source = defaultCalendar.source {
                userEmail = source.title
            }
        }
    }
    
    func requestAccess() async {
        print("📅 AppleCalendarAuth: Requesting calendar access...")
        
        // Use @MainActor function to ensure UI operations happen on main thread
        // but return the results instead of modifying actor state directly
        let (granted, email) = await requestAccessOnMainThread()
        
        // Update actor-isolated properties with the results
        isAuthorized = granted
        userEmail = email
        
        // Double-check authorization status after request
        if #available(iOS 17.0, *) {
            let status = EKEventStore.authorizationStatus(for: .event)
            print("📅 AppleCalendarAuth: Post-request status on iOS 17+: \(status.rawValue)")
            isAuthorized = (status == .fullAccess)
        } else {
            let status = EKEventStore.authorizationStatus(for: .event)
            print("📅 AppleCalendarAuth: Post-request status pre-iOS 17: \(status.rawValue)")
            isAuthorized = (status == .authorized)
        }
    }
    
    @MainActor
    private func requestAccessOnMainThread() async -> (Bool, String?) {
        var granted = false
        var email: String? = nil
        
        if #available(iOS 17.0, *) {
            do {
                print("📅 AppleCalendarAuth: Using iOS 17+ requestFullAccessToEvents()")
                try await eventStore.requestFullAccessToEvents()
                print("📅 AppleCalendarAuth: Access granted on iOS 17+")
                granted = true
                if let defaultCalendar = await eventStore.defaultCalendarForNewEvents,
                   let source = defaultCalendar.source {
                    email = source.title
                    print("📅 AppleCalendarAuth: Default calendar: \(source.title)")
                }
            } catch {
                print("📅 AppleCalendarAuth: Error requesting calendar access: \(error)")
                granted = false
                email = nil
            }
        } else {
            do {
                print("📅 AppleCalendarAuth: Using pre-iOS 17 requestAccess(to: .event)")
                granted = try await eventStore.requestAccess(to: .event)
                print("📅 AppleCalendarAuth: Access request result: \(granted)")
                if granted {
                    if let defaultCalendar = await eventStore.defaultCalendarForNewEvents,
                       let source = defaultCalendar.source {
                        email = source.title
                        print("📅 AppleCalendarAuth: Default calendar: \(source.title)")
                    }
                }
            } catch {
                print("📅 AppleCalendarAuth: Error requesting calendar access: \(error)")
                granted = false
                email = nil
            }
        }
        
        return (granted, email)
    }
} 
