import SwiftUI

struct TagsContentView: View {
    let friend: Friend
    let allTags: [Tag]
    @Binding var isEditMode: Bool
    @Binding var showingAddTagSheet: Bool
    @Binding var selectedTagsToDelete: Set<Tag.ID>
    let onTagSelection: (Tag) -> Void
    let onTagDeletion: (Tag) -> Void
    let onDeleteSelected: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("TAGS") {
                    TagsSection(
                        friend: friend,
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
