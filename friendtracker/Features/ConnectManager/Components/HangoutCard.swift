import SwiftUI
import SwiftData

/// A card component that displays a scheduled or completed hangout with a friend,
/// including the friend's profile, hangout details, and interaction options.
struct HangoutCard: View {
    let hangout: Hangout
    @State private var selectedFriend: Friend?
    
    var body: some View {
        BaseCardView {
            if let friend = hangout.friend {
                Button(action: {
                    selectedFriend = friend
                }) {
                    CardContentView(friend: friend) {
                        Text(hangout.formattedDate).cardSecondaryText()
                    }
                }
            }
        }
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