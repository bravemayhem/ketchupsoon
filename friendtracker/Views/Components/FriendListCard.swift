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
        HStack(spacing: AppTheme.spacingMedium) {
            ProfileImage(friend: friend)
            
            VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                Text(friend.name)
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppColors.label)
                    .lineLimit(1)
                
                Text(lastSeenText)
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppColors.secondaryLabel)
                
                if let location = friend.location {
                    Text(location)
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppColors.secondaryLabel)
                        .lineLimit(1)
                    
                    if let frequency = friend.catchUpFrequency {
                        Text(frequency.rawValue) // This will use the string values you defined ("Weekly", "Bi-weekly", etc.) in CatchUpFrequency.swift
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.secondaryLabel)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.spacingMedium)
            .padding(.vertical, AppTheme.spacingSmall)
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
}
