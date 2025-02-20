import SwiftUI
import SwiftData
import MessageUI
import EventKit

@MainActor
class CreateHangoutViewModel: ObservableObject {
    @Published var hangoutTitle: String = ""
    @Published var selectedDate: Date
    @Published var selectedLocation: String = ""
    @Published var selectedFriends: [Friend] = []
    @Published var selectedDuration: TimeInterval? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCalendarType: CalendarType
    @Published var showingCustomDurationInput = false
    @Published var customHours: Int = 1
    @Published var customMinutes: Int = 0
    @Published var showingWishlistPrompt = false
    @Published var newEmail: String = ""
    @Published private var additionalEmailRecipients: [String] = []
    
    // Dictionary to store temporary email addresses for friends
    @Published private var tempEmailAddresses: [Friend.ID: String] = [:]
    
    // Dictionary to store selected email addresses for friends
    @Published private var selectedEmailAddresses: [Friend.ID: String] = [:]
    
    let calendarManager: CalendarManager
    private var modelContext: ModelContext
    
    var isScheduleButtonDisabled: Bool {
        hangoutTitle.isEmpty || 
        selectedFriends.isEmpty || 
        selectedFriends.contains { friend in
            let hasSelectedEmail = selectedEmailAddresses[friend.id] != nil
            let hasPrimaryEmail = friend.email?.isEmpty == false
            return !hasSelectedEmail && !hasPrimaryEmail
        }
    }
    
    var emailRecipients: [String] {
        let friendEmails = selectedFriends.compactMap { friend -> String? in
            if let selectedEmail = selectedEmailAddresses[friend.id] {
                return selectedEmail
            }
            return friend.email
        }
        return friendEmails
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
        guard !email.isEmpty && email.contains("@") else { return }
        additionalEmailRecipients.append(email)
        newEmail = ""
    }
    
    func removeEmailRecipient(_ email: String) {
        additionalEmailRecipients.removeAll { $0 == email }
    }
    
    func removeFriend(_ friend: Friend) {
        selectedFriends.removeAll { $0.id == friend.id }
        // Also clean up any temporary email if it exists
        tempEmailAddresses.removeValue(forKey: friend.id)
    }
    
    func getSelectedEmail(for friend: Friend) -> String? {
        return selectedEmailAddresses[friend.id] ?? friend.email
    }
    
    func setSelectedEmail(_ email: String, for friend: Friend) {
        selectedEmailAddresses[friend.id] = email
        objectWillChange.send()
    }
    
    @Published var showingMessageSheet = false
    @Published var messageRecipient: String?
    @Published var messageBody: String?
    
    @Published var webLink: String?
    @Published var isCreatingEvent = false
    
    private var pendingEventLink: String?
    
    init(modelContext: ModelContext, initialDate: Date? = nil, initialLocation: String? = nil, initialTitle: String? = nil, initialSelectedFriends: [Friend]? = nil) {
        self.modelContext = modelContext
        self.selectedDate = initialDate ?? Date().addingTimeInterval(3600)
        self.selectedLocation = initialLocation ?? ""
        self.hangoutTitle = initialTitle ?? ""
        self.selectedFriends = initialSelectedFriends ?? []
        self.calendarManager = CalendarManager.shared
        self.selectedCalendarType = calendarManager.selectedCalendarType
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
            let calendarResult = try await calendarManager.createHangoutEvent(
                activity: hangoutTitle,
                location: selectedLocation,
                date: selectedDate,
                duration: selectedDuration ?? 3600,
                emailRecipients: emailRecipients
            )
            print("✅ Calendar event created with ID: \(calendarResult.eventId)")
            
            // Store Google Calendar specific information
            if calendarResult.isGoogleEvent {
                hangout.googleEventId = calendarResult.googleEventId
                hangout.googleEventLink = calendarResult.htmlLink
                print("🔗 Google Calendar event link: \(calendarResult.htmlLink ?? "nil")")
            }
            
            // Save the final state
            try modelContext.save()
            print("✅ Final save completed")
            
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
    
    // Update the model context
    func updateModelContext(_ newContext: ModelContext) {
        modelContext = newContext
    }
} 
