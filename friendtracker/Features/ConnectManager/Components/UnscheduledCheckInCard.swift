import SwiftUI

/// A card component that displays a friend who needs to be scheduled for a catch-up,
/// with options to message or schedule a hangout.
struct UnscheduledCheckInCard: View {
    let friend: Friend
    let onScheduleTapped: () -> Void
    let onMessageTapped: () -> Void
    
    var body: some View {
        BaseCardView {
            VStack(spacing: AppTheme.spacingMedium) {
                CardContentView(friend: friend, showChevron: false) {
                    if let frequency = friend.catchUpFrequency {
                        Text("Due for \(frequency.displayText) catch-up")
                            .cardSecondaryText()
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
    UnscheduledCheckInCard(
        friend: Friend(name: "Test Friend", phoneNumber: "123-456-7890"),
        onScheduleTapped: {},
        onMessageTapped: {}
    )
    .padding()
    .background(AppColors.systemBackground)
} 