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
    @State private var error: Error?
    @State private var showingError = false
    
    var body: some View {
        TagsContentView(
            friend: friend,
            allTags: allTags,
            isEditMode: $isEditMode,
            showingAddTagSheet: $showingAddTagSheet,
            selectedTagsToDelete: $selectedTagsToDelete,
            onTagSelection: handleTagSelection,
            onTagDeletion: toggleTagDeletion,
            onDeleteSelected: deleteTags
        )
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
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
        do {
            try Tag.toggleSelection(of: tag, for: friend, context: modelContext)
        } catch {
            self.error = error
            self.showingError = true
        }
    }
    
    private func deleteTags() {
        let tagsToDelete = allTags.filter { selectedTagsToDelete.contains($0.id) }
        do {
            try Tag.delete(tagsToDelete, context: modelContext)
            selectedTagsToDelete.removeAll()
            isEditMode = false
        } catch {
            self.error = error
            self.showingError = true
        }
    }
}

// MARK: - Preview Provider
struct TagsSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Friend.self, Tag.self, configurations: config)
        
        let friend = Friend(name: "Test Friend")
        let context = container.mainContext
        context.insert(friend)
        
        for tagName in Tag.predefinedTags {
            let tag = Tag.createPredefinedTag(tagName)
            context.insert(tag)
        }
        
        for tagName in ["book club", "coffee", "hiking"] {
            let tag = Tag(name: tagName)
            context.insert(tag)
        }
        
        return NavigationStack {
            TagsSelectionView(friend: friend)
        }
        .modelContainer(container)
    }
}
