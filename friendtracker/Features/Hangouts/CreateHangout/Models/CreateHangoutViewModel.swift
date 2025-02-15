import SwiftUI
import SwiftData
import MessageUI

struct ManualAttendee: Identifiable, Equatable, Codable {
    var id = UUID()
    var name: String
    var email: String
    
    init(id: UUID = UUID(), name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
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
    private var modelContext: ModelContext
    
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
        // Use the default calendar type from AppStorage
        let defaultType = UserDefaults.standard.string(forKey: "defaultCalendarType") ?? "apple"
        self.selectedCalendarType = defaultType == "google" ? .google : .apple
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
            
            // Create calendar event
            print("📅 Creating calendar event...")
            let attendeeNames = selectedFriends.map { $0.name }
            let calendarResult = try await calendarManager.createHangoutEvent(
                activity: hangoutTitle,
                location: selectedLocation,
                date: selectedDate,
                duration: selectedDuration ?? 3600,
                emailRecipients: emailRecipients,
                attendeeNames: attendeeNames
            )
            print("✅ Calendar event created with ID: \(calendarResult.eventId)")
            
            // Store Google Calendar specific information
            var googleEventLink: String? = nil
            if calendarResult.isGoogleEvent {
                googleEventLink = calendarResult.htmlLink
                print("🔗 Google Calendar event link: \(googleEventLink ?? "nil")")
                hangout.googleEventId = calendarResult.googleEventId
                hangout.googleEventLink = googleEventLink
            }
            
            // Save to Supabase and get web link
            print("☁️ Saving to Supabase...")
            if let result = try await SupabaseManager.shared.createEvent(hangout) {
                print("✅ Saved to Supabase with ID: \(result.eventId)")
                webLink = SupabaseManager.shared.getWebLink(for: result.eventId, withToken: result.token)
                print("🔗 Generated web link: \(webLink ?? "nil")")
                
                // Store the event link and token with the hangout
                hangout.eventLink = webLink
                hangout.eventToken = result.token
                
                // Save the updated hangout with all links
                try modelContext.save()
                print("✅ Saved hangout with all event links")
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
            print("🗓 Starting hangout scheduling...")
            print("📅 Selected calendar type: \(calendarManager.selectedCalendarType)")
            print("🔐 Calendar access state:")
            print("   - Apple Calendar authorized: \(calendarManager.isAuthorized)")
            print("   - Google Calendar authorized: \(calendarManager.isGoogleAuthorized)")
            print("   - Has selected calendar access: \(calendarManager.hasSelectedCalendarAccess)")
            
            // Ensure calendar access is granted
            await calendarManager.ensureInitialized()
            print("✅ Calendar manager initialized")
            
            // Set the calendar type first
            calendarManager.selectedCalendarType = selectedCalendarType
            print("📅 Set selected calendar type to: \(selectedCalendarType)")
            
            // Check if we have access to the selected calendar type
            if !calendarManager.hasSelectedCalendarAccess {
                print("❌ No access to selected calendar type")
                print("   - Selected type: \(calendarManager.selectedCalendarType)")
                print("   - Apple access: \(calendarManager.isAuthorized)")
                print("   - Google access: \(calendarManager.isGoogleAuthorized)")
                errorMessage = "\(calendarManager.selectedCalendarType == .apple ? "Apple" : "Google") Calendar access is required. Please grant access in Settings."
                isLoading = false
                return
            }
            
            print("✅ Calendar access verified")
            print("📅 Creating hangout...")
            await createHangout()
            
            // Save the model context
            try modelContext.save()
            print("✅ Model context saved")
            
            isLoading = false
            
            let wishlistFriends = selectedFriends.filter(\.needsToConnectFlag)
            if !wishlistFriends.isEmpty {
                showingWishlistPrompt = true
            }
        } catch {
            print("❌ Error scheduling hangout: \(error)")
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
    
    // Update the model context
    func updateModelContext(_ newContext: ModelContext) {
        modelContext = newContext
    }
} 
