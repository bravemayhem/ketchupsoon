import SwiftUI
import SwiftData
import MessageUI

struct ManualAttendee: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var email: String
}

@MainActor
class CreateHangoutViewModel: ObservableObject {
    @Published var hangoutTitle: String = ""
    @Published var selectedDate: Date
    @Published var selectedLocation: String = ""
    @Published var selectedFriends: [Friend] = []
    @Published var selectedDuration: TimeInterval? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCalendarType: CalendarManager.CalendarType
    @Published var showingCustomDurationInput = false
    @Published var customHours: Int = 1
    @Published var customMinutes: Int = 0
    @Published var showingWishlistPrompt = false
    @Published var manualAttendees: [ManualAttendee] = []
    @Published var newManualAttendeeName: String = ""
    @Published var newManualAttendeeEmail: String = ""
    @Published var newEmail: String = ""
    @Published private var additionalEmailRecipients: [String] = []
    
    // Dictionary to store temporary email addresses for friends
    @Published private var tempEmailAddresses: [Friend.ID: String] = [:]
    
    // Dictionary to store selected email addresses for friends
    @Published private var selectedEmailAddresses: [Friend.ID: String] = [:]
    
    // Dictionary to store custom email addresses for friends
    @Published private var customEmailAddresses: [Friend.ID: String] = [:]
    
    let calendarManager: CalendarManager
    private let modelContext: ModelContext
    
    var isScheduleButtonDisabled: Bool {
        hangoutTitle.isEmpty || selectedFriends.isEmpty
    }
    
    var emailRecipients: [String] {
        let friendEmails = selectedFriends.compactMap { friend -> String? in
            if let customEmail = customEmailAddresses[friend.id] {
                return customEmail
            }
            if let selectedEmail = selectedEmailAddresses[friend.id] {
                return selectedEmail
            }
            return friend.email
        }
        let manualEmails = manualAttendees.map(\.email)
        return friendEmails + manualEmails
    }
    
    // MARK: - Email Editing Functions
    
    func startEditingEmail(for friend: Friend) {
        tempEmailAddresses[friend.id] = ""
        objectWillChange.send()
    }
    
    func cancelEditingEmail(for friend: Friend) {
        tempEmailAddresses.removeValue(forKey: friend.id)
        objectWillChange.send()
    }
    
    func saveEmail(for friend: Friend) {
        if let email = tempEmailAddresses[friend.id], isValidEmail(email) {
            friend.email = email
            tempEmailAddresses.removeValue(forKey: friend.id)
            objectWillChange.send()
        }
    }
    
