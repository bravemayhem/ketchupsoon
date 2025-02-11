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
    func createEvent(_ event: Hangout) async throws -> String? {
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
        
        let response = try await client
            .from("events")
            .insert(eventData)
            .execute()
        
        // Get the ID of the created event
        let events = try decoder.decode([EventResponse].self, from: response.data)
        guard let eventId = events.first?.id else {
            return nil
        }
        
        // Create attendees
        for friend in event.friends {
            let attendeeData = SupabaseAttendeeData(
                event_id: eventId,
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
        
        return eventId
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
    func getWebLink(for eventId: String) -> String {
        guard let supabaseUrl = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String else {
            return "https://disauoaajnfvntvxnxph.supabase.co/hangout/\(eventId)"
        }
        return "\(supabaseUrl)/hangout/\(eventId)"
    }
    
    // Test connection to Supabase
    func testConnection() async throws -> Bool {
        do {
            let response = try await client
                .from("events")
                .select("id")
                .limit(1)
                .execute()
            
            // Try to decode the response to verify data structure
            _ = try decoder.decode([EventResponse].self, from: response.data)
            
            print("✅ Supabase connection successful!")
            return true
        } catch {
            print("❌ Supabase connection failed: \(error)")
            throw error
        }
    }
} 