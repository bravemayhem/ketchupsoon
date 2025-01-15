import SwiftUI
import SwiftData

struct TagsSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var friend: Friend
    @Query(sort: [SortDescriptor<Tag>(\.name)]) private var allTags: [Tag]
    @State private var showingAddTagSheet = false
    
    var body: some View {
        Form {
            Section("TAGS") {
                VStack(alignment: .leading) {
                    FlowLayout(spacing: 8) {
                        // Regular tag capsules
                        ForEach(allTags) { tag in
                            SelectableTagView(
                                name: tag.name,
                                isSelected: friend.tags.contains(tag)
                            ) {
                                toggleTag(tag)
                            }
                        }
                    }
                    
                    // Create Tag button
                    Button(action: { showingAddTagSheet = true }) {
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
                .padding(.vertical, 8)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.systemBackground)
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
}

struct SelectableTagView: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("#\(name)")
                    .font(.body)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? AppColors.accent : AppColors.systemBackground)
            )
            .foregroundColor(isSelected ? .white : AppColors.label)
        }
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
