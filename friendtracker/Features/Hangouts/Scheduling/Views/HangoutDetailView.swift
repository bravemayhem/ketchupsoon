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
            HStack(spacing: 16) {
                Image(systemName: "clock.fill")
                    .foregroundColor(AppColors.accent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(date))
                        .font(.headline)
                    Text("\(formatTime(date)) - \(formatTime(endDate))")
                        .foregroundColor(AppColors.secondaryLabel)
                }
            }
            
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
    @Binding var showingMessageSheet: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            if !hangout.isCompleted {
                Button {
                    showingRescheduleSheet = true
                } label: {
                    Label("Reschedule", systemImage: "calendar.badge.clock")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                if let eventLink = hangout.eventLink {
                    ShareLink(
                        item: URL(string: eventLink)!,
                        subject: Text("Join me for \(hangout.title)"),
                        message: Text("View event details and RSVP: \(eventLink)")
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Main View
struct HangoutDetailView: View {
    let hangout: Hangout
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingMessageSheet = false
    @State private var showingRescheduleSheet = false
    @State private var showingFriendPicker = false
    @State private var selectedFriends: [Friend]
    @State private var manualAttendees: [ManualAttendee]
    
    init(hangout: Hangout) {
        self.hangout = hangout
        self._selectedFriends = State(initialValue: hangout.friends)
        self._manualAttendees = State(initialValue: hangout.manualAttendees)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HangoutHeaderView(title: hangout.title, isRescheduled: hangout.isRescheduled)
                
                // Time and Location Section
                VStack(spacing: 16) {
                    // Time
                    HStack(spacing: 16) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(AppColors.accent)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatDate(hangout.date))
                                .font(.headline)
                            if Calendar.current.compare(hangout.date, to: hangout.endDate, toGranularity: .minute) != .orderedSame {
                                Text("\(formatTime(hangout.date)) - \(formatTime(hangout.endDate))")
                                    .foregroundColor(AppColors.secondaryLabel)
                            } else {
                                Text(formatTime(hangout.date))
                                    .foregroundColor(AppColors.secondaryLabel)
                            }
                        }
                    }
                    
                    // Location
                    if !hangout.location.isEmpty {
                        HStack(spacing: 16) {
                            Image(systemName: "location.fill")
                                .foregroundColor(AppColors.accent)
                                .frame(width: 24)
                            
                            Text(hangout.location)
                                .font(.headline)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Attendees Section with Add Button
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
                    
                    // Regular Friends
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
                    
                    // Manual Attendees
                    ForEach(manualAttendees) { attendee in
                        AttendeeRow(
                            name: attendee.name,
                            email: attendee.email,
                            initials: String(attendee.name.prefix(2).uppercased()),
                            canRemove: !hangout.isCompleted
                        ) {
                            manualAttendees.removeAll { $0.id == attendee.id }
                            hangout.manualAttendees = manualAttendees
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                ActionButtonsView(
                    hangout: hangout,
                    showingRescheduleSheet: $showingRescheduleSheet,
                    showingMessageSheet: $showingMessageSheet
                )
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
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
        .sheet(isPresented: $showingMessageSheet) {
            if let url = hangout.calendarEventURL {
                ShareSheet(items: [url])
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

// Helper view for sharing
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
