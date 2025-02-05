import SwiftUI
import SwiftData

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
    
    init(modelContext: ModelContext, initialDate: Date? = nil, initialLocation: String? = nil, initialTitle: String? = nil, initialSelectedFriends: [Friend]? = nil) {
        self.modelContext = modelContext
        self.calendarManager = CalendarManager.shared
        
        let defaultType = UserDefaults.standard.string(forKey: "defaultCalendarType") ?? Friend.CalendarType.apple.rawValue
        let calendarType = Friend.CalendarType(rawValue: defaultType) ?? .apple
        self._selectedCalendarType = Published(initialValue: calendarType == .apple ? .apple : .google)
        
        self._selectedDate = Published(initialValue: initialDate ?? Date())
        self._selectedLocation = Published(initialValue: initialLocation ?? "")
        self._hangoutTitle = Published(initialValue: initialTitle?.replacingOccurrences(of: " with .*$", with: "", options: .regularExpression) ?? "")
        self._selectedFriends = Published(initialValue: initialSelectedFriends ?? [])
    }
    
    func createHangout() async throws {
        // Create a single calendar event with all friends as attendees
        let allAttendeeNames = selectedFriends.map(\.name) + manualAttendees.map(\.name)
        
        _ = try await calendarManager.createHangoutEvent(
            activity: hangoutTitle,
            location: selectedLocation,
            date: selectedDate,
            duration: selectedDuration ?? 7200,
            emailRecipients: emailRecipients,
            attendeeNames: allAttendeeNames
        )
        
        // Create a single Hangout record with all friends
        let hangout = Hangout(
            date: selectedDate,
            activity: hangoutTitle,
            location: selectedLocation,
            isScheduled: true,
            friends: selectedFriends,
            duration: selectedDuration ?? 7200
        )
        modelContext.insert(hangout)
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
            try await createHangout()
            
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
} 