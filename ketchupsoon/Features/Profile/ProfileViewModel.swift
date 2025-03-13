import SwiftUI
import FirebaseAuth
import OSLog
import SwiftData
import Combine

// The profile view model protocol defines the shared interface for all profile view models

/// Protocol defining the shared interface for all profile view models
@MainActor
protocol ProfileViewModel: ObservableObject {
    // MARK: - Profile Data
    var id: String { get }
    var userName: String { get }
    var userBio: String { get }
    var profileImageURL: String? { get }
    var profileImage: UIImage? { get }
    var cachedProfileImage: UIImage? { get }
    var isLoadingImage: Bool { get }
    
    // MARK: - Profile Appearance
    var profileRingGradient: LinearGradient { get }
    var profileEmoji: String { get }
    
    // MARK: - UI State
    var isEditMode: Bool { get set }
    var isRefreshing: Bool { get set }
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    
    // MARK: - Methods
    func loadProfile() async
    func refreshProfile() async
    
    // Optional - implemented differently for user vs friend
    var canEdit: Bool { get }
    var showActions: Bool { get }
}

/// Default implementations of the ProfileViewModel protocol
extension ProfileViewModel {
    var profileEmoji: String { "😎" }
    var canEdit: Bool { false }
    var showActions: Bool { false }
    
    // Other default implementations as needed
}

/// Factory for creating the appropriate profile view model
@MainActor
enum ProfileViewModelFactory {
    @MainActor
    static func createViewModel(
        for profileType: ProfileType,
        modelContext: ModelContext,
        firebaseSyncService: FirebaseSyncService
    ) -> any ProfileViewModel {
        switch profileType {
            case .currentUser:
                return UserProfileViewModel(
                    modelContext: modelContext, 
                    firebaseSyncService: firebaseSyncService
                )
                
            case .friend(let friendModel):
                let friendshipRepository = FriendshipRepositoryFactory.createRepository(modelContext: modelContext)
                return FriendProfileViewModel(
                    friend: friendModel,
                    modelContext: modelContext,
                    firebaseSyncService: firebaseSyncService,
                    friendshipRepository: friendshipRepository
                )
        }
    }
}

/// Enum to define the type of profile being displayed
enum ProfileType {
    case currentUser
    case friend(UserModel)
}
