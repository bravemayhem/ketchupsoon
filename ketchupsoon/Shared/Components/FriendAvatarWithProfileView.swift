import SwiftUI
import SwiftData
import FirebaseAuth

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
    
    // Create a profile view for the friend using the shared ProfileFactory
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var firebaseSyncService: FirebaseSyncService
    
    private func createFriendProfileView() -> some View {
        // Determine gradient index based on the colors
        let gradientIndex = determineGradientIndex(friend.gradient)
        
        // Create a UserModel with all available data from FriendItem
        let user = UserModel(
            id: friend.id, // Use the string ID directly
            name: self.friend.name,
            profileImageURL: nil, // No URL in FriendItem
            email: self.friend.email,
            phoneNumber: self.friend.phoneNumber,
            bio: self.friend.bio,
            birthday: self.friend.birthday,
            gradientIndex: gradientIndex,
            createdAt: Date(), 
            updatedAt: Date()
        )
        
        // Use our new ProfileFactory to create the profile view
        return ProfileFactory.createProfileView(
            for: .friend(user),
            modelContext: modelContext,
            firebaseSyncService: firebaseSyncService
        )
    }
    
    // Helper function to determine which predefined gradient is being used
    private func determineGradientIndex(_ colors: [Color]) -> Int {
        // Return early if invalid colors array
        guard colors.count >= 2 else { return 0 }
        
        // Check against predefined gradient colors
        let startColor = colors[0]
        let endColor = colors[1]
        
        // Compare with known gradients
        if startColor == AppColors.gradient1Start && endColor == AppColors.gradient1End {
            return 0
        } else if startColor == AppColors.gradient2Start && endColor == AppColors.gradient2End {
            return 1
        } else if startColor == AppColors.gradient3Start && endColor == AppColors.gradient3End {
            return 2
        } else if startColor == AppColors.gradient4Start && endColor == AppColors.gradient4End {
            return 3
        } else if startColor == AppColors.gradient5Start && endColor == AppColors.gradient5End {
            return 4
        }
        
        // Default to the first gradient if no match is found
        return 0
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
