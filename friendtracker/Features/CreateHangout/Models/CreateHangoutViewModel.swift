import SwiftUI
import SwiftData

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
    @Published var newEmail: String = ""
    @Published private var additionalEmailRecipients: [String] = []
    
    let calendarManager: CalendarManager
    private let modelContext: ModelContext
    
    var isScheduleButtonDisabled: Bool {
        hangoutTitle.isEmpty || selectedFriends.isEmpty
    }
    
    var emailRecipients: [String] {
        let friendEmails = selectedFriends.compactMap { (friend: Friend) -> String? in
            guard let email = friend.email, !email.isEmpty else { return nil }
            return email
        }
        return friendEmails + additionalEmailRecipients
    }
    
    func addEmailRecipient(_ email: String) {
        guard !additionalEmailRecipients.contains(email) else { return }
        additionalEmailRecipients.append(email)
    }
    
    func removeEmailRecipient(_ email: String) {
        additionalEmailRecipients.removeAll { $0 == email }
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
        _ = try await calendarManager.createHangoutEvent(
            activity: hangoutTitle,
            location: selectedLocation,
            date: selectedDate,
            duration: selectedDuration ?? 7200,
            emailRecipients: emailRecipients,
            attendeeNames: selectedFriends.map(\.name)
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
            calendarManager.selectedCalendarType = selectedCalendarType
            try await createHangout()
            isLoading = false
            
            let wishlistFriends = selectedFriends.filter(\.needsToConnectFlag)
            if !wishlistFriends.isEmpty {
                showingWishlistPrompt = true
            }
        } catch {
            errorMessage = error.localizedDescription
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