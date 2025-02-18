import Foundation
import GoogleAPIClientForREST_Calendar

actor GoogleCalendarEvents: GoogleCalendarEventsProtocol {
    private var service: GTLRCalendarService?
    private let auth: GoogleCalendarAuthProtocol
    private let ketchupCalendarName = "Ketchup Soon Events"
    private var ketchupCalendarId: String?
    
    var currentCalendarId: String {
        ketchupCalendarId ?? "primary"
    }
    
    init(service: GTLRCalendarService?, auth: GoogleCalendarAuthProtocol) {
        self.service = service
        self.auth = auth
    }
    
    private func ensureKetchupCalendarExists() async throws {
        guard let service = service else { return }
        
        let listQuery = GTLRCalendarQuery_CalendarListList.query()
        let calendarList = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRCalendar_CalendarList, Error>) in
            service.executeQuery(listQuery) { callbackTicket, response, error in
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
        
        if let existingCalendar = calendarList.items?.first(where: { $0.summary == ketchupCalendarName }) {
            ketchupCalendarId = existingCalendar.identifier
            return
        }
        
        let calendar = GTLRCalendar_Calendar()
        calendar.summary = ketchupCalendarName
        calendar.descriptionProperty = "Calendar for Ketchup Soon events - Managed by the Ketchup Soon app"
        calendar.timeZone = TimeZone.current.identifier
        
        let createQuery = GTLRCalendarQuery_CalendarsInsert.query(withObject: calendar)
        let newCalendar = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRCalendar_Calendar, Error>) in
            service.executeQuery(createQuery) { callbackTicket, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let calendar = response as? GTLRCalendar_Calendar {
                    continuation.resume(returning: calendar)
                } else {
                    continuation.resume(throwing: NSError(domain: "", code: -1))
                }
            }
        }
        
        ketchupCalendarId = newCalendar.identifier
    }
    
    func createEvent(activity: String, location: String, date: Date, duration: TimeInterval, emailRecipients: [String]) async throws -> CalendarEventResult {
        guard let service = service, await auth.isAuthorized else {
            throw CalendarError.unauthorized
        }
        
        try await auth.refreshAuthorization()
        try await ensureKetchupCalendarExists()
        
        let event = GTLRCalendar_Event()
        event.summary = activity
        event.location = location
        event.descriptionProperty = "KetchupSoon Event 🍅"
        
        event.guestsCanModify = true
        event.guestsCanSeeOtherGuests = true
        event.guestsCanInviteOthers = false
        event.anyoneCanAddSelf = false
        event.transparency = "opaque"
        event.visibility = "private"
        
        let startDateTime = GTLRDateTime(date: date)
        let endDateTime = GTLRDateTime(date: date.addingTimeInterval(duration))
        
        let start = GTLRCalendar_EventDateTime()
        start.dateTime = startDateTime
        start.timeZone = TimeZone.current.identifier
        event.start = start
        
        let end = GTLRCalendar_EventDateTime()
        end.dateTime = endDateTime
        end.timeZone = TimeZone.current.identifier
        event.end = end
        
        if !emailRecipients.isEmpty {
            let attendees = emailRecipients.map { email in
                let attendee = GTLRCalendar_EventAttendee()
                attendee.email = email
                attendee.responseStatus = "needsAction"
                attendee.optional = false
                attendee.additionalGuests = 0
                return attendee
            }
            event.attendees = attendees
        }
        
        let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: currentCalendarId)
        query.sendUpdates = "all"
        query.supportsAttachments = true
        
        let createdEvent = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRCalendar_Event, Error>) in
            service.executeQuery(query) { callbackTicket, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let event = response as? GTLRCalendar_Event {
                    continuation.resume(returning: event)
                } else {
                    continuation.resume(throwing: CalendarError.eventCreationFailed)
                }
            }
        }
        
        return CalendarEventResult(
            eventId: createdEvent.identifier ?? UUID().uuidString,
            htmlLink: createdEvent.htmlLink,
            isGoogleEvent: true,
            googleEventId: createdEvent.identifier
        )
    }
    
    func updateEvent(eventId: String, title: String, location: String, date: Date, duration: TimeInterval, emailRecipients: [String]) async throws {
        guard let service = service, await auth.isAuthorized else {
            throw CalendarError.unauthorized
        }
        
        try await auth.refreshAuthorization()
        
        let event = GTLRCalendar_Event()
        event.summary = title
        event.location = location
        
        let startDateTime = GTLRDateTime(date: date)
        let endDateTime = GTLRDateTime(date: date.addingTimeInterval(duration))
        
        let start = GTLRCalendar_EventDateTime()
        start.dateTime = startDateTime
        start.timeZone = TimeZone.current.identifier
        event.start = start
        
        let end = GTLRCalendar_EventDateTime()
        end.dateTime = endDateTime
        end.timeZone = TimeZone.current.identifier
        event.end = end
        
        if !emailRecipients.isEmpty {
            let attendees = emailRecipients.map { email in
                let attendee = GTLRCalendar_EventAttendee()
                attendee.email = email
                attendee.responseStatus = "needsAction"
                attendee.optional = false
                attendee.additionalGuests = 0
                return attendee
            }
            event.attendees = attendees
        }
        
        let query = GTLRCalendarQuery_EventsPatch.query(withObject: event, calendarId: currentCalendarId, eventId: eventId)
        query.sendUpdates = "all"
        
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRCalendar_Event, Error>) in
            service.executeQuery(query) { callbackTicket, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let event = response as? GTLRCalendar_Event {
                    continuation.resume(returning: event)
                } else {
                    continuation.resume(throwing: CalendarError.eventUpdateFailed)
                }
            }
        }
    }
    
    func deleteEvent(eventId: String) async throws {
        guard let service = service, await auth.isAuthorized else {
            throw CalendarError.unauthorized
        }
        
        try await auth.refreshAuthorization()
        
        let query = GTLRCalendarQuery_EventsDelete.query(withCalendarId: currentCalendarId, eventId: eventId)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            service.executeQuery(query) { _, _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func fetchEvents(for date: Date) async throws -> [GTLRCalendar_Event] {
        guard let service = service, await auth.isAuthorized else {
            throw CalendarError.unauthorized
        }
        
        let calendar = Calendar.current
        guard let startDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date),
              let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) else {
            return []
        }
        
        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
        query.timeMin = GTLRDateTime(date: startDate)
        query.timeMax = GTLRDateTime(date: endDate)
        query.singleEvents = true
        query.orderBy = "startTime"
        
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
        
        return response.items ?? []
    }
    
    func fetchCalendars() async throws -> [GTLRCalendar_CalendarListEntry] {
        guard let service = service, await auth.isAuthorized else {
            throw CalendarError.unauthorized
        }
        
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
        
        return response.items ?? []
    }
    
    func fetchEvent(eventId: String) async throws -> GTLRCalendar_Event {
        print("🔄 GoogleCalendarEvents: Starting fetchEvent for ID: \(eventId)")
        
        guard let service = service else {
            print("❌ GoogleCalendarEvents: Service is nil")
            throw CalendarError.unauthorized
        }
        
        let isAuthorized = await auth.isAuthorized
        print("🔑 GoogleCalendarEvents: Authorization status: \(isAuthorized)")
        
        guard isAuthorized else {
            print("❌ GoogleCalendarEvents: Not authorized")
            throw CalendarError.unauthorized
        }
        
        print("🔄 GoogleCalendarEvents: Refreshing authorization")
        do {
            try await auth.refreshAuthorization()
            print("✅ GoogleCalendarEvents: Authorization refreshed successfully")
        } catch {
            print("❌ GoogleCalendarEvents: Failed to refresh authorization: \(error)")
            throw CalendarError.unauthorized
        }
        
        print("🔄 GoogleCalendarEvents: Ensuring Ketchup calendar exists")
        do {
            try await ensureKetchupCalendarExists()
            print("✅ GoogleCalendarEvents: Ketchup calendar check completed")
        } catch {
            print("⚠️ GoogleCalendarEvents: Error checking Ketchup calendar: \(error)")
            // Continue anyway as we'll try both calendars
        }
        
        print("📍 GoogleCalendarEvents: Using calendar ID: \(currentCalendarId)")
        print("🔍 GoogleCalendarEvents: Searching for event: \(eventId)")
        
        // First try the Ketchup calendar if it exists
        if let ketchupId = ketchupCalendarId {
            print("🔍 GoogleCalendarEvents: Trying Ketchup calendar first")
            do {
                let query = GTLRCalendarQuery_EventsGet.query(withCalendarId: ketchupId, eventId: eventId)
                let event = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRCalendar_Event, Error>) in
                    service.executeQuery(query) { callbackTicket, response, error in
                        if let error = error {
                            print("⚠️ GoogleCalendarEvents: Error in Ketchup calendar: \(error)")
                            if let gtlrError = error as NSError? {
                                print("   Domain: \(gtlrError.domain)")
                                print("   Code: \(gtlrError.code)")
                                print("   Description: \(gtlrError.localizedDescription)")
                                if let structuredError = gtlrError.userInfo["GTLRStructuredError"] {
                                    print("   Structured error: \(structuredError)")
                                }
                            }
                            continuation.resume(throwing: error)
                            return
                        }
                        if let event = response as? GTLRCalendar_Event {
                            print("✅ GoogleCalendarEvents: Found event in Ketchup calendar")
                            continuation.resume(returning: event)
                        } else {
                            print("⚠️ GoogleCalendarEvents: Response was not an event")
                            continuation.resume(throwing: CalendarError.eventNotFound)
                        }
                    }
                }
                return event
            } catch {
                print("⚠️ GoogleCalendarEvents: Event not found in Ketchup calendar, trying primary")
            }
        }
        
        print("🔍 GoogleCalendarEvents: Trying primary calendar")
        let query = GTLRCalendarQuery_EventsGet.query(withCalendarId: "primary", eventId: eventId)
        
        let event = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GTLRCalendar_Event, Error>) in
            service.executeQuery(query) { callbackTicket, response, error in
                if let error = error {
                    print("❌ GoogleCalendarEvents: Error in primary calendar")
                    if let gtlrError = error as NSError? {
                        print("   Domain: \(gtlrError.domain)")
                        print("   Code: \(gtlrError.code)")
                        print("   Description: \(gtlrError.localizedDescription)")
                        if let structuredError = gtlrError.userInfo["GTLRStructuredError"] {
                            print("   Structured error: \(structuredError)")
                        }
                    }
                    continuation.resume(throwing: error)
                    return
                }
                if let event = response as? GTLRCalendar_Event {
                    print("✅ GoogleCalendarEvents: Found event in primary calendar")
                    continuation.resume(returning: event)
                } else {
                    print("❌ GoogleCalendarEvents: Response was not an event")
                    continuation.resume(throwing: CalendarError.eventNotFound)
                }
            }
        }
        
        return event
    }
} 