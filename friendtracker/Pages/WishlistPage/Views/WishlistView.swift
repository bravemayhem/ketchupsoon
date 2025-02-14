import SwiftUI
import SwiftData

struct WishlistView: View {
    @Query(sort: [SortDescriptor(\Friend.lastSeen)]) private var friends: [Friend]
    @State private var selectedFriend: Friend?
    @State private var showingFriendPicker = false
    @State private var selectedFriends: [Friend] = []
    @State private var wishlistOrder: [UUID] = [] // Store UUIDs instead of Strings
    
    var wishlistFriends: [Friend] {
        let flaggedFriends = friends.filter { friend in
            friend.needsToConnectFlag
        }
        
        // Sort based on wishlistOrder if available, otherwise use default order
        if !wishlistOrder.isEmpty {
            return flaggedFriends.sorted { friend1, friend2 in
                let index1 = wishlistOrder.firstIndex(of: friend1.id) ?? Int.max
                let index2 = wishlistOrder.firstIndex(of: friend2.id) ?? Int.max
                return index1 < index2
            }
        }
        
        return flaggedFriends
    }
    
    var body: some View {
        List {
            Section {
                Button {
                    showingFriendPicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add to Wishlist")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.accent.opacity(0.1))
                    .foregroundColor(AppColors.accent)
                    .cornerRadius(10)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .padding(.vertical, 8)
            }
            
            if wishlistFriends.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "star")
                        .font(.custom("Cabin-Regular", size: 40))
                        .foregroundColor(Color.gray)
                    Text("Wishlist Empty")
                        .font(.custom("Cabin-Regular", size: 25))
                        .foregroundColor(Color.gray)
                    Text("Add friends you want to catch up with")
                        .font(.custom("Cabin-Regular", size: 16))
                        .foregroundColor(Color.gray)
                    Spacer()
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
                    .onDrag {
                        // Create drag item with friend's ID as UUID string
                        NSItemProvider(object: friend.id.uuidString as NSString)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            friend.needsToConnectFlag = false
                            // Remove from order list when removed from wishlist
                            wishlistOrder.removeAll { $0 == friend.id }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
                .onMove { source, destination in
                    // Update wishlistOrder when items are moved
                    var updatedOrder = wishlistFriends.map { $0.id }
                    updatedOrder.move(fromOffsets: source, toOffset: destination)
                    wishlistOrder = updatedOrder
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Friend.self) { friend in
            FriendExistingView(friend: friend)
        }
        .friendListStyle()
        .friendSheetPresenter(selectedFriend: $selectedFriend)
        .sheet(isPresented: $showingFriendPicker) {
            NavigationStack {
                FriendPickerView(selectedFriends: $selectedFriends, selectedTime: nil)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                // Add selected friends to wishlist and update order
                                for friend in selectedFriends {
                                    friend.needsToConnectFlag = true
                                    if !wishlistOrder.contains(friend.id) {
                                        wishlistOrder.append(friend.id)
                                    }
                                }
                                selectedFriends = []
                                showingFriendPicker = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                selectedFriends = []
                                showingFriendPicker = false
                            }
                        }
                    }
            }
        }
        .environment(\.editMode, .constant(.inactive))
        .scrollContentBackground(.hidden)
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
                title: "Coffee",
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
