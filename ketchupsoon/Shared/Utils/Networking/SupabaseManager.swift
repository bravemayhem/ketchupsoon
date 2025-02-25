/*
 Supabase functionality is currently not in use. Commented out to simplify the implementation.
 This includes:
 - Event storage and management
 - Attendee management and RSVPs
 - Invite system
 - Phone number verification
 
 If these features are needed in the future, uncomment this file and ensure Supabase
 configuration is properly set up in Info.plist
*/

/*
import Foundation
import Supabase

// MARK: Event Section
// Event data structure for Supabase
struct SupabaseEventData: Encodable {
    let title: String
    let date: String
    let location: String
    let description: String
    let duration: Int
    let created_at: String
    let creator_id: String
    let is_private: Bool
    let google_calendar_id: String?
    let google_calendar_link: String?
}

// Attendee data structure for Supabase
struct SupabaseAttendeeData: Encodable {
    let event_id: String
    let name: String
    let email: String
    let phone_number: String
    let rsvp_status: String
}

// Response structures
struct EventResponse: Codable {
    let id: String
    let title: String
    let date: String
    let location: String
    let description: String
    let duration: Int
    let created_at: String
    let creator_id: String
    let is_private: Bool
    let google_calendar_id: String?
    let google_calendar_link: String?
    let event_attendees: [AttendeeResponse]?
}

struct AttendeeResponse: Codable {
    let id: String
    let event_id: String
    let name: String
    let email: String
    let phone_number: String
    let rsvp_status: String
}

// Add new structures for invites
struct InviteData: Codable {
    let token: String
    let event_id: String
    let expires_at: String
}

/*
 Phone number standardization was used for Supabase functionality (event storage, invites, RSVPs).
 This is currently not needed but may be useful if we reimplement these features.
 
 extension String {
    func standardizedPhoneNumber() -> String {
        let digitsOnly = self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // If it's a 10-digit US number, add the country code
        if digitsOnly.count == 10 {
            return "1" + digitsOnly
        }
        // If it's already 11 digits and starts with 1, assume it's a US number
        else if digitsOnly.count == 11 && digitsOnly.hasPrefix("1") {
            return digitsOnly
        }
        // Otherwise return as is (for international numbers)
        return digitsOnly
    }
}
*/

// Add new structures for phone number verification
struct PhoneNumberParts {
    let countryCode: String
    let areaCode: String
    let middle: String
    let last: String
    
    var formatted: String {
        if countryCode == "1" {
            return "(\(areaCode)) \(middle)-\(last)"  // US format
        } else {
            return "+\(countryCode) \(areaCode) \(middle) \(last)"  // International format
        }
    }
    
    var standardized: String {
        countryCode + areaCode + middle + last
    }
    
