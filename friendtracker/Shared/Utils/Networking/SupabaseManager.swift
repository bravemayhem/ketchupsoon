import Foundation
import Supabase

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

// Add phone number formatting utilities
extension String {
    // Standardize phone number by removing all non-digit characters
    func standardizedPhoneNumber() -> String {
        return self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
    }
}

// Add new structures for phone number verification
struct PhoneNumberParts {
    let areaCode: String
    let middle: String
    let last: String
    
    var formatted: String {
        "(\(areaCode)) \(middle)-\(last)"
    }
    
    var standardized: String {
        areaCode + middle + last
    }
    
    static func parse(_ phoneNumber: String) -> PhoneNumberParts? {
        let digits = phoneNumber.standardizedPhoneNumber()
        guard digits.count >= 10 else { return nil }
        
        // Take last 10 digits if more are provided
        let last10 = String(digits.suffix(10))
        return PhoneNumberParts(
            areaCode: String(last10.prefix(3)),
            middle: String(last10[last10.index(last10.startIndex, offsetBy: 3)..<last10.index(last10.startIndex, offsetBy: 6)]),
            last: String(last10.suffix(4))
        )
    }
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
        print("🚀 Starting hangout creation...")
        
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
        print("📱 Checking phone numbers for all friends:")
        for friendData in friendsData {
            print("  - \(friendData.name): phoneNumber = \(String(describing: friendData.phoneNumber))")
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
                print("  - \(friend.name): phoneNumber = \(String(describing: friend.phoneNumber))")
            }
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "All friends must have phone numbers. Missing for: \(friendsWithoutPhones.map { $0.name }.joined(separator: ", "))"
            ])
        }
        
        // Get the organizer's phone number from UserSettings
        let organizer = Friend(
            name: UserSettings.shared.name ?? "Organizer",
            phoneNumber: UserSettings.shared.phoneNumber,
            email: UserSettings.shared.email
        )
        
        // Check if either the organizer or any friends have a phone number
        let hasPhoneNumber = UserSettings.shared.hasPhoneNumber ||
                            friendsData.contains(where: { $0.phoneNumber != nil && !$0.phoneNumber!.isEmpty })
        
        guard hasPhoneNumber else {
            print("❌ Error: No valid phone numbers found")
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "Either you or at least one friend must have a phone number"
            ])
        }
        
        let duration = Int(hangout.endDate.timeIntervalSince(hangout.date))
        print("⏱ Raw duration: \(duration)")
        // Use a default duration of 1 hour if not specified
        let finalDuration = duration <= 0 ? 3600 : duration
        print("⏱ Final duration: \(finalDuration)")
        
        let eventData = SupabaseEventData(
            title: hangout.title,
            date: hangout.date.ISO8601Format(),
            location: hangout.location,  // Allow empty location
            description: "",
            duration: finalDuration,
            created_at: Date().ISO8601Format(),
            creator_id: UUID().uuidString,
            is_private: false
        )
        
        print("📤 Sending event data to Supabase:")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(eventData)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
        } catch {
            print("❌ Error encoding event data: \(error)")
        }
        
        do {
            // Create the request but don't execute it yet
            let request = try client
                .from("events")
                .insert(eventData)
                .select()  // Add select to return the inserted row
                
            // Print the request details
            print("🔍 Request URL: \(request)")
            
            // Execute the request
            let response = try await request.execute()
            
            print("📥 Response status: \(response.status)")
            print("📥 Raw response data:")
            if let responseString = String(data: response.data, encoding: .utf8) {
                print(responseString)
            } else {
                print("❌ Unable to decode response data as UTF8 string")
            }
            
            // Check response status
            guard response.status == 201 || response.status == 200 else {
                print("❌ Error: Unexpected response status: \(response.status)")
                throw NSError(domain: "SupabaseManager", code: response.status, userInfo: [
                    NSLocalizedDescriptionKey: "Server returned unexpected status: \(response.status)"
                ])
            }
            
            // Check if response data is empty
            guard !response.data.isEmpty else {
                print("❌ Error: Empty response data")
                throw NSError(domain: "SupabaseManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "No response data received from server"])
            }
            
            // Try to decode the response
            do {
                let events = try decoder.decode([EventResponse].self, from: response.data)
                guard let eventId = events.first?.id else {
                    print("❌ Error: No event ID in response")
                    throw NSError(domain: "SupabaseManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to get event ID"])
                }
                
                print("✅ Created event with ID: \(eventId)")
                
                // Add organizer first if they have a phone number
                if let organizerPhone = organizer.phoneNumber, !organizerPhone.isEmpty {
                    let organizerData = SupabaseAttendeeData(
                        event_id: eventId,
                        name: organizer.name,
                        email: organizer.email ?? "",
                        phone_number: organizerPhone.standardizedPhoneNumber(),
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
            is_private: false
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
    func verifyPhoneNumber(token: String, areaCode: String, middle: String, last: String, ipAddress: String) async throws -> Bool {
        let response = try await client
            .rpc("verify_invite_phone", params: [
                "p_token": token,
                "p_area_code": areaCode,
                "p_middle": middle,
                "p_last": last,
                "p_ip": ipAddress
            ])
            .execute()
        
        return try decoder.decode(Bool.self, from: response.data)
    }
} 