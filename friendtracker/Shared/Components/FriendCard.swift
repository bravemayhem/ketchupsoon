import SwiftUI

struct FriendCard: View {
    let friend: Friend
    let buttonTitle: String
    let buttonStyle: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case outline
        
        var backgroundColor: Color {
            switch self {
            case .primary: return AppColors.accent
            case .secondary, .outline: return .clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary, .outline: return AppColors.accent
            }
        }
    }
    
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
        VStack(spacing: AppTheme.spacingMedium) {
            HStack(spacing: AppTheme.spacingMedium) {
                ProfileImage(friend: friend)
                
                VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                    Text(friend.name)
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppColors.label)
                        .lineLimit(1)
                    
                    if let location = friend.location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppColors.secondaryLabel)
                            Text(location)
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppColors.secondaryLabel)
                                .lineLimit(1)
                        }
                    }
                    
                    if let frequency = friend.catchUpFrequency {
                        Text(frequency.displayText)
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                    
                    if let lastSeen = lastSeenText {
                        Text(lastSeen)
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                    
                    Spacer()
                }
                
                Button(action: action) {
                    Text(buttonTitle)
                        .font(AppTheme.headlineFont)
                        .foregroundColor(buttonStyle.foregroundColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.spacingSmall)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                                .fill(buttonStyle.backgroundColor)
                        )
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
