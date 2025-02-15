import SwiftUI
import SwiftData

/// A card component that displays a scheduled or completed hangout,
/// including the event title, attendees, and details.
struct HangoutCard: View {
    let hangout: Hangout
    @State private var selectedFriend: Friend?
    @State private var showingCompletionPrompt = false
    @State private var showingEventDetails = false
    
    
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
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    // Title and Status
                    HStack {
                        Text(hangout.title)
                            .font(.headline)
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
                    
                    // Attendees
                    if !hangout.friends.isEmpty {
                        ForEach(hangout.friends) { friend in
                            Button(action: {
                                selectedFriend = friend
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.fill")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppColors.secondaryLabel)
                                    Text(friend.name)
                                        .cardSecondaryText()
                                    if let email = friend.email, !email.isEmpty {
                                        Image(systemName: "envelope.fill")
                                            .font(AppTheme.captionFont)
                                            .foregroundColor(AppColors.secondaryLabel)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Location
                    if !hangout.location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppColors.secondaryLabel)
                            Text(hangout.location).cardSecondaryText()
                        }
                    }
                    
                    // Date and Time
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                        Text(hangout.formattedDate).cardSecondaryText()
                    }
                }
            }
        }
        .onTapGesture {
            showingEventDetails = true
        }
        .friendSheetPresenter(selectedFriend: $selectedFriend)
        .sheet(isPresented: $showingCompletionPrompt) {
            HangoutCompletionView(hangout: hangout)
        }
        .sheet(isPresented: $showingEventDetails) {
            NavigationStack {
                HangoutDetailView(hangout: hangout)
            }
        }
    }
}

#Preview {
    let friend1 = Friend(name: "Test Friend 1")
    let friend2 = Friend(name: "Test Friend 2")
    let hangout = Hangout(
        date: Date().addingTimeInterval(86400),
        title: "Coffee",
        location: "Starbucks",
        isScheduled: true,
        friends: [friend1, friend2]
    )
    
    return HangoutCard(hangout: hangout)
        .padding()
} 
