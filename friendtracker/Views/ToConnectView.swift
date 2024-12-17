import SwiftUI
import SwiftData

struct ToConnectView: View {
    @Query(sort: [SortDescriptor(\Friend.lastSeen)]) private var friends: [Friend]
    @EnvironmentObject private var theme: Theme
    
    var friendsToConnect: [Friend] {
        friends.filter { $0.needsToConnect }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if friendsToConnect.isEmpty {
                    ContentUnavailableView("No Friends to Connect With", systemImage: "person.2.badge.gearshape")
                        .foregroundColor(theme.primaryText)
                } else {
                    ForEach(friendsToConnect) { friend in
                        FriendListCard(friend: friend)
                            .padding(.horizontal)
                            .onTapGesture {
                                friend.needsToConnectFlag = false
                                friend.lastSeen = Date()
                            }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(theme.background)
    }
}

#Preview {
    ToConnectView()
        .modelContainer(for: Friend.self)
        .environmentObject(Theme.shared)
} 