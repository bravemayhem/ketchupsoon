import Foundation
import GoogleAPIClientForREST_Calendar

actor GoogleCalendarMonitoring: GoogleCalendarMonitoringProtocol {
    private var service: GTLRCalendarService?
    private let auth: GoogleCalendarAuthProtocol
    private weak var delegate: GoogleCalendarServiceDelegate?
    private var monitoringTask: Task<Void, Never>?
    private let pollingInterval: TimeInterval = 300 // 5 minutes
    private var lastSyncToken: String?
    private var isMonitoring = false
    
    init(service: GTLRCalendarService?, auth: GoogleCalendarAuthProtocol, delegate: GoogleCalendarServiceDelegate?) {
        self.service = service
        self.auth = auth
        self.delegate = delegate
    }
    
    func startEventMonitoring() async {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // Cancel any existing monitoring task
        monitoringTask?.cancel()
        
        // Start a new monitoring task
        monitoringTask = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled {
                // Check isMonitoring in an async context
                guard await self.isMonitoring else { break }
                
                do {
                    try await self.checkForChanges()
                    try await Task.sleep(nanoseconds: UInt64(self.pollingInterval * 1_000_000_000))
                } catch {
                    print("Error monitoring Google Calendar changes: \(error)")
                    try? await Task.sleep(nanoseconds: UInt64(30 * 1_000_000_000)) // Wait 30 seconds before retrying
                }
            }
        }
    }
    
    func stopEventMonitoring() {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    private func checkForChanges() async throws {
        guard let service = service, await auth.isAuthorized else {
            throw CalendarError.unauthorized
        }
        
        try await auth.refreshAuthorization()
        
        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
        query.singleEvents = true
        
        if let syncToken = lastSyncToken {
            query.syncToken = syncToken
        } else {
            // If no sync token, get events from last 24 hours
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            query.timeMin = GTLRDateTime(date: startDate)
            query.timeMax = GTLRDateTime(date: Date())
            query.orderBy = "updated"  // Only use orderBy when not using sync token
        }
        
        let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRCalendar_Events, Error>) in
            service.executeQuery(query) { callbackTicket, response, error in
                if let error = error {
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
        
        // Update sync token for next request
        lastSyncToken = response.nextSyncToken
        
        // If there are any changes, notify the delegate
        if let items = response.items, !items.isEmpty {
            await notifyDelegate()
        }
    }
    
    private func notifyDelegate() async {
        await delegate?.googleCalendarEventsDidChange()
    }
} 