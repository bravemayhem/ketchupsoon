import SwiftUI
import SwiftData

/// A card component that displays a scheduled or completed hangout with a friend,
/// including the friend's profile, hangout details, and interaction options.
struct HangoutCard: View {
    let hangout: Hangout
    @State private var selectedFriend: Friend?
    
    var body: some View {
        VStack(spacing: AppTheme.spacingMedium) {
            if let friend = hangout.friend {
                Button(action: {
                    selectedFriend = friend
                }) {
                    HStack(spacing: AppTheme.spacingMedium) {
                        ProfileImage(friend: friend)
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                            Text(friend.name)
                                .font(AppTheme.headlineFont)
                                .foregroundColor(AppColors.label)
                            
                            Text(hangout.formattedDate)
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppColors.secondaryLabel)
                        }
                        
                        Spacer()
                    }
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
        .friendSheetPresenter(selectedFriend: $selectedFriend)
    }
}

#Preview {
    let friend = Friend(name: "Test Friend", phoneNumber: "123-456-7890")
    let hangout = Hangout(
        date: Date(),
        activity: "Coffee",
        location: "Local Cafe",
        isScheduled: true,
        friend: friend
    )
    
    return HangoutCard(hangout: hangout)
        .padding()
        .background(AppColors.systemBackground)
} 