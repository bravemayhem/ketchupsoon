import SwiftUI
import SwiftData

/// A card component that displays a scheduled or completed hangout with a friend,
/// including the friend's profile, hangout details, and interaction options.
struct HangoutCard: View {
    let hangout: Hangout
    @State private var selectedFriend: Friend?
    @State private var showingCompletionPrompt = false
    
    var statusColor: Color {
        if hangout.isCompleted {
            return .green
        } else if hangout.date <= Date() {
            return .orange
        } else {
            return AppColors.accent
        }
    }
    
    var body: some View {
        BaseCardView {
            if let friend = hangout.friend {
                VStack(spacing: 12) {
                    Button(action: {
                        selectedFriend = friend
                    }) {
                        CardContentView(friend: friend, showChevron: false) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(hangout.activity)
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.label)
                                    Spacer()
                                    if hangout.isCompleted {
                                        Label("Completed", systemImage: "checkmark.circle.fill")
                                            .font(AppTheme.captionFont)
                                            .foregroundColor(.green)
                                    } else if hangout.date <= Date() {
                                        Button(action: {
                                            showingCompletionPrompt = true
                                        }) {
                                            Text("Confirm")
                                                .font(AppTheme.captionFont)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .fill(AppColors.accent)
                                                )
                                        }
                                    }
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
        }
        .friendSheetPresenter(selectedFriend: $selectedFriend)
        .sheet(isPresented: $showingCompletionPrompt) {
            HangoutCompletionView(hangout: hangout)
        }
    }
}

#Preview {
    let friend = Friend(name: "Test Friend")
    let hangout = Hangout(
        date: Date().addingTimeInterval(86400),
        activity: "Coffee",
        location: "Starbucks",
        isScheduled: true,
        friend: friend
    )
    
    return HangoutCard(hangout: hangout)
        .padding()
} 
