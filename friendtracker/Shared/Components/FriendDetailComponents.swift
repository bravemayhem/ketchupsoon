import SwiftUI
import SwiftData

struct FriendInfoSection: View {
    let friend: Friend
    let onLastSeenTap: () -> Void
    
    var body: some View {
        Section(content: {
            // Last Seen
            HStack {
                Text("Last Seen")
                    .foregroundColor(AppColors.label)
                Spacer()
                Button(friend.lastSeenText) {
                    onLastSeenTap()
                }
                .foregroundColor(AppColors.secondaryLabel)
            }
            
            // Location
            HStack {
                Text("Location")
                    .foregroundColor(AppColors.label)
                Spacer()
                if let location = friend.location {
                    Text(location)
                        .foregroundColor(AppColors.secondaryLabel)
                }
            }
            
            if let phoneNumber = friend.phoneNumber {
                HStack {
                    Text("Phone")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    Text(phoneNumber)
                        .foregroundColor(AppColors.secondaryLabel)
                }
            }
            
            HStack {
                Text("Catch-up Frequency")
                    .foregroundColor(AppColors.label)
                Spacer()
                if let frequency = friend.catchUpFrequency {
                    Text(frequency.displayText)
                        .foregroundColor(AppColors.secondaryLabel)
                } else {
                    Text("Not set")
                        .foregroundColor(AppColors.secondaryLabel)
                }
            }
        })
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}
            

struct FriendActionSection: View {
    @Bindable var friend: Friend
    let onMessageTap: () -> Void
    let onScheduleTap: () -> Void
    let onMarkSeenTap: () -> Void
    
    var body: some View {
        Section(content: {
            if !(friend.phoneNumber?.isEmpty ?? true) {
                Button(action: onMessageTap) {
                    Label("Send Message", systemImage: "message.fill")
                        .foregroundColor(AppColors.accent)
                }
            }
            
            Button(action: onScheduleTap) {
                Label("Schedule Hangout", systemImage: "calendar")
                    .foregroundColor(AppColors.accent)
            }
            
            Button(action: onMarkSeenTap) {
                Label("Mark as Seen Today", systemImage: "checkmark.circle.fill")
                    .foregroundColor(AppColors.accent)
            }
            
            Toggle(isOn: $friend.needsToConnectFlag) {
                Label(friend.needsToConnectFlag ? "Remove from Wishlist" : "Add to Wishlist",
                      systemImage: friend.needsToConnectFlag ? "star.slash" : "star")
            }
            .tint(AppColors.accent)
        }, header: {
            Text("Actions")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppColors.label)
                .textCase(nil)
                .padding(.bottom, 8)
        })
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

struct FriendHangoutsSection: View {
    let hangouts: [Hangout]
    
    var body: some View {
        if !hangouts.isEmpty {
            Section(content: {
                ForEach(hangouts) { hangout in
                    VStack(alignment: .leading, spacing: AppTheme.spacingTiny) {
                        Text(hangout.activity)
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppColors.label)
                        Text(hangout.location)
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                        Text(hangout.formattedDate)
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                    .padding(.vertical, AppTheme.spacingTiny)
                }
            }, header: {
                Text("Upcoming Hangouts")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppColors.label)
                    .textCase(nil)
                    .padding(.bottom, 8)
            })
            .listRowBackground(AppColors.secondarySystemBackground)
        }
    }
} 
