import SwiftUI

/// A card component that displays a friend who needs to be scheduled for a catch-up,
/// with options to message or schedule a hangout.
struct UnscheduledCheckInCard: View {
    let friend: Friend
    let onScheduleTapped: () -> Void
    let onMessageTapped: () -> Void
    
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
            VStack(spacing: AppTheme.spacingMedium) {
                CardContentView(friend: friend, showChevron: false) {
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
                            Text("Due for \(frequency.displayText) catch-up")
                                .cardSecondaryText()
                        }
                        
                        if let lastSeen = lastSeenText {
                            Text(lastSeen).cardSecondaryText()
                        }
                    }
                }
                
                HStack(spacing: AppTheme.spacingMedium) {
                    if friend.phoneNumber != nil {
                        Button(action: onMessageTapped) {
                            Label("Message", systemImage: "message.fill")
                                .font(AppTheme.headlineFont)
                                .foregroundColor(AppColors.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.spacingSmall)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                                        .stroke(AppColors.accent, lineWidth: 1)
                                )
                        }
                    }
                    
                    Button(action: onScheduleTapped) {
                        Label("Schedule", systemImage: "calendar.badge.plus")
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppColors.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.spacingSmall)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                                    .stroke(AppColors.accent, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Friend with all details
        UnscheduledCheckInCard(
            friend: Friend(
                name: "Test Friend",
                lastSeen: Date(),
                location: "San Francisco",
                phoneNumber: "123-456-7890",
                catchUpFrequency: .monthly
            ),
            onScheduleTapped: {},
            onMessageTapped: {}
        )
        
        // Friend with only location
        UnscheduledCheckInCard(
            friend: Friend(
                name: "Another Friend",
                location: "Los Angeles",
                phoneNumber: "123-456-7890"
            ),
            onScheduleTapped: {},
            onMessageTapped: {}
        )
    }
    .padding()
    .background(AppColors.systemBackground)
} 
