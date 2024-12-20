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
    
    var body: some View {
        VStack(spacing: AppTheme.spacingMedium) {
            HStack(spacing: AppTheme.spacingMedium) {
                ProfileImage(friend: friend)
                
                VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                    Text(friend.name)
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppColors.label)
                        .lineLimit(1)
                    
                    Text(friend.lastSeenText)
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppColors.secondaryLabel)
                    
                    Text(friend.location)
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppColors.secondaryLabel)
                        .lineLimit(1)
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

#Preview {
    FriendCard(
        friend: Friend(name: "Preview Friend"),
        buttonTitle: "Connect",
        buttonStyle: .primary,
        action: {}
    )
    .padding()
    .background(AppColors.systemBackground)
} 