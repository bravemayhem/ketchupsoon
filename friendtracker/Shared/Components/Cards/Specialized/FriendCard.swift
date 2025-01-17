import SwiftUI

struct FriendCard: View {
    let friend: Friend
    let buttonTitle: String
    let buttonStyle: CardStyles.Button.ButtonStyle
    let action: () -> Void
    
    private var lastSeenText: String? {
        guard let lastSeen = friend.lastSeen else {
            return nil
        }
        
        if Calendar.current.isDateInToday(lastSeen) {
            return "Last seen: Today"
        } else {
            return "Last seen: \(lastSeen.formatted(.relative(presentation: .named)))"
        }
    }
    
    var body: some View {
        BaseCardView {
            VStack(spacing: AppTheme.spacingMedium) {
                CardContentView(friend: friend, showChevron: false) {
                    VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                        if let location = friend.location {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(AppTheme.captionFont)
                                Text(location)
                            }
                            .cardSecondaryText()
                        }
                        
                        if let frequency = friend.catchUpFrequency {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(AppTheme.captionFont)
                                Text(frequency.displayText)
                            }
                            .cardSecondaryText()
                        }
                        
                        if let lastSeen = lastSeenText {
                            HStack(spacing: 4) {
                                Image(systemName: "hourglass")
                                    .font(AppTheme.captionFont)
                                Text(lastSeen)
                            }
                            .cardSecondaryText()
                        }
                    }
                }
                
                Button(action: action) {
                    Text(buttonTitle)
                }
                .cardButton(style: buttonStyle)
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Friend with all details
            FriendCard(
                friend: Friend(
                    name: "PreviewFriend",
                    lastSeen: Date(),
                    location: "San Francisco",
                    needsToConnectFlag: false,
                    phoneNumber: "562-413-8770",
                    catchUpFrequency: .monthly
                ),
                buttonTitle: "Connect",
                buttonStyle: .primary,
                action: {}
            )
            
            // Friend with only location
            FriendCard(
                friend: Friend(
                    name: "Another Friend",
                    location: "Los Angeles",
                    phoneNumber: "562-413-8770"
                ),
                buttonTitle: "Connect",
                buttonStyle: .primary,
                action: {}
            )
        }
        .padding()
    }
    .background(AppColors.systemBackground)
    .modelContainer(for: [Friend.self, Hangout.self], inMemory: true)
} 