import SwiftUI

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