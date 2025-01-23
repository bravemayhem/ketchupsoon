import SwiftUI
import SwiftData

struct TagsContentView: View {
    let selectionState: TagSelectionState
    let allTags: [Tag]
    @Binding var isEditMode: Bool
    @Binding var showingAddTagSheet: Bool
    @Binding var selectedTagsToDelete: Set<Tag.ID>
    let onTagSelection: (Tag) -> Void
    let onTagDeletion: (Tag) -> Void
    let onDeleteSelected: () -> Void
    
    private var friend: Friend? {
        if case .existingFriend(let friend) = selectionState {
            return friend
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("TAGS") {
                    TagsSection(
                        selectionState: selectionState,
                        allTags: allTags,
                        isEditMode: isEditMode,
                        showingAddTagSheet: $showingAddTagSheet,
                        selectedTagsToDelete: selectedTagsToDelete,
                        onTagSelection: onTagSelection,
                        onTagDeletion: onTagDeletion
                    )
                }
            }
            
            if !isEditMode {
                CreateTagButton(action: {
                    print("Create Tag button tapped")
                    showingAddTagSheet = true
                })
                .padding()
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.systemBackground)
        .navigationTitle("Manage Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !allTags.isEmpty {
                    Button(isEditMode ? "Done" : "Edit") {
                        withAnimation {
                            isEditMode.toggle()
                            if !isEditMode {
                                selectedTagsToDelete.removeAll()
                            }
                        }
                    }
                }
            }
            ToolbarItem(placement: .bottomBar) {
                if isEditMode && !selectedTagsToDelete.isEmpty {
                    Button(role: .destructive) {
                        onDeleteSelected()
                    } label: {
                        Text("Delete Selected (\(selectedTagsToDelete.count))")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTagSheet) {
            AddTagSheet(friend: friend)
        }
    }
}

struct TagsPreviewContainer: View {
    let friend: Friend
    let tags: [Tag]
    let isEditMode: Bool
    let selectedTagsToDelete: Set<Tag.ID>
    let container: ModelContainer
    
    init(isEditMode: Bool = false) {
        let schema = Schema([Friend.self, Tag.self, Hangout.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        // Create sample friend
        let friend = Friend(
            name: "Emma Thompson",
            lastSeen: Date(),
            location: "San Francisco"
        )
        
        // Create sample tags
        let tags = [
            Tag(name: "college"),
            Tag(name: "book club"),
            Tag(name: "hiking"),
            Tag(name: "coffee buddy")
        ]
        
        // Add some tags to friend
        friend.tags = [tags[0], tags[2]]  // college and hiking
        
        // Insert into context
        context.insert(friend)
        tags.forEach { context.insert($0) }
        
        self.friend = friend
        self.tags = tags
        self.isEditMode = isEditMode
        self.selectedTagsToDelete = isEditMode ? [tags[0].id] : []
        self.container = container
    }
    
    var body: some View {
        NavigationStack {
            TagsContentView(
                selectionState: .existingFriend(friend),
                allTags: tags,
                isEditMode: .constant(isEditMode),
                showingAddTagSheet: .constant(false),
                selectedTagsToDelete: .constant(selectedTagsToDelete),
                onTagSelection: { _ in },
                onTagDeletion: { _ in },
                onDeleteSelected: {}
            )
        }
        .modelContainer(container)
    }
}

#Preview("TagsContentView - Normal Mode") {
    TagsPreviewContainer(isEditMode: false)
}

#Preview("TagsContentView - Edit Mode") {
    TagsPreviewContainer(isEditMode: true)
} 
