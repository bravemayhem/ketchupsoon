import SwiftUI
import SwiftData

struct SchedulerView: View {
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
    
    enum CalendarType {
        case apple, google
    }
    
    let availableDurations = [
        ("30 min", 1800.0),
        ("1 hour", 3600.0),
        ("1.5 hours", 5400.0),
        ("2 hours", 7200.0),
        ("Custom", -1.0)
    ]
    
    init(friend: Friend, initialDate: Date? = nil) {
        self.friend = friend
        self.initialDate = initialDate
        _selectedDate = State(initialValue: initialDate ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Friend Display
                Section("Friend") {
                    Text(friend.name)
                        .foregroundColor(.primary)
                }
                
                // Hangout Title
                Section("Hangout Title") {
                    TextField("Enter title", text: $hangoutTitle)
                }
                
                // Email Recipients
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
                
                // Date and Time
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
                
                // Location
                Section("Location") {
                    TextField("Enter location", text: $selectedLocation)
                }
                
                // Schedule Button
                Section {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                    
                    Button(action: scheduleHangout) {
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
                            .fill(isScheduleButtonDisabled ? Color.gray : Color.blue)
                    )
                    .disabled(isScheduleButtonDisabled || isLoading)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Schedule Hangout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCustomDurationInput) {
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
    
    private var isScheduleButtonDisabled: Bool {
        hangoutTitle.isEmpty
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        if minutes == 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
    
    private func createHangout() async throws {
        // Create calendar event
        _ = try await calendarManager.createHangoutEvent(
            with: friend,
            activity: hangoutTitle,
            location: selectedLocation,
            date: selectedDate,
            duration: selectedDuration ?? 7200, // Default 2 hours
            emailRecipients: emailRecipients
        )
        
        // Create and insert the hangout
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
}

#Preview {
    SchedulerView(friend: Friend(name: "Test Friend"))
        .modelContainer(for: [Friend.self, Hangout.self])
}
