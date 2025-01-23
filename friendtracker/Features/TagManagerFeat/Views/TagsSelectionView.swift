// UI and User Interactions

import SwiftUI
import SwiftData

struct TagsSelectionView: View {
    // MARK: - Environment & State
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor<Tag>(\.name)]) private var allTags: [Tag]
    
    // MARK: - View State
    @State private var showingAddTagSheet = false
    @State private var isEditMode = false
    @State private var selectedTagsToDelete: Set<Tag.ID> = []
    @State private var error: Error?
    @State private var showingError = false
    
    // MARK: - Properties
    private let friend: Friend?
    @Binding private var selectedTags: Set<Tag>
    
    private var selectionState: TagSelectionState {
        if let friend = friend {
            return .existingFriend(friend)
        } else {
            return .newFriend(selectedTags: Set(selectedTags.map { $0.id }))
        }
    }
    
    // MARK: - Initialization
    init(friend: Friend) {
        self.friend = friend
        self._selectedTags = .constant([]) // Dummy binding since using friend
    }
    
    init(selectedTags: Binding<Set<Tag>>) {
        self.friend = nil
        self._selectedTags = selectedTags
    }
    
    // MARK: - User Actions
    private func handleTagSelection(_ tag: Tag) {
        if let friend = friend {
            do {
                try Tag.toggleSelection(of: tag, for: friend, context: modelContext)
            } catch {
                self.error = error
                self.showingError = true
            }
        } else {
            // Direct tag selection for new friend
            if selectedTags.contains(tag) {
                selectedTags.remove(tag)
            } else {
                selectedTags.insert(tag)
            }
        }
    }
    
    private func toggleTagDeletion(_ tag: Tag) {
        if selectedTagsToDelete.contains(tag.id) {
            selectedTagsToDelete.remove(tag.id)
        } else {
            selectedTagsToDelete.insert(tag.id)
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
    
    // MARK: - Body
    var body: some View {
        TagsContentView(
            selectionState: selectionState,
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
        .sheet(isPresented: $showingAddTagSheet) {
            AddTagSheet(friend: friend)
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