    static func parse(_ phoneNumber: String) -> PhoneNumberParts? {
        // Clean the phone number to only include digits and plus sign
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        print("📱 Parsing phone number: \(cleaned)")
        
        // Extract country code and national number
        var countryCode = "1" // Default to US
        var nationalNumber = cleaned
        
        if cleaned.starts(with: "+") {
            // Handle international format with plus
            let parts = cleaned.dropFirst().split(maxSplits: 1) { !$0.isNumber }
            if let code = parts.first {
                countryCode = String(code)
                nationalNumber = parts.count > 1 ? String(parts[1]) : ""
            }
        } else {
            // Handle various US number formats
            let digitsOnly = cleaned.replacingOccurrences(of: "[^0-9]", with: "")
            
            if digitsOnly.count == 10 {
                // Standard US 10-digit number
                nationalNumber = digitsOnly
            } else if digitsOnly.count == 11 && digitsOnly.hasPrefix("1") {
                // US number with country code
                nationalNumber = String(digitsOnly.dropFirst())
            } else {
                // Invalid format
                print("❌ Invalid phone number format: \(digitsOnly.count) digits")
                return nil
            }
        }
        
        print("📱 Parsed: countryCode=\(countryCode), nationalNumber=\(nationalNumber)")
        
        // Ensure we have exactly 10 digits for the national number (for US numbers)
        if countryCode == "1" && nationalNumber.count != 10 {
            print("❌ Invalid US number: national number should be 10 digits")
            return nil
        }
        
        // For US numbers, split into area code, middle, and last
        if countryCode == "1" {
            guard nationalNumber.count >= 10 else { return nil }
            return PhoneNumberParts(
                countryCode: countryCode,
                areaCode: String(nationalNumber.prefix(3)),
                middle: String(nationalNumber[nationalNumber.index(nationalNumber.startIndex, offsetBy: 3)..<nationalNumber.index(nationalNumber.startIndex, offsetBy: 6)]),
                last: String(nationalNumber.suffix(4))
            )
        } else {
            // For international numbers, use a different splitting strategy
            // This is a simplified version - you might want to handle different country formats differently
            let remaining = nationalNumber
            let areaCode = String(remaining.prefix(3))
            let middle = String(remaining[remaining.index(remaining.startIndex, offsetBy: 3)..<remaining.index(remaining.startIndex, offsetBy: 6)])
            let last = String(remaining.suffix(4))
            return PhoneNumberParts(
                countryCode: countryCode,
                areaCode: areaCode,
                middle: middle,
                last: last
            )
        }
    }
}

// MARK: Poll Section
// Poll data structures for Supabase
struct SupabasePollData: Encodable {
    let title: String
    let creator_name: String
    let created_at: String
    let expires_at: String
    let selection_type: String
}

struct SupabaseTimeSlotData: Encodable {
    let poll_id: String
    let start_time: String
    let end_time: String
}

// Poll response structure
struct PollResponseData: Codable {
    let id: String
    let respondent_name: String
    let respondent_email: String
    let selected_slots: [TimeSlotData]
    let created_at: String
}

// Time slot data structure
struct TimeSlotData: Codable {
    let start_time: String
    let end_time: String
}

// Poll data structure from Supabase
private struct PollData: Codable {
    let id: String
    let title: String
    let created_at: String
    let expires_at: String
    let selection_type: String
    let time_slots: [TimeSlotData]
    let poll_responses: [PollResponseData]
}

class SupabaseManager {
    static let shared = SupabaseManager()
    private let client: SupabaseClient
    private let decoder = JSONDecoder()
    
    private init() {
        // Initialize Supabase client using Info.plist
        guard let infoPlist = Bundle.main.infoDictionary,
              let supabaseUrl = infoPlist["SUPABASE_URL"] as? String,
              let supabaseAnonKey = infoPlist["SUPABASE_ANON_KEY"] as? String else {
            fatalError("Supabase configuration not found in Info.plist")
        }
        
        self.client = SupabaseClient(
            supabaseURL: URL(string: supabaseUrl)!,
            supabaseKey: supabaseAnonKey
        )
    }
    
