import SwiftUI
import SwiftData

struct WishlistView: View {
    @Query(sort: [SortDescriptor(\Friend.lastSeen)]) private var friends: [Friend]
    @State private var selectedFriend: Friend?
    @State private var showingFriendSheet = false
    @State private var showingActionSheet = false
    @State private var showingScheduler = false
    @State private var showingMessageSheet = false
    @State private var showingFrequencyPicker = false
    
    var wishlistFriends: [Friend] {
        friends.filter { friend in
            // Only include friends that are manually flagged and don't have a frequency set
            friend.needsToConnectFlag && friend.catchUpFrequency == nil
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.spacingMedium) {
                if wishlistFriends.isEmpty {
                    ContentUnavailableView("Wishlist Empty", systemImage: "star")
                        .foregroundColor(AppColors.label)
                } else {
                    ForEach(wishlistFriends) { friend in
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
            
            Button("Remove from Wishlist") {
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
    WishlistView()
        .modelContainer(for: Friend.self)
} 