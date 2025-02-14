import SwiftUI
import SwiftData
import OSLog

struct FriendActionSection: View {
    @Bindable var friend: Friend
    let onMessageTap: () -> Void
    let onScheduleTap: () -> Void
    let onMarkSeenTap: () -> Void
    private static let logger = Logger(subsystem: "com.friendtracker", category: "WishlistActions")
    
    var body: some View {
        Section("Actions") {
            Button(action: onMessageTap) {
                Label("Send Message", systemImage: "message.fill")
                    .actionLabelStyle()
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
                Self.logger.info("🌟 Wishlist button tapped for friend: \(friend.name)")
                Self.logger.info("🌟 Current wishlist status: \(friend.needsToConnectFlag)")
                
                withAnimation {
                    friend.needsToConnectFlag.toggle()
                    Self.logger.info("🌟 New wishlist status: \(friend.needsToConnectFlag)")
                }
            } label: {
                Label(friend.needsToConnectFlag ? "Remove from Wishlist" : "Add to Wishlist",
                      systemImage: friend.needsToConnectFlag ? "star.slash" : "star")
                    .actionLabelStyle()
            }
            .tint(friend.needsToConnectFlag ? .red : AppColors.accent)
        }
        .listRowBackground(AppColors.secondarySystemBackground)
        .onAppear {
            Self.logger.info("⚡️ FriendActionSection appeared for friend: \(friend.name)")
            Self.logger.info("⚡️ Initial wishlist status: \(friend.needsToConnectFlag)")
        }
    }
}

#Preview {
    NavigationStack {
        List {
            FriendActionSection(
                friend: Friend(
                    name: "John Doe",
                    lastSeen: Date(),
                    location: "New York",
                    needsToConnectFlag: true,
                    phoneNumber: "(212) 555-0123",
                    catchUpFrequency: .weekly
                ),
                onMessageTap: {},
                onScheduleTap: {},
                onMarkSeenTap: {}
            )
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(for: [Friend.self, Tag.self, Hangout.self])
} 



