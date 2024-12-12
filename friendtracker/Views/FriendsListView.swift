import SwiftUI

struct FriendsListView: View {
    @State private var friends = SampleData.friends
    @State private var showingAddFriend = false
    
    var body: some View {
        NavigationView {
            FriendsContent(
                friends: friends,
                showingAddFriend: $showingAddFriend
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Friends")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Theme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.primary)
                            .padding(.trailing)
                    }
                }
            }
        }
    }
}

private struct FriendsContent: View {
    let friends: [Friend]
    @Binding var showingAddFriend: Bool
    
    private var hangoutsThisMonth: Int {
        // Calculate this based on your data
        return 5
    }
    
    private var currentMood: Int {
        // Calculate this based on your data
        return 4
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StatsHeader(
                    hangoutsThisMonth: hangoutsThisMonth,
                    currentMood: currentMood
                )
                
                FriendsList(friends: friends)
            }
            .padding()
        }
        .background(Theme.background)
    }
}

private struct StatsHeader: View {
    let hangoutsThisMonth: Int
    let currentMood: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Text("This Month")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.primaryText)
            
            HStack(spacing: 16) {
                StatCard(
                    value: "\(hangoutsThisMonth)",
                    label: "Hangouts"
                )
                
                StatCard(
                    value: "5/6",
                    label: "Hang Target"
                )
            }
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(value)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(Theme.primary)
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(NeoBrutalistBackground())
    }
}

private struct FriendsList: View {
    let friends: [Friend]
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(friends) { friend in
                FriendCard(friend: friend)
            }
        }
    }
}

#Preview {
    FriendsListView()
}
