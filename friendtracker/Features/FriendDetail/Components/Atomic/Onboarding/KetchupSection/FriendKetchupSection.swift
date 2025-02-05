import SwiftUI


struct FriendKetchupSection: View {
    let friend: Friend
    let onLastSeenTap: () -> Void
    let onFrequencyTap: () -> Void
    
    var body: some View {
        Section("Ketchup Details") {
            // Last Seen
            Button {
                onLastSeenTap()
            } label: {
                HStack {
                    Text("Last Seen")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    if friend.lastSeen == nil {
                        Text("Not set")
                            .foregroundColor(AppColors.tertiaryLabel)
                            .multilineTextAlignment(.trailing)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "hourglass")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppColors.secondaryLabel)
                            Text(friend.lastSeenText)
                                .foregroundColor(AppColors.secondaryLabel)
                        }
                    }
                }
            }
            .buttonStyle(.borderless)
            
            // Catch Up Frequency
            Button(action: onFrequencyTap) {
                HStack {
                    Text("Catch Up Frequency")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    if let frequency = friend.catchUpFrequency {
                        Text(frequency.displayText)
                            .foregroundColor(AppColors.secondaryLabel)
                    } else {
                        Text("Not set")
                            .foregroundColor(AppColors.tertiaryLabel)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .buttonStyle(.borderless)
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

#Preview {
    NavigationStack {
        List {
            FriendKetchupSection(
                friend: Friend(
                    name: "Emma Thompson",
                    lastSeen: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                    location: "San Francisco",
                    phoneNumber: "(415) 555-0123",
                    catchUpFrequency: .monthly
                ),
                onLastSeenTap: {},
                onFrequencyTap: {}
            )
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(for: [Friend.self, Tag.self, Hangout.self])
} 


#Preview("FriendKetchupSection") {
    NavigationStack {
        List {
            FriendKetchupSection(
                friend: Friend(
                    name: "Emma Thompson",
                    lastSeen: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                    location: "San Francisco",
                    phoneNumber: "(415) 555-0123",
                    catchUpFrequency: .monthly
                ),
                onLastSeenTap: {},
                onFrequencyTap: {}
            )
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(for: [Friend.self, Tag.self, Hangout.self])
}
