import SwiftUI

struct FriendListCard: View {
    let friend: Friend
    
    var lastSeenText: String? {
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
            CardContentView(friend: friend, showChevron: false) {
                VStack(alignment: .leading, spacing: 4) {
                    if let location = friend.location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppColors.secondaryLabel)
                                .frame(width: 15, alignment: .center)
                            Text(location).cardSecondaryText()
                        }
                    }
                    
                    if let frequency = friend.catchUpFrequency {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppColors.secondaryLabel)
                                .frame(width: 15, alignment: .center)
                            Text(frequency.displayText)
                                .cardSecondaryText()
                        }
                    }
                    
                    if let lastSeen = lastSeenText {
                        HStack(spacing: 4) {
                            Image(systemName: "hourglass")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppColors.secondaryLabel)
                                .frame(width: 15, alignment: .center)
                            Text(lastSeen)
                                .cardSecondaryText()
                        }
                    }
                    
                    // Ketchupsoon user badge
                    if friend.firebaseUserId != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(AppTheme.captionFont)
                                .foregroundColor(.green)
                                .frame(width: 15, alignment: .center)
                            Text("Ketchupsoon User")
                                .foregroundColor(.green)
                                .cardSecondaryText()
                        }
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                if friend.firebaseUserId != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .background(Circle().fill(Color.white))
                        .offset(x: 6, y: -6)
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
        
        // Friend with Firebase ID (Ketchupsoon user)
        FriendListCard(friend: Friend(
            name: "Ketchupsoon User",
            location: "Online",
            phoneNumber: "123-456-7890",
            firebaseUserId: "firebase-id-123"
        ))
    }
    .padding()
    .background(AppColors.systemBackground)
}
