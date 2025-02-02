import SwiftUI
import SwiftData

@MainActor
class CreateHangoutViewModel: ObservableObject {
    @Published var hangoutTitle: String = ""
    @Published var selectedDate: Date
    @Published var selectedLocation: String = ""
    @Published var emailRecipients: [String] = []
    @Published var newEmail: String = ""
    @Published var selectedDuration: TimeInterval? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCalendarType: CalendarManager.CalendarType
    @Published var showingCustomDurationInput = false
    @Published var customHours: Int = 1
    @Published var customMinutes: Int = 0
    @Published var showingWishlistPrompt = false
    
    let friend: Friend
    let calendarManager: CalendarManager
    private let modelContext: ModelContext
    
    var isScheduleButtonDisabled: Bool {
        hangoutTitle.isEmpty
    }
    
    init(friend: Friend, modelContext: ModelContext, initialDate: Date? = nil, initialLocation: String? = nil, initialTitle: String? = nil) {
        self.friend = friend
        self.modelContext = modelContext
        self.calendarManager = CalendarManager.shared
        
        let defaultType = UserDefaults.standard.string(forKey: "defaultCalendarType") ?? Friend.CalendarType.apple.rawValue
        let calendarType = Friend.CalendarType(rawValue: defaultType) ?? .apple
        self._selectedCalendarType = Published(initialValue: calendarType == .apple ? .apple : .google)
        
        self._selectedDate = Published(initialValue: initialDate ?? Date())
        self._selectedLocation = Published(initialValue: initialLocation ?? "")
        self._hangoutTitle = Published(initialValue: initialTitle?.replacingOccurrences(of: " with .*$", with: "", options: .regularExpression) ?? "")
        
        if let friendEmail = friend.email {
            self._emailRecipients = Published(initialValue: [friendEmail])
        }
    }
    
    func createHangout() async throws {
        _ = try await calendarManager.createHangoutEvent(
            with: friend,
            activity: hangoutTitle,
            location: selectedLocation,
            date: selectedDate,
            duration: selectedDuration ?? 7200,
            emailRecipients: emailRecipients
        )
        
        let hangout = Hangout(
            date: selectedDate,
            activity: hangoutTitle,
            location: selectedLocation,
            isScheduled: true,
            friend: friend,
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
            
            if friend.needsToConnectFlag {
                showingWishlistPrompt = true
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func removeFromWishlist() {
        friend.needsToConnectFlag = false
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