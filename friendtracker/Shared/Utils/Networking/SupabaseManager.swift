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
        
        // Validate required fields
        guard !hangout.title.isEmpty else {
            print("❌ Error: Empty title")
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Title is required"])
        }
        
        guard !hangout.friends.isEmpty else {
            print("❌ Error: No attendees")
            throw NSError(domain: "SupabaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "At least one attendee is required"])
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
                
                // Create a single invite token for the event that will work for everyone
                let inviteToken = try await createInvite(eventId: eventId)
                print("🎟 Created invite token for event")
                
                // Create attendees
                print("👥 Creating attendees:")
                for friend in hangout.friends {
                    let attendeeData = SupabaseAttendeeData(
                        event_id: eventId,
                        name: friend.name,
                        email: friend.email ?? "",
                        phone_number: friend.phoneNumber ?? "",
                        rsvp_status: "pending"
                    )
                    
                    print("👤 Adding attendee: \(friend.name)")
                    let attendeeResponse = try await client
                        .from("event_attendees")
                        .insert(attendeeData)
                        .select()
                        .execute()
                    
                    print("📥 Attendee response status: \(attendeeResponse.status)")
                }
                
                return (eventId: eventId, token: inviteToken)
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
            let attendeeData = SupabaseAttendeeData(
                event_id: event.id.uuidString,
                name: friend.name,
                email: friend.email ?? "",
                phone_number: friend.phoneNumber ?? "",
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
        let token = generateToken()
        let expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        
        let inviteData = InviteData(
            token: token,
            event_id: eventId,
            expires_at: expiresAt.ISO8601Format()
        )
        
        try await client
            .from("invites")
            .insert(inviteData)
            .execute()
        
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
} 