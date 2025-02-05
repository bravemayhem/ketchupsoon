import SwiftUI
import SwiftData

struct FriendTagsSection: View {
    private var displayTags: [Tag]
    let onManageTags: () -> Void
    
    // Init for existing friends
    init(friend: Friend, onManageTags: @escaping () -> Void) {
        self.displayTags = friend.tags
        self.onManageTags = onManageTags
    }
    
    // Init for new friends (onboarding)
    init(tags: Set<Tag>, onManageTags: @escaping () -> Void) {
        self.displayTags = Array(tags)
        self.onManageTags = onManageTags
    }
    
    private var tagsContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(displayTags) { tag in
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
        Section("Tags") {
            if displayTags.isEmpty {
                Text("No tags added")
                    .foregroundColor(AppColors.secondaryLabel)
            } else {
                tagsContent
            }
            manageTags
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
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppColors.systemBackground)
        .clipShape(Capsule())
    }
}

#Preview("FriendTagsSection") {
    let schema = Schema([Friend.self, Tag.self, Hangout.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = container.mainContext
    
    let friend = Friend(
        name: "Bob Wilson",
        lastSeen: Date(),
        location: "Remote"
    )
    
    let tags = [
        Tag(name: "college"),
        Tag(name: "book club"),
        Tag(name: "hiking")
    ]
    tags.forEach { context.insert($0) }
    friend.tags = tags
    context.insert(friend)
    
    return NavigationStack {
        List {
            FriendTagsSection(
                friend: friend,
                onManageTags: {}
            )
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(container)
}

#Preview("TagView") {
    HStack {
        TagView(tag: Tag(name: "college"))
        TagView(tag: Tag(name: "book club"))
        TagView(tag: Tag(name: "hiking"))
    }
    .padding()
    .background(AppColors.secondarySystemBackground)
    .modelContainer(for: [Tag.self])
} 
