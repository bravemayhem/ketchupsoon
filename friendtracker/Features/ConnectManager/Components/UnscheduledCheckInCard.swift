import SwiftUI

/// A card component that displays a friend who needs to be scheduled for a catch-up,
/// with options to message or schedule a hangout.
struct UnscheduledCheckInCard: View {
    let friend: Friend
    let onScheduleTapped: () -> Void
    let onMessageTapped: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.spacingMedium) {
            HStack(spacing: AppTheme.spacingMedium) {
                ProfileImage(friend: friend)
                
                VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                    Text(friend.name)
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppColors.label)
                        .lineLimit(1)
                    
                    if let frequency = friend.catchUpFrequency {
                        Text("Due for \(frequency) catch-up")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                }
                
                Spacer()
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
        .frame(maxWidth: .infinity)
        .padding(AppTheme.spacingMedium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(AppColors.secondarySystemBackground)
                .shadow(
                    color: AppTheme.shadowSmall.color,
                    radius: AppTheme.shadowSmall.radius,
                    x: AppTheme.shadowSmall.x,
                    y: AppTheme.shadowSmall.y
                )
        )
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