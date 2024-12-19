import SwiftUI
import SwiftData

struct SchedulerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedFriend: Friend?
    @State private var selectedActivity: String = SampleData.activities[0]
    @State private var selectedDate = Date()
    @State private var selectedLocation = ""
    @Query(sort: [SortDescriptor(\Friend.name)]) private var friends: [Friend]
    @StateObject private var calendarManager = CalendarManager()
    @State private var selectedDuration: TimeInterval? = nil // nil means use default
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var suggestedTimes: [Date] = []
    @State private var showingSuggestedTimes = false
    @State private var showingDurationPicker = false
    @State private var selectedCalendarType: CalendarType = .apple
    @State private var showingCustomDurationInput = false
    @State private var customHours: Int = 1
    @State private var customMinutes: Int = 0
    
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
    
    init(initialFriend: Friend? = nil) {
        _selectedFriend = State(initialValue: initialFriend)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Friend Selection
                Section("Friend") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(friends) { friend in
                                SelectableButton(
                                    title: friend.name,
                                    isSelected: selectedFriend?.id == friend.id,
                                    action: { selectedFriend = friend }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // Activity Selection
                Section("Activity") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SampleData.activities, id: \.self) { activity in
                                SelectableButton(
                                    title: activity,
                                    isSelected: selectedActivity == activity,
                                    action: { selectedActivity = activity }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
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
                        Text("Apple Calendar").tag(CalendarType.apple)
                        Text("Google Calendar").tag(CalendarType.google)
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
                                showingDurationPicker = true
                            }
                            .foregroundColor(.blue)
                        }
                    } else {
                        Button("Set Duration (Optional)") {
                            showingDurationPicker = true
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
            .sheet(isPresented: $showingSuggestedTimes) {
                NavigationStack {
                    List(suggestedTimes, id: \.self) { time in
                        Button(action: {
                            selectedDate = time
                            showingSuggestedTimes = false
                        }) {
                            Text(time.formatted(date: .complete, time: .shortened))
                        }
                    }
                    .navigationTitle("Suggested Times")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingSuggestedTimes = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingDurationPicker) {
                NavigationStack {
                    List {
                        ForEach(availableDurations, id: \.1) { duration in
                            Button(action: {
                                if duration.1 == -1 {
                                    showingCustomDurationInput = true
                                } else {
                                    selectedDuration = duration.1
                                    showingDurationPicker = false
                                }
                            }) {
                                HStack {
                                    Text(duration.0)
                                    Spacer()
                                    if let selected = selectedDuration, selected == duration.1 {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Select Duration")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Clear") {
                                selectedDuration = nil
                                showingDurationPicker = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingDurationPicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
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
                                showingDurationPicker = false
                            }
                            .disabled(customHours == 0 && customMinutes == 0)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    private var isScheduleButtonDisabled: Bool {
        selectedFriend == nil
    }
    
    private func findAvailableTimes() async {
        guard let friend = selectedFriend else { return }
        isLoading = true
        errorMessage = nil
        
        // Use default duration of 2 hours if none selected
        let duration = selectedDuration ?? 7200
        
        // Get suggested times considering both users' calendars
        let times = await calendarManager.suggestAvailableTimeSlots(
            with: [friend],
            duration: duration,
            limit: 5
        )
        
        await MainActor.run {
            suggestedTimes = times
            showingSuggestedTimes = true
            isLoading = false
        }
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
    
    private func scheduleHangout() {
        guard let friend = selectedFriend else { return }
        isLoading = true
        errorMessage = nil
        
        // Use default duration of 2 hours if none selected
        let duration = selectedDuration ?? 7200
        
        Task {
            do {
                // First, check if the time slot is available
                await calendarManager.fetchBusyTimeSlots(for: selectedDate, friends: [friend])
                guard calendarManager.isTimeSlotAvailable(selectedDate, duration: duration) else {
                    errorMessage = "This time slot is not available. Please select another time."
                    isLoading = false
                    return
                }
                
                // Create the calendar event based on selected calendar type
                if selectedCalendarType == .google && calendarManager.isGoogleAuthorized {
                    // Use Google Calendar
                    // TODO: Implement Google Calendar event creation
                } else {
                    // Use Apple Calendar
                    _ = try await calendarManager.createHangoutEvent(
                        with: friend,
                        activity: selectedActivity,
                        location: selectedLocation,
                        date: selectedDate,
                        duration: duration
                    )
                }
                
                // Create and insert the hangout
                let hangout = Hangout(
                    date: selectedDate,
                    activity: selectedActivity,
                    location: selectedLocation,
                    isScheduled: true,
                    duration: duration / 60, // Convert seconds to minutes
                    friend: friend
                )
                modelContext.insert(hangout)
                
                // Only remove from To Connect list, but don't update last seen
                friend.needsToConnectFlag = false
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
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

private struct SelectableButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.blue : Color.primary, lineWidth: 1)
                        )
                )
        }
    }
}

#Preview {
    SchedulerView()
        .modelContainer(for: Friend.self)
}
