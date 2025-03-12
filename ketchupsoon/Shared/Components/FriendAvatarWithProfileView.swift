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
        // Create a Friend with all available data from FriendItem
        let friend = FriendModel(
            id: UUID(), // Create a new ID
            name: self.friend.name,
            profileImageURL: nil, // No URL in FriendItem
            email: self.friend.email,
            phoneNumber: self.friend.phoneNumber,
            bio: self.friend.bio,
            birthday: self.friend.birthday,
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
                name: "Sarah Johnson",
                bio: "Adventure seeker and coffee enthusiast. Always up for hiking or trying new cafes.",                
                phoneNumber: "+1 (206) 555-1234",
                email: "sarah.j@example.com",
                birthday: Date(timeIntervalSince1970: 791394000), // 1995-02-30
                emoji: "🌟",
                lastHangout: "3 months",
                gradient: [AppColors.gradient1Start, AppColors.gradient1End]
            )
        )
    }
    .preferredColorScheme(.dark)
} 
