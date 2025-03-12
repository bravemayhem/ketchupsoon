import SwiftUI
import SwiftData
import FirebaseAuth

/// Protocol that defines all user-related data operations
/// This provides a clean abstraction over the underlying data source (Firebase, local, etc.)
protocol UserRepository {
    // MARK: - User Fetching
    /// Get a user by their ID
    func getUser(id: String) async throws -> UserModel
    
    /// Get the currently authenticated user
    func getCurrentUser() async throws -> UserModel?
    
    /// Search for users by name or other criteria
    func searchUsers(query: String) async throws -> [UserModel]
    
    // MARK: - User Management
    /// Create a new user profile
    func createUser(user: UserModel) async throws
    
    /// Update an existing user profile
    func updateUser(user: UserModel) async throws
    
    /// Delete a user profile
    func deleteUser(id: String) async throws
    
    // MARK: - Special Operations
    /// Find and link a user based on their email or phone number
    func linkUserWithFirebase(email: String, phoneNumber: String) async throws -> UserModel?
    
    /// Refresh data for the current user from Firebase
    func refreshCurrentUser() async throws
    
    /// Sync local data with remote data
    func syncLocalWithRemote() async throws
}

/// Factory for creating UserRepository instances
struct UserRepositoryFactory {
    /// Create the default repository implementation
    @MainActor
    static func createRepository(modelContext: ModelContext) -> UserRepository {
        return FirebaseUserRepository(modelContext: modelContext)
    }
    
    /// Create a mock repository for previews or testing
    @MainActor
    static func createMockRepository() -> UserRepository {
        // You could implement a mock version here
        let container = try! ModelContainer(for: UserModel.self)
        return FirebaseUserRepository(modelContext: container.mainContext)
    }
} 