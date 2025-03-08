import SwiftUI

struct FriendManagementBar: View {
    // MARK: - Properties
    let pendingFriendRequests: Int
    let onAddFriendTapped: () -> Void
    let onViewRequestsTapped: () -> Void
    
    // MARK: - Body
    var body: some View {
        ZStack {
            HStack(spacing: 12) {
                // Add friend button - flexible width
                Button(action: onAddFriendTapped) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("add friend")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 34)
                    .frame(maxWidth: .infinity) // Expand to fill available space
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [AppColors.gradient1Start, AppColors.gradient1End]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: AppColors.accent.opacity(0.5), radius: 8, x: 0, y: 0)
                }
                
                // Spacer to control the gap between buttons
                Spacer()
                    .frame(width: 0) // Control the exact spacing
                
                // Requests button - flexible width
                Button(action: onViewRequestsTapped) {
                    HStack {
                        Text("requests")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 34)
                    .frame(maxWidth: .infinity) // Expand to fill available space
                    .background(Color(UIColor.systemGray6).opacity(0.3))
                    .overlay(
                        Capsule()
                            .stroke(AppColors.purple.opacity(0.4), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                }
                .overlay(
                    // Notification badge
                    ZStack {
                        Circle()
                            .fill(AppColors.accent)
                            .frame(width: 24, height: 24)
                            .shadow(color: AppColors.accent.opacity(0.5), radius: 4, x: 0, y: 0)
                        
                        Text("\(pendingFriendRequests)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 8, y: -10), // Adjusted for perfect centering on the edge
                    alignment: .topTrailing
                )
            }
            .padding(.horizontal, 15)
        }
    }
}

// MARK: - Preview
struct FriendManagementBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            FriendManagementBar(
                pendingFriendRequests: 3,
                onAddFriendTapped: {},
                onViewRequestsTapped: {}
            )
            .padding(.horizontal, 20)
        }
    }
} 
