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
                        .foregroundColor(isMarkedForDeletion ? .red : .gray)
                        .font(.caption)
                }
                
                Text("#\(tag.name)")
                    .font(.body)
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
            )
            .foregroundColor(isSelected && !isEditMode ? .white : AppColors.label)
            .contentShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
} 