import SwiftUI

struct FriendListCard: View {
    let friend: Friend
    
    var lastSeenText: String? {
        guard let lastSeen = friend.lastSeen else {
            return nil
        }
        
        if Calendar.current.isDateInToday(lastSeen) {
            return "Last Seen: Today"
        } else {
            return "Last Seen: \(lastSeen.formatted(.relative(presentation: .named)))"
        }
    }
    
    var body: some View {
        BaseCardView {
            CardContentView(friend: friend) {
                VStack(alignment: .leading, spacing: 4) {
                    if let location = friend.location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppColors.secondaryLabel)
                            Text(location).cardSecondaryText()
                        }
                    }
                    
                    if let frequency = friend.catchUpFrequency {
                        Text(frequency.displayText).cardSecondaryText()
                    }
                    
                    if let lastSeen = lastSeenText {
                        Text(lastSeen).cardSecondaryText()
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Friend with all details
        FriendListCard(friend: Friend(
            name: "Test Friend",
            lastSeen: Date(),
            location: "San Francisco",
            phoneNumber: "123-456-7890",
            catchUpFrequency: .monthly
        ))
        
        // Friend with only location
        FriendListCard(friend: Friend(
            name: "Another Friend",
            location: "Los Angeles",
            phoneNumber: "123-456-7890"
        ))
        
        // Friend with no optional fields
        FriendListCard(friend: Friend(
            name: "Basic Friend",
            phoneNumber: "123-456-7890"
        ))
    }
    .padding()
    .background(AppColors.systemBackground)
}
