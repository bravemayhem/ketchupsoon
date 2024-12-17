import SwiftUI
import SwiftData
import MessageUI

struct FriendsListView: View {
    @EnvironmentObject private var theme: Theme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Friend.name)]) private var friends: [Friend]
    @State private var selectedFriend: Friend?
    @State private var showingFriendSheet = false
    @State private var showingActionSheet = false
    @State private var showingScheduler = false
    @State private var showingMessageSheet = false
    @State private var showingFrequencyPicker = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if friends.isEmpty {
                    ContentUnavailableView("No Friends Added", systemImage: "person.2.badge.plus")
                        .foregroundColor(theme.primaryText)
                } else {
                    ForEach(friends) { friend in
                        FriendListCard(friend: friend)
                            .padding(.horizontal)
                            .onTapGesture {
                                #if DEBUG
                                debugLog("Tapped friend card: \(friend.name)")
                                #endif
                                selectedFriend = friend
                                showingActionSheet = true
                            }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(theme.background)
        .onAppear {
            #if DEBUG
            debugLog("FriendsListView appeared with \(friends.count) friends")
            #endif
        }
        .sheet(isPresented: $showingFriendSheet, content: {
            if let friend = selectedFriend {
                NavigationStack {
                    FriendDetailView(
                        friend: friend,
                        presentationMode: .sheet($showingFriendSheet)
                    )
                }
            }
        })
        .sheet(isPresented: $showingScheduler) {
            if let friend = selectedFriend {
                NavigationStack {
                    SchedulerView(initialFriend: friend)
                }
            }
        }
        .sheet(isPresented: $showingMessageSheet) {
            if let friend = selectedFriend {
                MessageComposeView(recipient: friend.phoneNumber ?? "")
            }
        }
        .sheet(isPresented: $showingFrequencyPicker) {
            if let friend = selectedFriend {
                NavigationStack {
                    FrequencyPickerView(friend: friend)
                }
            }
        }
        .confirmationDialog("Actions", isPresented: $showingActionSheet, presenting: selectedFriend) { friend in
            Button("View Details") {
                showingFriendSheet = true
            }
            
            if friend.phoneNumber != nil {
                Button("Send Message") {
                    showingMessageSheet = true
                }
            }
            
            Button("Schedule Hangout") {
                showingScheduler = true
            }
            
            Button("Mark as Seen Today") {
                friend.updateLastSeen(Date())
            }
            
            if friend.needsToConnectFlag {
                Button("Remove from To Connect List") {
                    friend.needsToConnectFlag = false
                }
            } else {
                Button("Add to To Connect List") {
                    friend.needsToConnectFlag = true
                }
            }
            
            Button("Set Catch-up Frequency") {
                showingFrequencyPicker = true
            }
            
            Button("Cancel", role: .cancel) {}
        } message: { friend in
            Text(friend.name)
        }
    }
}

struct FriendListCard: View {
    @EnvironmentObject private var theme: Theme
    let friend: Friend
    
    var lastSeenText: String {
        if Calendar.current.isDateInToday(friend.lastSeen) {
            return "Active today"
        } else {
            return friend.lastSeen.formatted(.relative(presentation: .named))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(friend.name)
                .font(.title2)
                .bold()
                .foregroundColor(theme.primaryText)
            
            Text(lastSeenText)
                .foregroundColor(theme.secondaryText)
            
            Text(friend.location)
                .foregroundColor(theme.secondaryText)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
                .shadow(color: Color.black.opacity(theme.shadowOpacity), radius: theme.shadowRadius, x: theme.shadowOffset.x, y: theme.shadowOffset.y)
        )
    }
}

struct FrequencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: Theme
    let friend: Friend
    @State private var customDays: Int = 30
    @State private var showingCustomDaysPicker = false
    
    var body: some View {
        List {
            Section {
                Button("No Automatic Reminders") {
                    friend.updateFrequency(nil)
                    friend.updateCustomDays(nil)
                    dismiss()
                }
                .foregroundColor(friend.catchUpFrequency == nil ? theme.primary : .primary)
            } header: {
                Text("Manual Mode")
            } footer: {
                Text("You'll only be reminded to connect when you manually add this friend to the To Connect list.")
            }
            
            Section {
                ForEach(CatchUpFrequency.allCases, id: \.rawValue) { frequency in
                    Button {
                        if frequency == .custom {
                            showingCustomDaysPicker = true
                        } else {
                            friend.updateFrequency(frequency.rawValue)
                            friend.updateCustomDays(nil)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Text(frequency.rawValue)
                            Spacer()
                            if let currentFrequency = friend.catchUpFrequency,
                               currentFrequency == frequency.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.primary)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            } header: {
                Text("Automatic Reminders")
            } footer: {
                Text("You'll be automatically reminded to connect 3 weeks before the next catch-up is due.")
            }
        }
        .navigationTitle("Catch Up Frequency")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingCustomDaysPicker) {
            NavigationStack {
                Form {
                    Section {
                        Stepper("Every \(customDays) days", value: $customDays, in: 1...365)
                    }
                }
                .navigationTitle("Custom Frequency")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingCustomDaysPicker = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            friend.updateFrequency(CatchUpFrequency.custom.rawValue)
                            friend.updateCustomDays(customDays)
                            showingCustomDaysPicker = false
                            dismiss()
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    FriendsListView()
        .modelContainer(for: Friend.self)
        .environmentObject(Theme.shared)
}
