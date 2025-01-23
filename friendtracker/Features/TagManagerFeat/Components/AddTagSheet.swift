import SwiftUI
import SwiftData

enum TagError: LocalizedError {
    case duplicateTag
    
    var errorDescription: String? {
        switch self {
        case .duplicateTag:
            return "Tag name already exists"
        }
    }
}

struct AddTagSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let friend: Friend?
    @State private var tagName = ""
    @State private var error: TagError?
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Tag name", text: $tagName)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppColors.label)
                        .onSubmit {
                            if !tagName.isEmpty {
                                createTag()
                            }
                        }
                        .submitLabel(.done)
                }
                .listRowBackground(AppColors.secondarySystemBackground)
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
                    .foregroundColor(AppColors.label)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        createTag()
                    }
                    .disabled(tagName.isEmpty)
                    .foregroundColor(tagName.isEmpty ? AppColors.tertiaryLabel : AppColors.accent)
                }
            }
        }
        .background(AppColors.systemBackground)
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    private func createTag() {
        let normalizedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Check for existing tag
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.name == normalizedName
            }
        )
        
        do {
            let existingTags = try modelContext.fetch(descriptor)
            if !existingTags.isEmpty {
                error = .duplicateTag
                showingError = true
                return
            }
            
            let tag = Tag(name: normalizedName, isPredefined: false)
            modelContext.insert(tag)
            
            // If we have a friend, associate the tag with them
            if let friend = friend {
                friend.tags.append(tag)
            }
            
            dismiss()
        } catch {
            print("Error creating tag: \(error)")
            showingError = true
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Friend.self, Tag.self, configurations: config)
    
    let friend = Friend(name: "Test Friend")
    let context = container.mainContext
    context.insert(friend)
    
    let existingTags = ["coffee", "work", "gym"]
    for tagName in existingTags {
        let tag = Tag(name: tagName)
        context.insert(tag)
    }
    
    return AddTagSheet(friend: friend)
        .modelContainer(container)
} 