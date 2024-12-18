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
    @State private var selectedDuration: TimeInterval = 3600 // 1 hour default
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let availableDurations = [
        ("30 min", 1800.0),
        ("1 hour", 3600.0),
        ("1.5 hours", 5400.0),
        ("2 hours", 7200.0)
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
                    
                    Picker("Duration", selection: $selectedDuration) {
                        ForEach(availableDurations, id: \.1) { duration in
                            Text(duration.0).tag(duration.1)
                        }
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
        }
    }
    
    private var isScheduleButtonDisabled: Bool {
        selectedFriend == nil
    }
    
    private func scheduleHangout() {
        guard let friend = selectedFriend else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // First, check if the time slot is available
                await calendarManager.fetchBusyTimeSlots(for: selectedDate)
                guard calendarManager.isTimeSlotAvailable(selectedDate, duration: selectedDuration) else {
                    errorMessage = "This time slot is not available. Please select another time."
                    isLoading = false
                    return
                }
                
                // Create the calendar event
                _ = try await calendarManager.createHangoutEvent(
                    with: friend,
                    activity: selectedActivity,
                    location: selectedLocation,
                    date: selectedDate,
                    duration: selectedDuration
                )
                
                // Create and insert the hangout
                let hangout = Hangout(
                    date: selectedDate,
                    activity: selectedActivity,
                    location: selectedLocation,
                    isScheduled: true,
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
