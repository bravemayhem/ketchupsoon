import SwiftUI
import SwiftData

/// A card component that displays a scheduled or completed hangout with a friend,
/// including the friend's profile, hangout details, and interaction options.
struct HangoutCard: View {
    let hangout: Hangout
    @State private var selectedFriend: Friend?
    
    var statusColor: Color {
        if hangout.isCompleted {
            return .green
        } else if hangout.date <= Date() {
            return .orange
        } else {
            return AppColors.accent
        }
    }
    
    var statusText: String {
        if hangout.isCompleted {
            return "Completed"
        } else if hangout.date <= Date() {
            return "Needs Confirmation"
        } else {
            return "Upcoming"
        }
    }
    
    var body: some View {
        BaseCardView {
            if let friend = hangout.friend {
                Button(action: {
                    selectedFriend = friend
                }) {
                    CardContentView(friend: friend) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(hangout.activity)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.label)
                                Spacer()
                                Text(statusText)
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(statusColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(statusColor.opacity(0.1))
                                    )
                            }
                            
                            if !hangout.location.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppColors.secondaryLabel)
                                    Text(hangout.location).cardSecondaryText()
                                }
                            }
                            
                            if let frequency = friend.catchUpFrequency {
                                Text(frequency.displayText).cardSecondaryText()
                            }
                            
                            Text(hangout.formattedDate).cardSecondaryText()
                        }
                    }
                }
            }
        }
        .friendSheetPresenter(selectedFriend: $selectedFriend)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Friend with all details
        let friendWithDetails = Friend(
            name: "Test Friend",
            location: "San Francisco",
            phoneNumber: "123-456-7890",
            catchUpFrequency: .monthly
        )
        let hangoutWithDetails = Hangout(
            date: Date(),
            activity: "Coffee",
            location: "Local Cafe",
            isScheduled: true,
            friend: friendWithDetails
        )
        HangoutCard(hangout: hangoutWithDetails)
        
        // Friend with only location
        let friendWithLocation = Friend(
            name: "Another Friend",
            location: "Los Angeles",
            phoneNumber: "123-456-7890"
        )
        let hangoutWithLocation = Hangout(
            date: Date(),
            activity: "Lunch",
            location: "Restaurant",
            isScheduled: true,
            friend: friendWithLocation
        )
        HangoutCard(hangout: hangoutWithLocation)
    }
    .padding()
    .background(AppColors.systemBackground)
} 
