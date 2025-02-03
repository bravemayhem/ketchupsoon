var body: some View {
    NavigationStack {
        List(friends) { friend in
            NavigationLink(value: friend) {
                FriendRow(friend: friend)
            }
        }
        .navigationDestination(for: Friend.self) { friend in
            FriendDetailView(friend: friend)
        }
        .navigationTitle("Friends")
    }
} 