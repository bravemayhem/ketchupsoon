import SwiftUI
import SwiftData

struct ToConnectView: View {
    @EnvironmentObject private var theme: Theme
    @Query(sort: [SortDescriptor(\Friend.lastSeen)]) private var friends: [Friend]
    
    var friendsToConnect: [Friend] {
        friends.filter { friend in
            guard let lastSeen = friend.lastSeen else { return true }
            let days = Calendar.current.dateComponents([.day], from: lastSeen, to: Date()).day ?? 0
            return days > 14
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if friendsToConnect.isEmpty {
                    ContentUnavailableView("No Friends to Connect With", systemImage: "person.2.badge.gearshape")
                        .foregroundColor(theme.primaryText)
                } else {
                    ForEach(friendsToConnect) { friend in
                        FriendCard(
                            friend: friend,
                            buttonTitle: "Schedule",
                            buttonStyle: .secondary,
                            action: {
                                // Schedule action
                            }
                        )
                        .padding(.horizontal)
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