    // Create event in Supabase
    func createEvent(_ hangout: Hangout) async throws -> (eventId: String, token: String)? {
        print("🚀 Starting hangout creation in Supabase...")
        print("📊 Event details:")
        print("   - Title: \(hangout.title)")
        print("   - Date: \(hangout.date)")
        print("   - Location: \(hangout.location)")
        print("   - Duration: \(hangout.endDate.timeIntervalSince(hangout.date)) seconds")
        print("   - Google Calendar ID: \(hangout.googleEventId ?? "none")")
        print("   - Google Calendar Link: \(hangout.googleEventLink ?? "none")")
        
        // Capture friend data on main thread before async operation
        let friendsData = await MainActor.run {
            hangout.friends.map { friend in
                (
                    name: friend.name,
                    phoneNumber: friend.phoneNumber,
                    email: friend.email ?? ""
                )
            }
        }
        
        // Add debug logging for friends and their phone numbers
        print("👥 Attendee details:")
        for friendData in friendsData {
            print("   - Name: \(friendData.name)")
            print("     Phone: \(String(describing: friendData.phoneNumber))")
            print("     Email: \(friendData.email)")
        }
        
        // Validate required fields
        guard !hangout.title.isEmpty else {
            print("❌ Error: Empty title")
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Title is required"])
        }
        
        // Validate that all friends have phone numbers
        let friendsWithoutPhones = friendsData.filter { $0.phoneNumber == nil || $0.phoneNumber!.isEmpty }
        if !friendsWithoutPhones.isEmpty {
            print("❌ Error: Found \(friendsWithoutPhones.count) friends without phone numbers:")
            for friend in friendsWithoutPhones {
                print("   - \(friend.name): phoneNumber = \(String(describing: friend.phoneNumber))")
            }
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "All friends must have phone numbers. Missing for: \(friendsWithoutPhones.map { $0.name }.joined(separator: ", "))"
            ])
        }
        
        let duration = Int(hangout.endDate.timeIntervalSince(hangout.date))
        print("⏱ Duration calculation:")
        print("   - Start date: \(hangout.date)")
        print("   - End date: \(hangout.endDate)")
        print("   - Raw duration: \(duration)")
        // Use a default duration of 1 hour if not specified
        let finalDuration = duration <= 0 ? 3600 : duration
        print("   - Final duration: \(finalDuration)")
        
        let eventData = SupabaseEventData(
            title: hangout.title,
            date: hangout.date.ISO8601Format(),
            location: hangout.location,
            description: "",
            duration: finalDuration,
            created_at: Date().ISO8601Format(),
            creator_id: UUID().uuidString,
            is_private: false,
            google_calendar_id: hangout.googleEventId,
            google_calendar_link: hangout.googleEventLink
        )
        
        print("📤 Preparing Supabase request:")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(eventData)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📝 Event data JSON:")
                print(jsonString)
            }
        } catch {
            print("❌ Error encoding event data: \(error)")
        }
        
        do {
            print("📡 Sending request to Supabase...")
            let request = try client
                .from("events")
                .insert(eventData)
                .select()
                
            print("🔍 Request details:")
            print("   - Table: events")
            print("   - Method: INSERT")
            print("   - Returning: All columns")
            
            let response = try await request.execute()
            
            print("📥 Response received:")
            print("   - Status: \(response.status)")
            print("   - Data length: \(response.data.count) bytes")
            
            if let responseString = String(data: response.data, encoding: .utf8) {
                print("📄 Response data:")
                print(responseString)
            }
            
            guard response.status == 201 || response.status == 200 else {
                print("❌ Error: Unexpected response status: \(response.status)")
                throw NSError(domain: "SupabaseManager", code: response.status, userInfo: [
                    NSLocalizedDescriptionKey: "Server returned unexpected status: \(response.status)"
                ])
            }
            
            // Try to decode the response
            do {
                let events = try decoder.decode([EventResponse].self, from: response.data)
                guard let eventId = events.first?.id else {
                    print("❌ Error: No event ID in response")
                    throw NSError(domain: "SupabaseManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to get event ID"])
                }
                
                print("✅ Event created successfully:")
                print("   - Event ID: \(eventId)")
                
                // Add organizer first if they have a phone number
                if let organizerPhone = UserSettings.shared.phoneNumber?.standardizedPhoneNumber(), !organizerPhone.isEmpty {
                    let organizerData = SupabaseAttendeeData(
                        event_id: eventId,
                        name: UserSettings.shared.name ?? "Organizer",
                        email: UserSettings.shared.email ?? "",
                        phone_number: organizerPhone,
                        rsvp_status: "accepted"  // Organizer is automatically accepted
                    )
                    
                    print("👤 Adding organizer")
                    let organizerResponse = try await client
                        .from("event_attendees")
                        .insert(organizerData)
                        .select()
                        .execute()
                    
                    print("📥 Organizer response status: \(organizerResponse.status)")
                }
                
                // Then add all friends
                print("👥 Creating attendees:")
                for friendData in friendsData {
                    // Standardize phone number if present
                    let standardizedPhone = friendData.phoneNumber?.standardizedPhoneNumber()
                    
                    let attendeeData = SupabaseAttendeeData(
                        event_id: eventId,
                        name: friendData.name,
                        email: friendData.email,
                        phone_number: standardizedPhone ?? "",
                        rsvp_status: "pending"
                    )
                    
                    print("👤 Adding attendee: \(friendData.name)")
                    let attendeeResponse = try await client
                        .from("event_attendees")
                        .insert(attendeeData)
                        .select()
                        .execute()
                    
                    print("📥 Attendee response status: \(attendeeResponse.status)")
                }
                
                // Create a single invite token for the event
                print("🎟 Creating invite token for event...")
                let token = try await createInvite(eventId: eventId)
                print("✅ Created invite token")
                
                return (eventId: eventId, token: token)
            } catch {
                print("❌ Error decoding response: \(error)")
                if let responseString = String(data: response.data, encoding: .utf8) {
                    print("📥 Response data that failed to decode: \(responseString)")
                }
                throw NSError(domain: "SupabaseManager", code: 500, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to decode server response",
                    NSDebugDescriptionErrorKey: error.localizedDescription
                ])
            }
        } catch {
            print("❌ Error creating event: \(error)")
            throw error
        }
    }
    
    // Get event from Supabase
    func getEvent(id: String) async throws -> EventResponse {
        let response = try await client
            .from("events")
            .select("*, event_attendees(*)")
            .eq("id", value: id)
            .single()
            .execute()
        
        return try decoder.decode(EventResponse.self, from: response.data)
    }
    
    // Update event in Supabase
    func updateEvent(_ event: Hangout) async throws {
        // Validate that all friends have phone numbers
        let friendsWithoutPhones = event.friends.filter { $0.phoneNumber == nil || $0.phoneNumber!.isEmpty }
        if !friendsWithoutPhones.isEmpty {
            print("❌ Error: Some friends are missing phone numbers")
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "All friends must have phone numbers. Missing for: \(friendsWithoutPhones.map { $0.name }.joined(separator: ", "))"
            ])
        }
        
        let duration = Int(event.endDate.timeIntervalSince(event.date))
        let eventData = SupabaseEventData(
            title: event.title,
            date: event.date.ISO8601Format(),
            location: event.location,
            description: "",
            duration: duration,
            created_at: Date().ISO8601Format(),
            creator_id: UUID().uuidString,
            is_private: false,
            google_calendar_id: nil,
            google_calendar_link: nil
        )
        
        try await client
            .from("events")
            .update(eventData)
            .eq("id", value: event.id.uuidString)
            .execute()
            
        // Update attendees
        // First, get existing attendees
        let existingAttendeesResponse = try await client
            .from("event_attendees")
            .select("*")
            .eq("event_id", value: event.id.uuidString)
            .execute()
        
        let existingAttendees = try decoder.decode([AttendeeResponse].self, from: existingAttendeesResponse.data)
        
        // Delete existing attendees if there are any
        if !existingAttendees.isEmpty {
            try await client
                .from("event_attendees")
                .delete()
                .eq("event_id", value: event.id.uuidString)
                .execute()
        }
        
        // Re-add all attendees
        for friend in event.friends {
            let standardizedPhone = friend.phoneNumber?.standardizedPhoneNumber()
            
            let attendeeData = SupabaseAttendeeData(
                event_id: event.id.uuidString,
                name: friend.name,
                email: friend.email ?? "",
                phone_number: standardizedPhone ?? "",
                rsvp_status: "pending"
            )
            
            try await client
                .from("event_attendees")
                .insert(attendeeData)
                .execute()
        }
    }
    
    // Get web link for event
    func getWebLink(for eventId: String, withToken token: String? = nil) -> String {
        // Get your Supabase project URL from Info.plist
        guard let projectUrl = Bundle.main.infoDictionary?["SUPABASE_PROJECT_URL"] as? String else {
            // Fallback to your project's default URL - replace with your actual Supabase project URL
            return "https://events.ketchupsoon.com/hangout/\(eventId)?token=\(token ?? "")"
        }
        
        // Remove any trailing slashes and add the hangout path
        let baseUrl = projectUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return "\(baseUrl)/hangout/\(eventId)?token=\(token ?? "")"
    }
    
    // Test connection to Supabase
    func testConnection() async throws -> Bool {
        do {
            // Just check if we can connect by getting the health status
            _ = try await client
                .from("events")
                .select("count")
                .limit(0)
                .execute()
            
            print("✅ Supabase connection successful!")
            return true
        } catch {
            print("❌ Supabase connection failed: \(error)")
            throw error
        }
    }
    
    // Generate a secure random token
    private func generateToken(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    // Create an invite for an event attendee
    func createInvite(eventId: String) async throws -> String {
        let token = UUID().uuidString
        let expiryDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        
        // Get the organizer's phone number from UserSettings
        guard let phoneNumber = UserSettings.shared.phoneNumber?.standardizedPhoneNumber(),
              !phoneNumber.isEmpty else {
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "Organizer phone number is required to create an invite"
            ])
        }
        
        let inviteData = [
            "event_id": eventId,
            "token": token,
            "phone_number": phoneNumber,
            "expires_at": ISO8601DateFormatter().string(from: expiryDate)
        ]
        
        let response = try await client
            .from("invites")
            .insert(inviteData)
            .execute()
        
        guard response.status == 201 else {
            throw NSError(domain: "SupabaseManager", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create invite"
            ])
        }
        
        return token
    }
    
    // Get event details with an invite token
    func getEventWithInvite(token: String) async throws -> EventResponse {
        let response = try await client
            .from("events")
            .select("*, event_attendees(*)")
            .eq("id", value: """
                (SELECT event_id FROM invites WHERE token = '\(token)' AND expires_at > NOW())
            """)
            .single()
            .execute()
        
        return try decoder.decode(EventResponse.self, from: response.data)
    }
    
    // Verify phone number for event access
    func verifyPhoneNumber(token: String, phoneNumber: String, ipAddress: String) async throws -> Bool {
        guard let parts = PhoneNumberParts.parse(phoneNumber) else {
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "Invalid phone number format"
            ])
        }
        
        let response = try await client
            .rpc("verify_invite_phone", params: [
                "p_token": token,
                "p_country_code": parts.countryCode,
                "p_area_code": parts.areaCode,
                "p_middle": parts.middle,
                "p_last": parts.last,
                "p_ip": ipAddress
            ])
            .execute()
        
        return try decoder.decode(Bool.self, from: response.data)
    }
    
    // Create poll in Supabase
    func createPoll(title: String, timeRanges: [TimeRange], selectionType: SelectionType) async throws -> String {
        print("🎲 Creating poll: \(title)")
        
        let pollData = SupabasePollData(
            title: title,
            creator_name: UserSettings.shared.name ?? "Anonymous",
            created_at: Date().ISO8601Format(),
            expires_at: Calendar.current.date(byAdding: .day, value: 7, to: Date())?.ISO8601Format() ?? "",
            selection_type: selectionType == .oneOnOne ? "one_on_one" : "poll"
        )
        
        // Create the poll
        let pollResponse = try await client
            .from("schedule_polls")
            .insert(pollData)
            .select()
            .single()
            .execute()
            
        guard let pollId = try decoder.decode([String: String].self, from: pollResponse.data)["id"] else {
            throw NSError(domain: "SupabaseManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to get poll ID"])
        }
            
        print("✅ Created poll with ID: \(pollId)")
        
        // Create time slots
        for range in timeRanges {
            // Get the base date components
            let calendar = Calendar.current
            var startComponents = calendar.dateComponents([.year, .month, .day], from: range.startSlot.date)
            startComponents.timeZone = TimeZone(identifier: "UTC")  // Use UTC for consistency
            startComponents.hour = range.startSlot.hour
            startComponents.minute = range.startSlot.minute
            
            var endComponents = calendar.dateComponents([.year, .month, .day], from: range.startSlot.date)  // Use same base date
            endComponents.timeZone = TimeZone(identifier: "UTC")  // Use UTC for consistency
            endComponents.hour = range.endSlot.hour
            endComponents.minute = range.endSlot.minute
            
            guard let startDate = calendar.date(from: startComponents),
                  let endDate = calendar.date(from: endComponents) else {
                print("❌ Failed to create dates for time slot")
                continue
            }
            
            print("📅 Creating time slot: \(startDate) - \(endDate)")
            
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = TimeZone(identifier: "UTC")!
            
            let slotData = SupabaseTimeSlotData(
                poll_id: pollId,
                start_time: formatter.string(from: startDate),
                end_time: formatter.string(from: endDate)
            )
            
            try await client
                .from("time_slots")
                .insert(slotData)
                .execute()
        }
        
        return pollId
    }
    
    func fetchUserPolls() async throws -> [Poll] {
        print("🔍 Fetching user polls")
        
        let pollsResponse = try await client
            .from("schedule_polls")
            .select("""
                *,
                time_slots (*),
                poll_responses (*)
            """)
            .order("created_at", ascending: false)
            .execute()
            
        let pollsData = try decoder.decode([PollData].self, from: pollsResponse.data)
        
        return pollsData.map { data in
            // Convert time slots to TimeRange objects
            let timeSlots = data.time_slots.map { slot -> TimeRange in
                let startDate = ISO8601DateFormatter().date(from: slot.start_time) ?? Date()
                let endDate = ISO8601DateFormatter().date(from: slot.end_time) ?? Date()
                
                var calendar = Calendar.current
                calendar.timeZone = TimeZone(identifier: "UTC")!
                let startComponents = calendar.dateComponents([.hour, .minute], from: startDate)
                let endComponents = calendar.dateComponents([.hour, .minute], from: endDate)
                
                let startSlot = TimeSlot(
                    date: startDate,
                    hour: startComponents.hour ?? 0,
                    minute: startComponents.minute ?? 0
                )
                
                let endSlot = TimeSlot(
                    date: endDate,
                    hour: endComponents.hour ?? 0,
                    minute: endComponents.minute ?? 0
                )
                
                return TimeRange(startSlot: startSlot, endSlot: endSlot)
            }
            
            // Convert responses
            let responses = data.poll_responses.map { response -> PollResponse in
                let selectedSlots = response.selected_slots.map { slot -> TimeRange in
                    let startDate = ISO8601DateFormatter().date(from: slot.start_time) ?? Date()
                    let endDate = ISO8601DateFormatter().date(from: slot.end_time) ?? Date()
                    
                    var calendar = Calendar.current
                    calendar.timeZone = TimeZone(identifier: "UTC")!
                    let startComponents = calendar.dateComponents([.hour, .minute], from: startDate)
                    let endComponents = calendar.dateComponents([.hour, .minute], from: endDate)
                    
                    let startSlot = TimeSlot(
                        date: startDate,
                        hour: startComponents.hour ?? 0,
                        minute: startComponents.minute ?? 0
                    )
                    
                    let endSlot = TimeSlot(
                        date: endDate,
                        hour: endComponents.hour ?? 0,
                        minute: endComponents.minute ?? 0
                    )
                    
                    return TimeRange(startSlot: startSlot, endSlot: endSlot)
                }
                
                return PollResponse(
                    respondentName: response.respondent_name,
                    respondentEmail: response.respondent_email,
                    selectedSlots: selectedSlots,
                    responseDate: ISO8601DateFormatter().date(from: response.created_at) ?? Date()
                )
            }
            
            return Poll(
                id: data.id,
                title: data.title,
                createdAt: ISO8601DateFormatter().date(from: data.created_at) ?? Date(),
                expiresAt: ISO8601DateFormatter().date(from: data.expires_at) ?? Date(),
                selectionType: data.selection_type == "one_on_one" ? .oneOnOne : .poll,
                responses: responses,
                timeSlots: timeSlots
            )
        }
    }
} 
*/
