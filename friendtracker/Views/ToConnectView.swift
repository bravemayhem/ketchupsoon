import SwiftUI
import SwiftData

struct ToConnectView: View {
    @Query(sort: [SortDescriptor(\Friend.lastSeen)]) private var friends: [Friend]
    @State private var selectedFriend: Friend?
    @State private var showingFriendSheet = false
    @State private var showingActionSheet = false
    @State private var showingScheduler = false
    @State private var showingMessageSheet = false
    @State private var showingFrequencyPicker = false
    
    var friendsToConnect: [Friend] {
        friends.filter { $0.needsToConnect }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.spacingMedium) {
                if friendsToConnect.isEmpty {
                    ContentUnavailableView("No Friends to Connect With", systemImage: "person.2.badge.gearshape")
                        .foregroundColor(AppColors.label)
                } else {
                    ForEach(friendsToConnect) { friend in
                        FriendListCard(friend: friend)
                            .padding(.horizontal)
                            .onTapGesture {
                                selectedFriend = friend
                                showingActionSheet = true
                            }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(AppColors.systemBackground)
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
            
            Button("Remove from To Connect List") {
                friend.needsToConnectFlag = false
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

#Preview {
    ToConnectView()
        .modelContainer(for: Friend.self)
} 