    func emailBinding(for friend: Friend) -> Binding<String> {
        Binding(
            get: { self.tempEmailAddresses[friend.id] ?? "" },
            set: { self.tempEmailAddresses[friend.id] = $0 }
        )
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // Add a computed property to access tempEmail for a friend
    func tempEmail(for friend: Friend) -> String? {
        return tempEmailAddresses[friend.id]
    }
    
    func addEmailRecipient(_ email: String) {
        guard !additionalEmailRecipients.contains(email) else { return }
        additionalEmailRecipients.append(email)
    }
    
    func removeEmailRecipient(_ email: String) {
        additionalEmailRecipients.removeAll { $0 == email }
    }
    
    func addManualAttendee(name: String, email: String) {
        guard !email.isEmpty && email.contains("@") else { return }
        let attendee = ManualAttendee(name: name, email: email)
        manualAttendees.append(attendee)
        newManualAttendeeName = ""
        newManualAttendeeEmail = ""
    }
    
    func removeManualAttendee(_ attendee: ManualAttendee) {
        manualAttendees.removeAll { $0.id == attendee.id }
    }
    
    func removeFriend(_ friend: Friend) {
        selectedFriends.removeAll { $0.id == friend.id }
        // Also clean up any temporary email if it exists
        tempEmailAddresses.removeValue(forKey: friend.id)
    }
    
    func getSelectedEmail(for friend: Friend) -> String? {
        if let customEmail = customEmailAddresses[friend.id] {
            return customEmail
        }
        return selectedEmailAddresses[friend.id] ?? friend.email
    }
    
    func setSelectedEmail(_ email: String, for friend: Friend) {
        selectedEmailAddresses[friend.id] = email
        // Clear any custom email when selecting an existing one
        customEmailAddresses.removeValue(forKey: friend.id)
        objectWillChange.send()
    }
    
    func setCustomEmail(_ email: String, for friend: Friend) {
        if isValidEmail(email) {
            customEmailAddresses[friend.id] = email
            // Clear any selected email when using a custom one
            selectedEmailAddresses.removeValue(forKey: friend.id)
            objectWillChange.send()
        }
    }
    
    func clearCustomEmail(for friend: Friend) {
        customEmailAddresses.removeValue(forKey: friend.id)
        objectWillChange.send()
    }
    
    @Published var showingMessageSheet = false
    @Published var messageRecipient: String?
    @Published var messageBody: String?
    
    @Published var webLink: String?
    @Published var isCreatingEvent = false
    
    private var pendingEventLink: String?
    
    @Published var isTestingConnection = false
    @Published var connectionTestResult: String?
    
    init(modelContext: ModelContext,
         initialDate: Date? = nil,
         initialLocation: String? = nil,
         initialTitle: String? = nil,
         initialSelectedFriends: [Friend]? = nil) {
        self.modelContext = modelContext
        self.selectedDate = initialDate ?? Date()
        self.selectedLocation = initialLocation ?? ""
        self.hangoutTitle = initialTitle ?? ""
        self.selectedFriends = initialSelectedFriends ?? []
        self.calendarManager = CalendarManager.shared
        self.selectedCalendarType = .apple
    }

    private func saveHangout(_ hangout: Hangout) throws {
        modelContext.insert(hangout)
        try modelContext.save()
    }

    func createHangout() async {
        print("🚀 Starting hangout creation...")
        isCreatingEvent = true
        defer { isCreatingEvent = false }
        
        do {
            // Validate required fields
            guard !hangoutTitle.isEmpty else {
                print("❌ Error: Empty title")
                errorMessage = "Please enter a title for the hangout"
                return
            }
            
            guard !selectedFriends.isEmpty else {
                print("❌ Error: No friends selected")
                errorMessage = "Please select at least one friend"
                return
            }
            
            print("✅ Validation passed")
            print("📝 Title: \(hangoutTitle)")
            print("👥 Selected friends: \(selectedFriends.map { $0.name }.joined(separator: ", "))")
            print("📅 Date: \(selectedDate)")
            print("📍 Location: \(selectedLocation)")
            print("⏱ Duration: \(selectedDuration?.description ?? "default (1 hour)")")
            
            // Test Supabase connection first
            do {
                print("🔄 Testing Supabase connection...")
                _ = try await SupabaseManager.shared.testConnection()
                print("✅ Supabase connection successful")
            } catch {
                print("❌ Supabase connection failed: \(error)")
                errorMessage = "Unable to connect to server: \(error.localizedDescription)"
                return
            }
            
            print("📦 Creating local hangout...")
            let hangout = Hangout(
                date: selectedDate,
                title: hangoutTitle,
                location: selectedLocation,
                isScheduled: true,
                friends: selectedFriends,
                duration: selectedDuration ?? 3600
            )
            
            // Save to local database
            print("💾 Saving to local database...")
            try saveHangout(hangout)
            print("✅ Saved to local database")
            
            // Save to Supabase and get web link
            print("☁️ Saving to Supabase...")
            if let result = try await SupabaseManager.shared.createEvent(hangout) {
                print("✅ Saved to Supabase with ID: \(result.eventId)")
                webLink = SupabaseManager.shared.getWebLink(for: result.eventId, withToken: result.token)
                print("🔗 Generated web link: \(webLink ?? "nil")")
                
                // Store the event link and token with the hangout
                hangout.eventLink = webLink
                hangout.eventToken = result.token
                // Save the event link for the creator
                let creatorLink = webLink
                
                // Show message sheet with web link for attendees
                messageRecipient = selectedFriends.first?.phoneNumber ?? manualAttendees.first?.email
                messageBody = """
                Join me for \(hangoutTitle)!
                When: \(formatDate(selectedDate))
                \(selectedLocation.isEmpty ? "" : "Where: \(selectedLocation)\n")View event details and RSVP: \(webLink ?? "")
                """
                showingMessageSheet = true
                print("📱 Showing message sheet")
                
                // Show confirmation with creator's link
                print("🔗 Creator's event link: \(creatorLink ?? "")")
                print("ℹ️ Save this link to view your event later")
            }
        } catch {
            print("❌ Error in createHangout: \(error)")
            errorMessage = "Failed to create event: \(error.localizedDescription)"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func scheduleHangout() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Ensure calendar access is granted
            await calendarManager.ensureInitialized()
            
            // Check if we have calendar access
            if selectedCalendarType == .apple && !calendarManager.isAuthorized {
                errorMessage = "Apple Calendar access is required. Please grant access in Settings."
                isLoading = false
                return
            }
            
            if selectedCalendarType == .google && !calendarManager.isGoogleAuthorized {
                errorMessage = "Google Calendar access is required. Please sign in with Google."
                isLoading = false
                return
            }
            
            calendarManager.selectedCalendarType = selectedCalendarType
            await createHangout()
            
            // Save the model context
            try modelContext.save()
            
            isLoading = false
            
            let wishlistFriends = selectedFriends.filter(\.needsToConnectFlag)
            if !wishlistFriends.isEmpty {
                showingWishlistPrompt = true
            }
        } catch {
            print("Error scheduling hangout: \(error)")
            errorMessage = "Failed to schedule hangout: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func removeFromWishlist() {
        for friend in selectedFriends {
            friend.needsToConnectFlag = false
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        if minutes == 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
    
    func testSupabaseConnection() async {
        isTestingConnection = true
        connectionTestResult = nil
        
        do {
            _ = try await SupabaseManager.shared.testConnection()
            connectionTestResult = "✅ Successfully connected to Supabase!"
        } catch {
            connectionTestResult = "❌ Connection failed: \(error.localizedDescription)"
        }
        
        isTestingConnection = false
    }
} 