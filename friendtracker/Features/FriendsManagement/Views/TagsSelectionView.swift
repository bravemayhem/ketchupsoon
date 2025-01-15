import SwiftUI
import SwiftData

struct TagsSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var friend: Friend
    @Query(sort: [SortDescriptor<Tag>(\.name)]) private var allTags: [Tag]
    @State private var showingAddTagSheet = false
    @State private var isEditMode = false
    @State private var selectedTagsToDelete: Set<Tag.ID> = []
    
    var body: some View {
        Form {
            Section("TAGS") {
                VStack(alignment: .leading, spacing: 12) {
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
                                        toggleTagDeletion(tag)
                                    } else {
                                        handleTagSelection(tag)
                                    }
                                }
                            )
                        }
                    }
                    
                    if !isEditMode {
                        CreateTagButton(action: {
                            showingAddTagSheet = true
                        })
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.systemBackground)
        .navigationTitle("Manage Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !allTags.isEmpty {
                    Button(isEditMode ? "Done" : "Edit") {
                        isEditMode.toggle()
                        if !isEditMode {
                            selectedTagsToDelete.removeAll()
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                if isEditMode && !selectedTagsToDelete.isEmpty {
                    Button(role: .destructive) {
                        deleteTags()
                    } label: {
                        Text("Delete Selected (\(selectedTagsToDelete.count))")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTagSheet) {
            AddTagSheet(friend: friend)
        }
    }
    
    private func toggleTagDeletion(_ tag: Tag) {
        if selectedTagsToDelete.contains(tag.id) {
            selectedTagsToDelete.remove(tag.id)
        } else {
            selectedTagsToDelete.insert(tag.id)
        }
    }
    
    private func handleTagSelection(_ tag: Tag) {
        if friend.tags.contains(where: { $0.id == tag.id }) {
            friend.tags.removeAll(where: { $0.id == tag.id })
        } else {
            friend.tags.append(tag)
        }
        try? modelContext.save()
    }
    
    private func deleteTags() {
        // Get all tags marked for deletion
        let tagsToDelete = allTags.filter { selectedTagsToDelete.contains($0.id) }
        
        // Remove tags from all friends that have them
        for tag in tagsToDelete {
            for friend in tag.friends {
                friend.tags.removeAll(where: { $0.id == tag.id })
            }
            modelContext.delete(tag)
        }
        
        try? modelContext.save()
        selectedTagsToDelete.removeAll()
        isEditMode = false
    }
}

private struct TagButton: View {
    let tag: Tag
    let isSelected: Bool
    let isEditMode: Bool
    let isMarkedForDeletion: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                if isEditMode {
                    Image(systemName: isMarkedForDeletion ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isMarkedForDeletion ? .red : .gray)
                        .font(.caption)
                }
                
                Text("#\(tag.name)")
                    .font(.body)
                if isSelected && !isEditMode {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected && !isEditMode ? AppColors.accent : AppColors.systemBackground)
            )
            .foregroundColor(isSelected && !isEditMode ? .white : AppColors.label)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct CreateTagButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Create Tag")
                    .font(.body)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundColor(AppColors.label)
            .background(AppColors.systemBackground)
            .clipShape(Capsule())
        }
    }
}

private struct AddTagSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var friend: Friend
    @State private var tagName = ""
    @State private var showingDuplicateAlert = false
    @Query(sort: [SortDescriptor<Tag>(\.name)]) private var existingTags: [Tag]
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Tag name", text: $tagName)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .font(.body)
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.systemBackground)
            .navigationTitle("Create Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        createTag()
                    }
                    .disabled(tagName.isEmpty)
                }
            }
            .alert("Duplicate Tag", isPresented: $showingDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A tag with this name already exists.")
            }
        }
    }
    
    private func createTag() {
        let normalizedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if existingTags.contains(where: { $0.name == normalizedName }) {
            showingDuplicateAlert = true
            return
        }
        
        let tag = Tag(name: normalizedName)
        modelContext.insert(tag)
        friend.tags.append(tag)
        try? modelContext.save()
        dismiss()
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if x + size.width > width {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
            height = y + maxHeight
        }
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            view.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(size)
            )
            
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Friend.self, Tag.self, configurations: config)
    
    // Create test friend
    let friend = Friend(name: "Test Friend")
    
    let context = container.mainContext
    context.insert(friend)
    
    // Create and insert predefined tags
    for tagName in Tag.predefinedTags {
        let tag = Tag.createPredefinedTag(tagName)
        context.insert(tag)
    }
    
    // Create and insert some custom tags
    for tagName in ["book club", "coffee", "hiking"] {
        let tag = Tag(name: tagName)
        context.insert(tag)
    }
    
    return NavigationStack {
        TagsSelectionView(friend: friend)
    }
    .modelContainer(container)
}
