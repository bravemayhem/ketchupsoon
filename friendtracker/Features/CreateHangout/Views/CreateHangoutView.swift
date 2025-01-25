import SwiftUI
import SwiftData

// MARK: - Friend Section
private struct FriendSection: View {
    let friendName: String
    
    var body: some View {
        Section("Friend") {
            Text(friendName)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Email Recipients Section
private struct EmailRecipientsSection: View {
    @Binding var emailRecipients: [String]
    @Binding var newEmail: String
    
    var body: some View {
        Section("Email Recipients") {
            ForEach(emailRecipients, id: \.self) { email in
                HStack {
                    Text(email)
                    Spacer()
                    Button(action: {
                        emailRecipients.removeAll { $0 == email }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            
            HStack {
                TextField("Add email", text: $newEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                Button(action: {
                    if !newEmail.isEmpty && newEmail.contains("@") {
                        emailRecipients.append(newEmail)
                        newEmail = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Date Time Section
private struct DateTimeSection: View {
    @Binding var selectedDate: Date
    @Binding var selectedCalendarType: CalendarManager.CalendarType
    @Binding var selectedDuration: TimeInterval?
    @Binding var showingCustomDurationInput: Bool
    @Binding var errorMessage: String?
    @StateObject var calendarManager: CalendarManager
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        if minutes == 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
    
    var body: some View {
        Section("Date & Time") {
            DatePicker(
                "Date",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            
            Picker("Calendar", selection: $selectedCalendarType) {
                Text("Apple Calendar").tag(CalendarManager.CalendarType.apple)
                Text("Google Calendar").tag(CalendarManager.CalendarType.google)
            }
            
            if selectedCalendarType == .google && !calendarManager.isGoogleAuthorized {
                Button(action: {
                    Task {
                        do {
                            try await calendarManager.requestGoogleAccess()
                        } catch {
                            errorMessage = "Failed to connect: \(error.localizedDescription)"
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "g.circle.fill")
                            .foregroundColor(.blue)
                        Text("Sign in with Google")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                }
            }
            
            if let duration = selectedDuration {
                HStack {
                    Text("Duration")
                    Spacer()
                    Button(formatDuration(duration)) {
                        showingCustomDurationInput = true
                    }
                    .foregroundColor(.blue)
                }
            } else {
                Button("Set Duration (Optional)") {
                    showingCustomDurationInput = true
                }
                .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Schedule Button Section
private struct ScheduleButtonSection: View {
    let isLoading: Bool
    let errorMessage: String?
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Section {
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.callout)
            }
            
            Button(action: action) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                } else {
                    Text("Schedule Hangout")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isDisabled ? Color.gray : Color.blue)
            )
            .disabled(isDisabled || isLoading)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
}

// MARK: - Custom Duration Input View
private struct CustomDurationInputView: View {
    @Binding var customHours: Int
    @Binding var customMinutes: Int
    @Binding var showingCustomDurationInput: Bool
    @Binding var selectedDuration: TimeInterval?
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        if minutes == 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Hours: \(customHours)", value: $customHours, in: 0...12)
                    Stepper("Minutes: \(customMinutes)", value: $customMinutes, in: 0...59)
                    
                    Text("Total Duration: \(formatDuration(TimeInterval(customHours * 3600 + customMinutes * 60)))")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Custom Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCustomDurationInput = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set") {
                        let duration = TimeInterval(customHours * 3600 + customMinutes * 60)
                        selectedDuration = duration
                        showingCustomDurationInput = false
                    }
                    .disabled(customHours == 0 && customMinutes == 0)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - CreateHangoutView
struct CreateHangoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let friend: Friend
    let initialDate: Date?
    
    @State private var hangoutTitle: String = ""
    @State private var selectedDate: Date
    @State private var selectedLocation = ""
    @State private var emailRecipients: [String] = []
    @State private var newEmail: String = ""
    @StateObject private var calendarManager = CalendarManager()
    @State private var selectedDuration: TimeInterval? = nil
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedCalendarType: CalendarManager.CalendarType = .apple
    @State private var showingCustomDurationInput = false
    @State private var customHours: Int = 1
    @State private var customMinutes: Int = 0
    @State private var showingWishlistPrompt = false
    
    init(friend: Friend, initialDate: Date? = nil) {
        self.friend = friend
        self.initialDate = initialDate
        _selectedDate = State(initialValue: initialDate ?? Date())
        if let friendEmail = friend.email {
            _emailRecipients = State(initialValue: [friendEmail])
        }
        
        // Configure UIDatePicker to snap to 5-minute intervals
        UIDatePicker.appearance().minuteInterval = 5
    }
    
    private var isScheduleButtonDisabled: Bool {
        hangoutTitle.isEmpty
    }
    
    private func createHangout() async throws {
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
    
    private func handleScheduleCompletion() {
        if friend.needsToConnectFlag {
            showingWishlistPrompt = true
        } else {
            dismiss()
        }
    }
    
    private func scheduleHangout() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                calendarManager.selectedCalendarType = selectedCalendarType
                try await createHangout()
                
                await MainActor.run {
                    isLoading = false
                    handleScheduleCompletion()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                FriendSection(friendName: friend.name)
                
                Section("Hangout Title") {
                    TextField("Enter title", text: $hangoutTitle)
                }
                
                EmailRecipientsSection(
                    emailRecipients: $emailRecipients,
                    newEmail: $newEmail
                )
                
                DateTimeSection(
                    selectedDate: $selectedDate,
                    selectedCalendarType: $selectedCalendarType,
                    selectedDuration: $selectedDuration,
                    showingCustomDurationInput: $showingCustomDurationInput,
                    errorMessage: $errorMessage,
                    calendarManager: calendarManager
                )
                
                Section("Location") {
                    TextField("Enter location", text: $selectedLocation)
                }
                
                ScheduleButtonSection(
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    isDisabled: isScheduleButtonDisabled,
                    action: scheduleHangout
                )
            }
            .navigationTitle("Create Hangout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCustomDurationInput) {
                CustomDurationInputView(
                    customHours: $customHours,
                    customMinutes: $customMinutes,
                    showingCustomDurationInput: $showingCustomDurationInput,
                    selectedDuration: $selectedDuration
                )
            }
        }
        .alert("Remove from Wishlist?", isPresented: $showingWishlistPrompt) {
            Button("Keep on Wishlist") {
                dismiss()
            }
            Button("Remove from Wishlist") {
                friend.needsToConnectFlag = false
                dismiss()
            }
        } message: {
            Text("You've scheduled time with \(friend.name). Would you like to remove them from your wishlist?")
        }
    }
}

#Preview {
    CreateHangoutView(friend: Friend(name: "Test Friend"))
        .modelContainer(for: [Friend.self, Hangout.self], inMemory: true)
}
