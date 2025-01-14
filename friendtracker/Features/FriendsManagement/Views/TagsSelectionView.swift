import SwiftUI
import SwiftData

struct TagsSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var friend: Friend
    @Query(sort: [SortDescriptor<Tag>(\.name)]) private var allTags: [Tag]
    @State private var showingAddTagSheet = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Predefined Tags Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100, maximum: 200), spacing: 12)
                ], spacing: 12) {
                    ForEach(allTags.filter(\.isPredefined)) { tag in
                        TagCapsuleView(
                            tag: tag,
                            isSelected: friend.tags.contains(tag),
                            onTap: { toggleTag(tag) }
                        )
                    }
                    
                    // Add New Tag Button
                    Button(action: { showingAddTagSheet = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Tag")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.secondarySystemBackground)
                        .foregroundColor(AppColors.label)
                        .clipShape(Capsule())
                    }
                }
                .padding()
                
                // Custom Tags List
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Tags")
                        .font(AppTheme.headlineFont)
                        .padding(.horizontal)
                    
                    List {
                        ForEach(allTags.filter { !$0.isPredefined }) { tag in
                            HStack {
                                Text("#\(tag.name)")
                                    .font(AppTheme.bodyFont)
                                Spacer()
                                if friend.tags.contains(tag) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.accent)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleTag(tag)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteTag(tag)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Manage Tags")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddTagSheet) {
            AddTagSheet(friend: friend)
        }
    }
    
    private func toggleTag(_ tag: Tag) {
        if friend.tags.contains(tag) {
            friend.tags.removeAll { $0.id == tag.id }
        } else {
            friend.tags.append(tag)
        }
        try? modelContext.save()
    }
    
    private func deleteTag(_ tag: Tag) {
        friend.tags.removeAll { $0.id == tag.id }
        modelContext.delete(tag)
        try? modelContext.save()
    }
}

private struct TagCapsuleView: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text("#\(tag.name)")
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? AppColors.accent : AppColors.secondarySystemBackground)
            .foregroundColor(isSelected ? .white : AppColors.label)
            .clipShape(Capsule())
        }
    }
}

private struct AddTagSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var friend: Friend
    @State private var tagName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Tag name", text: $tagName)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
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
                        dismiss()
                    }
                    .disabled(tagName.isEmpty)
                }
            }
        }
    }
    
    private func createTag() {
        let normalizedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let tag = Tag(name: normalizedName)
        modelContext.insert(tag)
        friend.tags.append(tag)
        try? modelContext.save()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Friend.self, Tag.self, configurations: config)
    
    // Create sample data
    let friend = Friend(name: "Preview Friend")
    let predefinedTags = Tag.predefinedTags.map { Tag(name: $0, isPredefined: true) }
    let customTags = ["hiking", "book club", "coffee"].map { Tag(name: $0) }
    
    let context = container.mainContext
    context.insert(friend)
    predefinedTags.forEach { context.insert($0) }
    customTags.forEach { context.insert($0) }
    
    // Add some tags to friend
    friend.tags.append(predefinedTags[0])
    friend.tags.append(customTags[0])
    
    return NavigationStack {
        TagsSelectionView(friend: friend)
    }
    .modelContainer(container)
}
