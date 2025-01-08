import SwiftUI

struct FriendListCard: View {
    let friend: Friend
    
    var lastSeenText: String {
        guard let lastSeen = friend.lastSeen else {
            return "Never"
        }
        
        if Calendar.current.isDateInToday(lastSeen) {
            return "Active today"
        } else {
            return lastSeen.formatted(.relative(presentation: .named))
        }
    }
    
    var body: some View {
        BaseCardView {
            CardContentView(friend: friend) {
                VStack(alignment: .leading) {
                    Text(lastSeenText).cardSecondaryText()
                    
                    if let location = friend.location {
                        Text(location).cardSecondaryText()
                        
                        if let frequency = friend.catchUpFrequency {
                            Text(frequency.displayText).cardSecondaryText()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    FriendListCard(friend: Friend(name: "Test Friend", phoneNumber: "123-456-7890"))
        .padding()
        .background(AppColors.systemBackground)
}
