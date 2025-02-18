import SwiftUI
import SwiftData

// MARK: - Header View
private struct HangoutHeaderView: View {
    let title: String
    let isRescheduled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title)
                .bold()
                .foregroundColor(AppColors.label)
            
            if isRescheduled {
                Text("Rescheduled")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

// MARK: - Time and Location View
private struct TimeLocationView: View {
    let date: Date
    let endDate: Date
    let location: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Time
            HStack(spacing: 16) {
                Image(systemName: "clock.fill")
                    .foregroundColor(AppColors.accent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(date))
                        .font(.headline)
                    if Calendar.current.compare(date, to: endDate, toGranularity: .minute) != .orderedSame {
                        Text("\(formatTime(date)) - \(formatTime(endDate))")
                            .foregroundColor(AppColors.secondaryLabel)
                    } else {
                        Text(formatTime(date))
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                }
            }
            
            // Location
            if !location.isEmpty {
                HStack(spacing: 16) {
                    Image(systemName: "location.fill")
                        .foregroundColor(AppColors.accent)
                        .frame(width: 24)
                    
                    Text(location)
                        .font(.headline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Attendees View
private struct AttendeesView: View {
    let friends: [Friend]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Attendees")
                .font(.headline)
                .foregroundColor(AppColors.label)
            
            ForEach(friends as [Friend]) { friend in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(friend.initials)
                                .font(.headline)
                                .foregroundColor(AppColors.label)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(friend.name)
                            .font(.headline)
                        if let email = friend.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryLabel)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

// MARK: - Action Buttons View
private struct ActionButtonsView: View {
    let hangout: Hangout
    @Binding var showingRescheduleSheet: Bool
    @Binding var showingDeleteConfirmation: Bool
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 12) {
            if !hangout.isCompleted {
                Text("Please make modifications to the event via your default calendar service")
                    .font(.footnote)
                    .foregroundColor(AppColors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
                
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Event", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Content View
private struct HangoutContentView: View {
    let hangout: Hangout
    @Binding var selectedFriends: [Friend]
    @Binding var attendeeEmails: [String]
    @Binding var showingRescheduleSheet: Bool
    @Binding var showingDeleteConfirmation: Bool
    @Binding var showingFriendPicker: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            HangoutHeaderView(title: hangout.title, isRescheduled: hangout.isRescheduled)
            
            TimeLocationView(
                date: hangout.date,
                endDate: hangout.endDate,
                location: hangout.location
            )
            
            // Attendees Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Attendees")
                        .font(.headline)
                        .foregroundColor(AppColors.label)
                    
                    Spacer()
                    
                    if !hangout.isCompleted {
                        Button {
                            showingFriendPicker = true
                        } label: {
                            Label("Add", systemImage: "person.badge.plus")
                                .labelStyle(.iconOnly)
                                .foregroundColor(AppColors.accent)
                        }
                    }
                }
                
                // Friends Section
                if !selectedFriends.isEmpty {
                    Text("Friends")
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondaryLabel)
                    
                    ForEach(selectedFriends) { friend in
                        AttendeeRow(
                            name: friend.name,
                            email: friend.email,
                            initials: friend.initials,
                            canRemove: !hangout.isCompleted
                        ) {
                            selectedFriends.removeAll { $0.id == friend.id }
                            hangout.friends = selectedFriends
                        }
                    }
                }
                
                // Calendar Attendees Section
                let nonFriendAttendees = attendeeEmails.filter { email in
                    !selectedFriends.contains { $0.email == email }
                }
                
                if !nonFriendAttendees.isEmpty {
                    Text("Calendar Attendees")
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondaryLabel)
                        .padding(.top, 8)
                    
                    ForEach(nonFriendAttendees, id: \.self) { email in
                        AttendeeRow(
                            name: email.components(separatedBy: "@").first ?? email,
                            email: email,
                            initials: String(email.prefix(2).uppercased()),
                            canRemove: false
                        ) {
                            // No removal action for calendar attendees
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            ActionButtonsView(
                hangout: hangout,
                showingRescheduleSheet: $showingRescheduleSheet,
                showingDeleteConfirmation: $showingDeleteConfirmation
            )
        }
        .padding(.vertical)
    }
}

// MARK: - Main View
struct HangoutDetailView: View {
    let hangout: Hangout
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var calendarManager = CalendarManager.shared
    @State private var showingRescheduleSheet = false
    @State private var showingFriendPicker = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedFriends: [Friend]
    @State private var attendeeEmails: [String]
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var isSyncing = false
    @State private var lastCacheUpdate = Date()
    
    private static var currentSyncTask: Task<Void, Never>?
    
    init(hangout: Hangout) {
        self.hangout = hangout
        self._selectedFriends = State(initialValue: hangout.friends)
        self._attendeeEmails = State(initialValue: hangout.attendeeEmails)
    }
    
    private func syncAttendees() async {
        guard let googleEventId = hangout.googleEventId else {
            print("⚠️ No Google Event ID found for hangout: \(hangout.id)")
            return
        }
        
        // Cancel any existing sync task
        Self.currentSyncTask?.cancel()
        
        // Create a new sync task
        Self.currentSyncTask = Task {
            guard !isSyncing else {
                print("⚠️ Already syncing attendees, skipping...")
                return
            }
            
            print("🔄 Starting attendee sync for event ID: \(googleEventId)")
            isSyncing = true
            defer { isSyncing = false }
            
            do {
                print("📅 Current friends count: \(hangout.friends.count)")
                print("📅 Current attendee emails count: \(hangout.attendeeEmails.count)")
                
                try await calendarManager.syncGoogleEventAttendees(for: hangout)
                
                // Update local state
                if !Task.isCancelled {
                    await MainActor.run {
                        selectedFriends = hangout.friends
                        attendeeEmails = hangout.attendeeEmails
                    }
                    
                    print("✅ Sync completed successfully")
                    print("📅 Updated friends count: \(selectedFriends.count)")
                    print("📅 Updated attendee emails count: \(attendeeEmails.count)")
                }
            } catch {
                print("❌ Sync failed with error: \(error)")
                print("❌ Error description: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("❌ Error domain: \(nsError.domain)")
                    print("❌ Error code: \(nsError.code)")
                    print("❌ Error user info: \(nsError.userInfo)")
                }
                if !Task.isCancelled {
                    await MainActor.run {
                        errorMessage = "Failed to sync attendees: \(error.localizedDescription)"
                    }
                }
            }
        }
        
        // Wait for the sync task to complete
        await Self.currentSyncTask?.value
    }
    
    private func deleteHangout() async {
        isDeleting = true
        defer { isDeleting = false }
        
        do {
            // First try to delete from calendar if it exists
            if let googleEventId = hangout.googleEventId {
                try await calendarManager.deleteEvent(eventId: googleEventId, isGoogleEvent: true)
            }
            
            // Delete from local database
            modelContext.delete(hangout)
            dismiss()
        } catch {
            errorMessage = "Failed to delete event: \(error.localizedDescription)"
        }
    }
    
    var body: some View {
        ScrollView {
            if isDeleting {
                ProgressView("Deleting event...")
                    .padding()
            } else if isSyncing {
                ProgressView("Syncing attendees...")
                    .padding()
            } else {
                VStack(spacing: 24) {
                    HangoutHeaderView(title: hangout.title, isRescheduled: hangout.isRescheduled)
                    
                    TimeLocationView(
                        date: hangout.date,
                        endDate: hangout.endDate,
                        location: hangout.location
                    )
                    
                    // Attendees Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Attendees")
                                .font(.headline)
                                .foregroundColor(AppColors.label)
                            
                            Spacer()
                            
                            if !hangout.isCompleted {
                                Button {
                                    showingFriendPicker = true
                                } label: {
                                    Label("Add", systemImage: "person.badge.plus")
                                        .labelStyle(.iconOnly)
                                        .foregroundColor(AppColors.accent)
                                }
                            }
                        }
                        
                        // Friends Section
                        if !selectedFriends.isEmpty {
                            Text("Friends")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryLabel)
                            
                            ForEach(selectedFriends) { friend in
                                AttendeeRow(
                                    name: friend.name,
                                    email: friend.email,
                                    initials: friend.initials,
                                    canRemove: !hangout.isCompleted
                                ) {
                                    selectedFriends.removeAll { $0.id == friend.id }
                                    hangout.friends = selectedFriends
                                }
                            }
                        }
                        
                        // Calendar Attendees Section
                        let nonFriendAttendees = attendeeEmails.filter { email in
                            !selectedFriends.contains { $0.email == email }
                        }
                        
                        if !nonFriendAttendees.isEmpty {
                            Text("Calendar Attendees")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryLabel)
                                .padding(.top, 8)
                            
                            ForEach(nonFriendAttendees, id: \.self) { email in
                                AttendeeRow(
                                    name: email.components(separatedBy: "@").first ?? email,
                                    email: email,
                                    initials: String(email.prefix(2).uppercased()),
                                    canRemove: false
                                ) {
                                    // No removal action for calendar attendees
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    ActionButtonsView(
                        hangout: hangout,
                        showingRescheduleSheet: $showingRescheduleSheet,
                        showingDeleteConfirmation: $showingDeleteConfirmation
                    )
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            await syncAttendees()
        }
        .onReceive(calendarManager.$eventCache.map { _ in Date() }) { _ in
            Task {
                await syncAttendees()
            }
        }
        .alert("Delete Event", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteHangout()
                }
            }
        } message: {
            Text("Are you sure you want to delete this event? This will remove it from your calendar as well.")
        }
        .alert("Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showingRescheduleSheet) {
            NavigationStack {
                CreateHangoutView(
                    initialDate: Date(),
                    initialLocation: hangout.location,
                    initialTitle: hangout.title,
                    initialSelectedFriends: selectedFriends
                )
            }
        }
        .sheet(isPresented: $showingFriendPicker) {
            NavigationStack {
                FriendPickerView(selectedFriends: $selectedFriends, selectedTime: hangout.date)
                    .onDisappear {
                        hangout.friends = selectedFriends
                    }
            }
        }
    }
}

// MARK: - Attendee Row View
private struct AttendeeRow: View {
    let name: String
    let email: String?
    let initials: String
    let canRemove: Bool
    let onRemove: () -> Void
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(initials)
                        .font(.headline)
                        .foregroundColor(AppColors.label)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                if let email = email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondaryLabel)
                }
            }
            
            if canRemove {
                Spacer()
                
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .imageScale(.small)
                }
                .alert("Remove Attendee", isPresented: $showingDeleteConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Remove", role: .destructive) {
                        onRemove()
                    }
                } message: {
                    Text("Are you sure you want to remove \(name) from this hangout?")
                }
            }
        }
    }
}

#Preview {
    let friend1 = Friend(name: "Test Friend 1")
    friend1.email = "test1@example.com"
    let friend2 = Friend(name: "Test Friend 2")
    friend2.email = "test2@example.com"
    
    let hangout = Hangout(
        date: Date().addingTimeInterval(86400),
        title: "Coffee Catchup",
        location: "Starbucks Downtown",
        isScheduled: true,
        friends: [friend1, friend2]
    )
    
    return NavigationStack {
        HangoutDetailView(hangout: hangout)
    }
} 
