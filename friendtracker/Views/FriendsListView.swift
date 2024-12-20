import SwiftUI
import SwiftData
import MessageUI

struct FriendsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Friend.name)]) private var friends: [Friend]
    @State private var selectedFriend: Friend?
    @State private var showingFriendSheet = false
    @State private var showingActionSheet = false
    @State private var showingScheduler = false
    @State private var showingMessageSheet = false
    @State private var showingFrequencyPicker = false
    
    var body: some View {
        List {
            if friends.isEmpty {
                emptyStateView
                    .listRowBackground(Color.clear)
                    .listSectionSeparator(.hidden)
            } else {
                ForEach(friends) { friend in
                    FriendListCard(friend: friend)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            #if DEBUG
                            debugLog("Tapped friend card: \(friend.name)")
                            #endif
                            selectedFriend = friend
                            showingFriendSheet = true
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                friend.needsToConnectFlag.toggle()
                            } label: {
                                Label(friend.needsToConnectFlag ? "Remove" : "Add", 
                                      systemImage: friend.needsToConnectFlag ? "star.slash.fill" : "star.fill")
                            }
                            .tint(friend.needsToConnectFlag ? .red : AppColors.success)
                        }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColors.systemBackground)
        .environment(\.defaultMinListRowHeight, 0)
        .environment(\.defaultMinListHeaderHeight, 0)
        .onAppear {
            #if DEBUG
            debugLog("FriendsListView appeared with \(friends.count) friends")
            #endif
        }
        .sheet(isPresented: $showingFriendSheet) {
            if let friend = selectedFriend {
                NavigationStack {
                    FriendDetailView(
                        friend: friend,
                        presentationMode: .sheet($showingFriendSheet)
                    )
                }
            }
        }
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
            actionButtons(for: friend)
        } message: { friend in
            Text(friend.name)
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        ContentUnavailableView("No Friends Added", systemImage: "person.2.badge.plus")
            .foregroundColor(AppColors.label)
    }
    
    @ViewBuilder
    private func actionButtons(for friend: Friend) -> some View {
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
            Button("Remove from Wishlist") {
                friend.needsToConnectFlag = false
            }
        } else {
            Button("Add to Wishlist") {
                friend.needsToConnectFlag = true
            }
        }
        
        Button("Set Catch-up Frequency") {
            showingFrequencyPicker = true
        }
        
        Button("Cancel", role: .cancel) {}
    }
}

#Preview {
    FriendsListView()
        .modelContainer(for: Friend.self)
}
