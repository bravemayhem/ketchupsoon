import SwiftUI
import SwiftData
import FirebaseAuth

/// Factory for creating profile views
@MainActor
enum ProfileFactory {
    /// Create an appropriate ProfileView based on the profile type
    /// - Parameters:
    ///   - profileType: The type of profile (.currentUser or .friend)
    ///   - modelContext: The SwiftData ModelContext
    ///   - firebaseSyncService: The Firebase sync service
    /// - Returns: A ProfileView configured for the specified profile type
    @MainActor
    static func createProfileView(
        for profileType: ProfileType,
        modelContext: ModelContext,
        firebaseSyncService: FirebaseSyncService
    ) -> some View {
        let viewModel = ProfileViewModelFactory.createViewModel(
            for: profileType,
            modelContext: modelContext,
            firebaseSyncService: firebaseSyncService
        )
        
        switch viewModel {
        case let userViewModel as UserProfileViewModel:
            return AnyView(ProfileView(viewModel: userViewModel)
                .environmentObject(firebaseSyncService))
            
        case let friendViewModel as FriendProfileViewModel:
            return AnyView(ProfileView(viewModel: friendViewModel)
                .environmentObject(firebaseSyncService))
            
        default:
            // This should never happen if the factory is properly implemented
            return AnyView(Text("Invalid profile type"))
        }
    }
}
