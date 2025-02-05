import SwiftUI
import SwiftData

struct TagPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTags: Set<Tag>
    let allTags: [Tag]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(allTags) { tag in
                    Button(action: {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }) {
                        HStack {
                            Text(tag.name)
                                .foregroundColor(AppColors.label)
                            Spacer()
                            if selectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                    .listRowBackground(AppColors.systemBackground)
                }
            }
            .navigationTitle("Filter by Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .destructiveAction) {
                    Button("Clear All") {
                        selectedTags.removeAll()
                        dismiss()
                    }
                    .foregroundColor(.red)
                    .opacity(selectedTags.isEmpty ? 0.5 : 1)
                    .disabled(selectedTags.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
} 