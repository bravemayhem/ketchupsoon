import SwiftUI
import SwiftData

/// A card component that displays a scheduled or completed hangout with a friend,
/// including the friend's profile, hangout details, and interaction options.
struct HangoutCard: View {
    let hangout: Hangout
    @State private var selectedFriend: Friend?
    @State private var showingMessageSheet = false
    
    var statusColor: Color {
        if hangout.isCompleted {
            return .green
        } else if hangout.date <= Date() {
            return .orange
        } else {
            return AppColors.accent
        }
    }
    
    var statusText: String {
        if hangout.isCompleted {
            return "Completed"
        } else if hangout.date <= Date() {
            return "Needs Confirmation"
        } else {
            return "Upcoming"
        }
    }
    
    var messageText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        
        var message = "Hey! Here are the details for our hangout:\n\n"
        message += "🗓 \(dateFormatter.string(from: hangout.date))\n"
        message += "🎯 \(hangout.activity)\n"
        if !hangout.location.isEmpty {
            message += "📍 \(hangout.location)\n"
        }
        
        message += "\n\nSee you there! 👋"
        
        return message
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
                                    Text(statusText)
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(statusColor)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(statusColor.opacity(0.1))
                                        )
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
                    
                    if !hangout.isCompleted && hangout.date > Date() && friend.phoneNumber != nil {
                        Button {
                            showingMessageSheet = true
                        } label: {
                            Label("Share Details", systemImage: "square.and.arrow.up")
                                .font(AppTheme.bodyFont)
                                .foregroundColor(AppColors.accent)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                    }
                }
            }
        }
        .friendSheetPresenter(selectedFriend: $selectedFriend)
        .sheet(isPresented: $showingMessageSheet) {
            if let phoneNumber = hangout.friend?.phoneNumber {
                MessageComposeView(recipient: phoneNumber, message: messageText)
                    .presentationDetents([.height(400), .large])
                    .presentationDragIndicator(.visible)
            }
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
