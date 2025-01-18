import SwiftUI
import SwiftData

struct TagsSection: View {
    let friend: Friend
    let allTags: [Tag]
    let isEditMode: Bool
    @Binding var showingAddTagSheet: Bool
    let selectedTagsToDelete: Set<Tag.ID>
    let onTagSelection: (Tag) -> Void
    let onTagDeletion: (Tag) -> Void
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(allTags) { tag in
                let isSelected = friend.tags.contains(where: { $0.id == tag.id })
                TagButton(
                    tag: tag,
                    isSelected: isSelected,
                    isEditMode: isEditMode,
                    isMarkedForDeletion: selectedTagsToDelete.contains(tag.id),
                    onSelect: {
                        if isEditMode {
                            onTagDeletion(tag)
                        } else {
                            onTagSelection(tag)
                        }
                    }
                )
            }
        }
        .padding(.vertical, 8)
    }
}

struct TagsSectionPreviewContainer: View {
    let isEditMode: Bool
    @State private var showingAddTagSheet = false
    @State private var selectedTagsToDelete: Set<Tag.ID> = []
    let friend: Friend
    let tags: [Tag]
    
    init(isEditMode: Bool) {
        self.isEditMode = isEditMode
        
        // Create sample tags
        self.tags = [
            Tag(name: "college"),
            Tag(name: "book club"),
            Tag(name: "hiking"),
            Tag(name: "coffee buddy"),
            Tag(name: "work friend")
        ]
        
        // Create friend and assign tags
        let friend = Friend(name: "Preview Friend")
        friend.tags = [self.tags[0], self.tags[2]] // college and hiking
        self.friend = friend
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("TAGS") {
                    TagsSection(
                        friend: friend,
                        allTags: tags,
                        isEditMode: isEditMode,
                        showingAddTagSheet: $showingAddTagSheet,
                        selectedTagsToDelete: isEditMode ? [tags[0].id] : [],
                        onTagSelection: { _ in },
                        onTagDeletion: { _ in }
                    )
                }
            }
            .listStyle(.insetGrouped)
        }
        .modelContainer(for: [Friend.self, Tag.self])
    }
}

#Preview("Normal Mode") {
    TagsSectionPreviewContainer(isEditMode: false)
}

#Preview("Edit Mode") {
    TagsSectionPreviewContainer(isEditMode: true)
} 