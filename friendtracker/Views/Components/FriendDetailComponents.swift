import SwiftUI
import SwiftData

struct FriendInfoSection: View {
    let friend: Friend
    let onLastSeenTap: () -> Void
    
    var body: some View {
        Section {
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
                Text(friend.location)
                    .foregroundColor(AppColors.secondaryLabel)
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
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

struct FriendActionSection: View {
    let friend: Friend
    let onMessageTap: () -> Void
    let onScheduleTap: () -> Void
    let onMarkSeenTap: () -> Void
    
    var body: some View {
        Section {
            if friend.phoneNumber != nil {
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
            
            if friend.needsToConnectFlag {
                Button(action: { friend.needsToConnectFlag = false }) {
                    Label("Remove from Wishlist", systemImage: "star.slash")
                        .foregroundColor(AppColors.accent)
                }
            } else {
                Button(action: { friend.needsToConnectFlag = true }) {
                    Label("Add to Wishlist", systemImage: "star")
                        .foregroundColor(AppColors.accent)
                }
            }
        } header: {
            Text("Actions")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppColors.label)
                .textCase(nil)
                .padding(.bottom, 8)
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

struct FriendHangoutsSection: View {
    let hangouts: [Hangout]
    
    var body: some View {
        if !hangouts.isEmpty {
            Section {
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
            } header: {
                Text("Upcoming Hangouts")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppColors.label)
                    .textCase(nil)
                    .padding(.bottom, 8)
            }
            .listRowBackground(AppColors.secondarySystemBackground)
        }
    }
} 