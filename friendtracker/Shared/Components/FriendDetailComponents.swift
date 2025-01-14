import SwiftUI
import SwiftData

struct FriendInfoSection: View {
    let friend: Friend
    let onLastSeenTap: () -> Void
    let onCityTap: () -> Void
    
    var body: some View {
        Section(content: {
            // Last Seen
            HStack {
                Text("Last Seen")
                    .foregroundColor(AppColors.label)
                Spacer()
                Button {
                    onLastSeenTap()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "hourglass")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                        Text(friend.lastSeenText)
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                }
            }
            
            // Location
            Button(action: onCityTap) {
                HStack {
                    Text("City")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    if let location = friend.location {
                        Text(location)
                            .foregroundColor(AppColors.secondaryLabel)
                    } else {
                        Text("Not set")
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                }
            }
            .foregroundColor(.primary)
            
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
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                        Text(frequency.displayText)
                            .foregroundColor(AppColors.secondaryLabel)
                    }
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
                        .actionLabelStyle()
                }
            }
            
            Button(action: onScheduleTap) {
                Label("Schedule Hangout", systemImage: "calendar")
                    .actionLabelStyle()
            }
            
            Button(action: onMarkSeenTap) {
                Label("Mark as Seen Today", systemImage: "checkmark.circle.fill")
                    .actionLabelStyle()
            }
            
            Button {
                friend.needsToConnectFlag.toggle()
            } label: {
                HStack {
                    Label(friend.needsToConnectFlag ? "Remove from Wishlist" : "Add to Wishlist",
                          systemImage: friend.needsToConnectFlag ? "star.slash" : "star")
                        .actionLabelStyle()
                    Spacer()
                    Toggle("", isOn: $friend.needsToConnectFlag)
                        .labelsHidden()
                        .tint(AppColors.accent)
                }
            }
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
            Section {
                // Content
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
                // Header
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

struct FriendTagsSection: View {
    @Bindable var friend: Friend
    let onManageTags: () -> Void
    
    private var tagsContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(friend.tags) { tag in
                    TagView(tag: tag)
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var manageTags: some View {
        Button(action: onManageTags) {
            Label("Manage Tags", systemImage: "tag")
                .actionLabelStyle()
        }
    }
    
    var body: some View {
        Section {
            if friend.tags.isEmpty {
                Text("No tags added")
                    .foregroundColor(AppColors.secondaryLabel)
            } else {
                tagsContent
            }
            manageTags
        } header: {
            Text("Tags")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppColors.label)
                .textCase(nil)
                .padding(.bottom, 8)
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}

// Helper view for individual tags
struct TagView: View {
    let tag: Tag
    
    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag.name)")
                .font(AppTheme.captionFont)
                .foregroundColor(AppColors.label)
            if tag.isPredefined {
                Image(systemName: "checkmark.seal.fill")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppColors.systemBackground)  // Changed to systemBackground (F2F2F7)
        .clipShape(Capsule())
    }
}
