import EventKit
import SwiftUI

@MainActor
class CalendarManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var isAuthorized = false
    @Published var busyTimeSlots: [DateInterval] = []
    
    init() {
        Task {
            await requestAccess()
        }
    }
    
    func requestAccess() async {
        if #available(iOS 17.0, *) {
            do {
                try await eventStore.requestFullAccessToEvents()
                isAuthorized = true
            } catch {
                print("Error requesting calendar access: \(error)")
                isAuthorized = false
            }
        } else {
            do {
                let granted = try await eventStore.requestAccess(to: .event)
                isAuthorized = granted
            } catch {
                print("Error requesting calendar access: \(error)")
                isAuthorized = false
            }
        }
    }
    
    func fetchBusyTimeSlots(for date: Date) async {
        guard isAuthorized else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        
        busyTimeSlots = events.map { event in
            DateInterval(start: event.startDate, end: event.endDate)
        }
    }
    
    func isTimeSlotAvailable(_ date: Date, duration: TimeInterval = 3600) -> Bool {
        let proposedInterval = DateInterval(start: date, duration: duration)
        return !busyTimeSlots.contains { busySlot in
            busySlot.intersects(proposedInterval)
        }
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
    
    func suggestAvailableTimeSlots(duration: TimeInterval = 3600, limit: Int = 3) -> [Date] {
        guard isAuthorized else { return [] }
        
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
}