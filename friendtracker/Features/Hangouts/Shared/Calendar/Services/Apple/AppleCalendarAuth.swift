import EventKit
import Foundation

actor AppleCalendarAuth: AppleCalendarAuthProtocol {
    private let eventStore: EKEventStore
    
    var isAuthorized = false
    var userEmail: String?
    
    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
    }
    
    func requestAccess() async {
        if #available(iOS 17.0, *) {
            do {
                try await eventStore.requestFullAccessToEvents()
                isAuthorized = true
                if let defaultCalendar = eventStore.defaultCalendarForNewEvents,
                   let source = defaultCalendar.source {
                    userEmail = source.title
                }
            } catch {
                isAuthorized = false
                userEmail = nil
            }
        } else {
            do {
                let granted = try await eventStore.requestAccess(to: .event)
                isAuthorized = granted
                if granted {
                    if let defaultCalendar = eventStore.defaultCalendarForNewEvents,
                       let source = defaultCalendar.source {
                        userEmail = source.title
                    }
                }
            } catch {
                isAuthorized = false
                userEmail = nil
            }
        }
    }
} 