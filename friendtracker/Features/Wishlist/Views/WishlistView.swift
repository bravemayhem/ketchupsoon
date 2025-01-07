import SwiftUI
import SwiftData

struct WishlistView: View {
    @Query(sort: [SortDescriptor(\Friend.lastSeen)]) private var friends: [Friend]
    @State private var selectedFriend: Friend?
    
    var wishlistFriends: [Friend] {
        friends.filter { friend in
            // Only include friends that are manually flagged
            friend.needsToConnectFlag
        }
    }
    
    var body: some View {
        List {
            if wishlistFriends.isEmpty {
                ContentUnavailableView("Wishlist Empty", systemImage: "star")
                    .foregroundColor(AppColors.label)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(wishlistFriends) { friend in
                    FriendListCard(friend: friend)
                        .friendCardStyle()
                        .onTapGesture {
                            selectedFriend = friend
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                friend.needsToConnectFlag = false
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .friendListStyle()
        .friendSheetPresenter(selectedFriend: $selectedFriend)
    }
}

#Preview {
    WishlistView()
        .modelContainer(for: [Friend.self, Hangout.self])
} 
