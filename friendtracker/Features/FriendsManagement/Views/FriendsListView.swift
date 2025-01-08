import SwiftUI
import SwiftData
import MessageUI

struct FriendsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Friend.name)]) private var friends: [Friend]
    @State private var selectedFriend: Friend?
    
    var body: some View {
        List {
            if friends.isEmpty {
                emptyStateView
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(friends) { friend in
                    FriendListCard(friend: friend)
                        .friendCardStyle()
                        .onTapGesture {
                            #if DEBUG
                            debugLog("Tapped friend card: \(friend.name)")
                            #endif
                            selectedFriend = nil  // Reset first to ensure onChange triggers
                            selectedFriend = friend
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
        .friendListStyle()
        .friendSheetPresenter(selectedFriend: $selectedFriend)
        .onAppear {
            #if DEBUG
            debugLog("FriendsListView appeared with \(friends.count) friends")
            #endif
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        ContentUnavailableView("No Friends Added", systemImage: "person.2.badge.plus")
            .foregroundColor(AppColors.label)
    }
}

#Preview {
    FriendsListView()
        .modelContainer(for: Friend.self)
}
