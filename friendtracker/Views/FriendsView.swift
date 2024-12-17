import SwiftUI

struct FriendsView: View {
    let friends: [Friend]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(friends) { friend in
                    FriendCard(
                        friend: friend,
                        buttonTitle: "Connect",
                        buttonStyle: .secondary,
                        action: {
                            // Connect action
                        }
                    )
                }
            }
            .padding()
        }
    }
} 