import SwiftUI
import SwiftData

struct FriendAvatarWithProfileView: View {
    let friend: FriendItem
    var isSelected: Bool = false
    var onSelect: (() -> Void)? = nil
    
    @State private var showingProfile = false
    @GestureState private var isLongPressing = false
    
    var body: some View {
        ZStack {
            // Replace deprecated NavigationLink with a button that triggers navigation
            FriendAvatarView(
                friend: friend,
                isSelected: isSelected,
                onSelect: onSelect
            )
            .scaleEffect(isLongPressing ? 1.1 : 1.0) // Visual feedback for debugging
            // Use simultaneousGesture instead of onLongPressGesture
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        print("Long press detected on \(friend.name)") // Debug print
                        showingProfile = true
                    }
                    .updating($isLongPressing) { currentState, gestureState, _ in
                        gestureState = currentState
                    }
            )
        }
        .navigationDestination(isPresented: $showingProfile) {
            createFriendProfileView()
        }
    }
    
    // Create a Friend model from FriendItem for the profile view
    private func createFriendProfileView() -> some View {
        // Create a sample Friend with the data we have from FriendItem
        let friend = Friend(
            id: UUID(), // Create a new ID
            name: self.friend.name,
            profileImageURL: nil, // No URL in FriendItem
            bio: "This is \(self.friend.name)'s profile", // Sample bio
            createdAt: Date(), 
            updatedAt: Date()
        )
        
        return FriendProfileView(friend: friend)
    }
}

#Preview {
    NavigationStack {
        FriendAvatarWithProfileView(
            friend: FriendItem(
                id: "1", 
                name: "sarah", 
                emoji: "🌟", 
                lastHangout: "3 months", 
                gradient: [AppColors.gradient1Start, AppColors.gradient1End]
            )
        )
    }
    .preferredColorScheme(.dark)
} 