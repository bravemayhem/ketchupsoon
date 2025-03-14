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
        
        // Now we're directly using the concrete CombinedProfileViewModel, no need for type casting
        return AnyView(ProfileView(viewModel: viewModel)
            .environmentObject(firebaseSyncService))
    }
}
