import SwiftUI
import SwiftData

/// A shared form component for displaying and editing friend information.
/// This component provides a consistent layout and styling for friend-related forms
/// across the app.
///
/// Used by:
/// - FriendExistingView: For viewing and editing existing friends
/// - FriendOnboardingView: For adding new friends
struct FriendDetailForm: View {
    @Bindable var friend: Friend
    let onLastSeenTap: () -> Void
    let onCityTap: () -> Void
    let onManageTags: () -> Void
    let onMessageTap: () -> Void
    let onScheduleTap: () -> Void
    let onMarkSeenTap: () -> Void
    
    var body: some View {
        List {
            FriendInfoSection(
                friend: friend,
                onLastSeenTap: onLastSeenTap,
                onCityTap: onCityTap
            )
            
            FriendTagsSection(
                friend: friend,
                onManageTags: onManageTags
            )
            
            FriendActionSection(
                friend: friend,
                onMessageTap: onMessageTap,
                onScheduleTap: onScheduleTap,
                onMarkSeenTap: onMarkSeenTap
            )
            
            FriendHangoutsSection(hangouts: friend.scheduledHangouts)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .listSectionSpacing(20)
        .environment(\.defaultMinListHeaderHeight, 0)
        .background(AppColors.systemBackground)
    }
}

#Preview {
    FriendDetailForm(
        friend: Friend(
            name: "Preview Friend",
            lastSeen: Date(),
            location: "Local",
            phoneNumber: "+1234567890"
        ),
        onLastSeenTap: {},
        onCityTap: {},
        onManageTags: {},
        onMessageTap: {},
        onScheduleTap: {},
        onMarkSeenTap: {}
    )
    .modelContainer(for: Friend.self)
} 