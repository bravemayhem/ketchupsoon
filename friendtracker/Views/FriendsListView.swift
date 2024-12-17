import SwiftUI
import SwiftData
import MessageUI

struct FriendsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Friend.name)]) private var friends: [Friend]
    @State private var selectedFriend: Friend?
    @State private var showingFriendSheet = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if friends.isEmpty {
                    ContentUnavailableView("No Friends Added", systemImage: "person.2.badge.plus")
                } else {
                    ForEach(friends) { friend in
                        FriendListCard(friend: friend)
                            .padding(.horizontal)
                            .onTapGesture {
                                selectedFriend = friend
                                showingFriendSheet = true
                            }
                    }
                }
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showingFriendSheet, content: {
            if let friend = selectedFriend {
                NavigationStack {
                    FriendDetailSheet(friend: friend, isPresented: $showingFriendSheet)
                }
            }
        })
    }
}

struct FriendListCard: View {
    let friend: Friend
    
    var lastSeenText: String {
        if let lastSeen = friend.lastSeen {
            if Calendar.current.isDateInToday(lastSeen) {
                return "Active today"
            } else {
                return lastSeen.formatted(.relative(presentation: .named))
            }
        }
        return "Never"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Friend Name
            Text(friend.name)
                .font(.title2)
                .bold()
            
            // Last Seen
            Text(lastSeenText)
                .foregroundStyle(.secondary)
            
            // Location
            Text(friend.location)
                .foregroundStyle(.secondary)
            
            // Connect Button
            HStack {
                Spacer()
                Button(action: {
                    // Connect action handled by parent tap gesture
                }) {
                    Text("Connect")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary, lineWidth: 1)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

struct FriendDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    let friend: Friend
    @Binding var isPresented: Bool
    @State private var showingDatePicker = false
    @State private var lastSeenDate = Date()
    @State private var showingScheduler = false
    @State private var showingMessageSheet = false
    
    var body: some View {
        List {
            Section {
                // Last Seen
                HStack {
                    Text("Last Seen")
                    Spacer()
                    Button(friend.lastSeenText) {
                        lastSeenDate = friend.lastSeen ?? Date()
                        showingDatePicker = true
                    }
                    .foregroundStyle(.secondary)
                }
                
                // Location
                HStack {
                    Text("Location")
                    Spacer()
                    Text(friend.location)
                        .foregroundStyle(.secondary)
                }
                
                if let phoneNumber = friend.phoneNumber {
                    HStack {
                        Text("Phone")
                        Spacer()
                        Text(phoneNumber)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Actions") {
                if friend.phoneNumber != nil {
                    Button(action: {
                        showingMessageSheet = true
                    }) {
                        Label("Send Message", systemImage: "message.fill")
                    }
                }
                
                Button(action: {
                    showingScheduler = true
                }) {
                    Label("Schedule Hangout", systemImage: "calendar")
                }
                
                Button(action: {
                    friend.lastSeen = Date()
                }) {
                    Label("Mark as Seen Today", systemImage: "checkmark.circle.fill")
                }
            }
        }
        .navigationTitle(friend.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    isPresented = false
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                DatePicker(
                    "Select Date",
                    selection: $lastSeenDate,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .navigationTitle("Last Seen Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingDatePicker = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            friend.lastSeen = lastSeenDate
                            showingDatePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingScheduler) {
            NavigationStack {
                SchedulerView(initialFriend: friend)
            }
        }
        .sheet(isPresented: $showingMessageSheet) {
            MessageComposeView(recipient: friend.phoneNumber ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        FriendDetailSheet(
            friend: Friend(
                name: "Preview Friend",
                lastSeen: Date(),
                location: "Local",
                phoneNumber: "+1234567890"
            ),
            isPresented: .constant(true)
        )
    }
    .modelContainer(for: Friend.self)
}
