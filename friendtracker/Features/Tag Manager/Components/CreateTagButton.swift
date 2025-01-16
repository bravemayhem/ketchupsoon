import SwiftUI

struct CreateTagButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            print("Create Tag button tapped")
            action()
        }) {
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
            .contentShape(Capsule())
        }
    }
} 