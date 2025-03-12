import SwiftUI
import SwiftData
import FirebaseAuth

/// Protocol that defines all friendship-related data operations
/// This provides a clean abstraction over the underlying data source (Firebase, local, etc.)
protocol FriendshipRepository {
    // MARK: - Friendship Fetching
    
    /// Get a friendship by its UUID
    func getFriendship(id: UUID) async throws -> FriendshipModel
    
    /// Get all friendships for the current user
    func getFriendshipsForCurrentUser() async throws -> [FriendshipModel]
    
    /// Get a specific friendship between the current user and a friend
    func getFriendship(currentUserID: String, friendID: String) async throws -> FriendshipModel?
    
    // MARK: - Friendship Management
    
    /// Create a new friendship between users
    func createFriendship(friendship: FriendshipModel) async throws
    
    /// Update an existing friendship
    func updateFriendship(friendship: FriendshipModel) async throws
    
    /// Delete a friendship
    func deleteFriendship(id: UUID) async throws
    
    /// Remove friendship between the current user and a specific friend
    func removeFriendship(currentUserID: String, friendID: String) async throws
    
    // MARK: - Special Operations
    
    /// Check if a friendship exists between two users
    func checkFriendshipExists(currentUserID: String, friendID: String) async throws -> Bool
    
    /// Get all friends of the current user with their user profiles
    func getFriendsWithProfiles(currentUserID: String) async throws -> [(FriendshipModel, UserModel)]
    
    /// Get count of pending friend requests for a user
    func getPendingFriendRequestsCount(for userID: String) async throws -> Int
    
    /// Sync local friendships with remote data
    func syncLocalWithRemote(for userID: String) async throws
}

/// Factory for creating FriendshipRepository instances
struct FriendshipRepositoryFactory {
    /// Create the default repository implementation
    @MainActor
    static func createRepository(modelContext: ModelContext) -> FriendshipRepository {
        return FirebaseFriendshipRepository(modelContext: modelContext)
    }
    
    /// Create a mock repository for previews or testing
    @MainActor
    static func createMockRepository() -> FriendshipRepository {
        let container = try! ModelContainer(for: FriendshipModel.self, UserModel.self)
        return FirebaseFriendshipRepository(modelContext: container.mainContext)
    }
}
