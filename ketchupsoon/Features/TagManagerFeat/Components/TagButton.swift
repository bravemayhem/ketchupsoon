import SwiftUI

struct TagButton: View {
    let tag: Tag
    let isSelected: Bool
    let isEditMode: Bool
    let isMarkedForDeletion: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            print("Tag button '\(tag.name)' tapped")
            onSelect()
        }) {
            HStack {
                if isEditMode {
                    Image(systemName: isMarkedForDeletion ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isMarkedForDeletion ? .red : AppColors.secondaryLabel)
                        .font(.caption)
                }
                
                Text("#\(tag.name)")
                    .font(AppTheme.bodyFont)
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
                    .shadow(color: AppColors.label.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .foregroundColor(isSelected && !isEditMode ? .white : AppColors.label)
            .contentShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("TagButton States") {
    VStack(alignment: .leading, spacing: 20) {
        Group {
            // Normal state
            TagButton(
                tag: Tag(name: "hiking"),
                isSelected: false,
                isEditMode: false,
                isMarkedForDeletion: false,
                onSelect: {}
            )
            
            // Selected state
            TagButton(
                tag: Tag(name: "book club"),
                isSelected: true,
                isEditMode: false,
                isMarkedForDeletion: false,
                onSelect: {}
            )
            
            // Edit mode
            TagButton(
                tag: Tag(name: "coffee"),
                isSelected: false,
                isEditMode: true,
                isMarkedForDeletion: false,
                onSelect: {}
            )
            
            // Marked for deletion
            TagButton(
                tag: Tag(name: "movies"),
                isSelected: false,
                isEditMode: true,
                isMarkedForDeletion: true,
                onSelect: {}
            )
        }
    }
    .padding()
    .background(AppColors.secondarySystemBackground)
    .modelContainer(for: Tag.self)
} 