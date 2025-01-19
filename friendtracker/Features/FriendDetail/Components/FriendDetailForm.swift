import SwiftUI
import SwiftData


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
            
            // Use new initializer that takes a Set<Tag>
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

// MARK: - PREVIEWS

struct FriendDetailPreviewContainer: View {
    enum PreviewType {
        case basic
        case remote
        case detailed
    }
    
    let type: PreviewType
    let container: ModelContainer
    let friend: Friend
    
    init(type: PreviewType) {
        self.type = type
        
        let schema = Schema([Friend.self, Tag.self, Hangout.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        switch type {
        case .basic:
            let friend = Friend(
                name: "Emma Ze Stammen",
                lastSeen: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
                location: "Local",
                phoneNumber: "+1234567890"
            )
            context.insert(friend)
            self.friend = friend
            
        case .remote:
            let friend = Friend(
                name: "Emma Thompson",
                lastSeen: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
                location: "Remote",
                needsToConnectFlag: false,
                phoneNumber: "+1234567894",
                catchUpFrequency: .quarterly
            )
            context.insert(friend)
            self.friend = friend
            
        case .detailed:
            let friend = Friend(
                name: "Aleah Smith",
                lastSeen: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
                location: "San Francisco",
                needsToConnectFlag: true,
                phoneNumber: "(512) 348-4182",
                catchUpFrequency: .monthly
            )
            context.insert(friend)
            
            let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
            let hangout = Hangout(
                date: futureDate,
                activity: "Coffee",
                location: "Blue Bottle",
                isScheduled: true,
                friend: friend
            )
            context.insert(hangout)
            self.friend = friend
        }
        
        self.container = container
    }
    
    var body: some View {
        NavigationStack {
            FriendDetailForm(
                friend: friend,
                onLastSeenTap: {},
                onCityTap: {},
                onManageTags: {},
                onMessageTap: {},
                onScheduleTap: {},
                onMarkSeenTap: {}
            )
        }
        .modelContainer(container)
    }
}

#Preview("Basic Friend") {
    FriendDetailPreviewContainer(type: .basic)
}

#Preview("Remote Friend") {
    FriendDetailPreviewContainer(type: .remote)
}

#Preview("Friend with Details") {
    FriendDetailPreviewContainer(type: .detailed)
}
