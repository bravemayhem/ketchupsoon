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
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "star")
                        .font(.custom("Cabin-Regular", size: 40))
                        .foregroundColor(Color.gray)
                    Text("Wishlist Empty")
                        .font(.custom("Cabin-Regular", size: 25))
                        .foregroundColor(Color.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(wishlistFriends) { friend in
                    BetterNavigationLink {
                        FriendListCard(friend: friend)
                            .friendCardStyle()
                    } destination: {
                        FriendExistingView(friend: friend)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .tint(.clear)
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
        .listStyle(.plain)
        .navigationDestination(for: Friend.self) { friend in
            FriendExistingView(friend: friend)
        }
        .friendListStyle()
        .friendSheetPresenter(selectedFriend: $selectedFriend)
    }
}

struct FriendsWishlistPreviewContainer: View {
    enum PreviewState {
        case empty
        case withFriends
    }
    
    let state: PreviewState
    let container: ModelContainer
    
    init(state: PreviewState) {
        self.state = state
        
        let schema = Schema([Friend.self, Tag.self, Hangout.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        if state == .withFriends {
            // Create sample friends with various states
            let friends = [
                Friend(
                    name: "Emma Thompson",
                    lastSeen: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                    location: "San Francisco",
                    needsToConnectFlag: true,
                    phoneNumber: "(415) 555-0123",
                    catchUpFrequency: .weekly
                ),
                Friend(
                    name: "James Wilson",
                    lastSeen: Date(),
                    location: "Local",
                    phoneNumber: "(555) 123-4567",
                    catchUpFrequency: .monthly
                ),
                Friend(
                    name: "Sarah Chen",
                    lastSeen: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
                    location: "Remote",
                    needsToConnectFlag: true,
                    phoneNumber: "(650) 555-0199",
                    catchUpFrequency: .quarterly
                ),
                Friend(
                    name: "Alex Rodriguez",
                    lastSeen: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                    location: "Oakland",
                    phoneNumber: "(510) 555-0145"
                )
            ]
            
            // Add some tags to friends
            let tags = [
                Tag(name: "college"),
                Tag(name: "work"),
                Tag(name: "book club"),
                Tag(name: "hiking")
            ]
            
            friends[0].tags = [tags[0], tags[3]]  // Emma: college, hiking
            friends[1].tags = [tags[1]]           // James: work
            friends[2].tags = [tags[1], tags[2]]  // Sarah: work, book club
            
            // Add some hangouts
            let futureDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
            let hangout = Hangout(
                date: futureDate,
                activity: "Coffee",
                location: "Blue Bottle",
                isScheduled: true,
                friends: [friends[0]]
            )
            
            // Insert everything into context
            friends.forEach { context.insert($0) }
            tags.forEach { context.insert($0) }
            context.insert(hangout)
        }
        
        self.container = container
    }
    
    var body: some View {
        NavigationStack {
            WishlistView()
        }
        .modelContainer(container)
    }
}

#Preview("With Friends") {
    FriendsWishlistPreviewContainer(state: .withFriends)
}

#Preview("Without Friends") {
    FriendsWishlistPreviewContainer(state: .empty)
}
