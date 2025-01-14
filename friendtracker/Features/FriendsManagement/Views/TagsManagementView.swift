import SwiftUI
import SwiftData

struct TagsManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var friend: Friend
    @Query(sort: [SortDescriptor<Tag>(\.name)]) private var allTags: [Tag]
    @State private var newTagName = ""
    
    var body: some View {
        Form {
            Section("Current Tags") {
                if friend.tags.isEmpty {
                    Text("No tags added")
                        .foregroundColor(AppColors.secondaryLabel)
                } else {
                    ForEach(friend.tags) { tag in
                        HStack {
                            Text("#\(tag.name)")
                                .foregroundColor(AppColors.label)
                            Spacer()
                            if tag.isPredefined {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        do {
                            indexSet.forEach { index in
                                friend.tags.remove(at: index)
                            }
                            try modelContext.save()
                        } catch {
                            print("Error removing tag: \(error)")
                        }
                    }
                }
            }
            
            Section("Add New Tag") {
                HStack {
                    TextField("Tag name", text: $newTagName)
                    Button("Add") {
                        addNewTag()
                    }
                    .disabled(newTagName.isEmpty)
                }
            }
            
            Section("Suggested Tags") {
                let friendTagSet = Set(friend.tags)
                let unusedTags = allTags.filter { !friendTagSet.contains($0) }
                if unusedTags.isEmpty {
                    Text("No suggestions available")
                        .foregroundColor(AppColors.secondaryLabel)
                } else {
                    ForEach(unusedTags) { tag in
                        Button {
                            var updatedTags = friend.tags
                            updatedTags.append(tag)
                            friend.tags = updatedTags
                        } label: {
                            HStack {
                                Text("#\(tag.name)")
                                    .foregroundColor(AppColors.label)
                                Spacer()
                                if tag.isPredefined {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(AppColors.accent)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Manage Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(AppColors.accent)
            }
        }
    }
    
    private func addNewTag() {
        let tagName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !tagName.isEmpty else { return }
        
        do {
            if let existingTag = allTags.first(where: { $0.name == tagName }) {
                if !friend.tags.contains(existingTag) {
                    friend.tags.append(existingTag)
                }
            } else {
                let newTag = Tag(name: tagName)
                modelContext.insert(newTag)
                friend.tags.append(newTag)
            }
            try modelContext.save()
        } catch {
            print("Error saving tag: \(error)")
        }
        
        newTagName = ""
    }
}

#Preview {
    let previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Friend.self, Tag.self,
            configurations: config
        )
        
        // Create and insert sample data
        let friend = Friend(name: "Preview Friend")
        let tag1 = Tag(name: "climbing")
        let tag2 = Tag(name: "tech", isPredefined: true)
        container.mainContext.insert(friend)
        container.mainContext.insert(tag1)
        container.mainContext.insert(tag2)
        friend.tags = [tag1, tag2]
        
        try! container.mainContext.save()
        return container
    }()
    
    // Create a reference to the friend directly instead of fetching
    NavigationStack {
        if let friend = try? previewContainer.mainContext.fetch(FetchDescriptor<Friend>()).first {
            TagsManagementView(friend: friend)
                .modelContainer(previewContainer)
        } else {
            Text("Could not load preview")
        }
    }
} 
