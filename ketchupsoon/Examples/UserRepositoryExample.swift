import SwiftUI
import SwiftData

/// Example view demonstrating how to use the UserRepository
struct UserRepositoryExampleView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentUser: UserModel?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Create a repository instance using the factory
    private var userRepository: UserRepository {
        UserRepositoryFactory.createRepository(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Current User") {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if let user = currentUser {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(user.name ?? "No Name")
                                .font(.headline)
                            
                            if let email = user.email {
                                Text("Email: \(email)")
                                    .font(.subheadline)
                            }
                            
                            if let phone = user.phoneNumber {
                                Text("Phone: \(phone)")
                                    .font(.subheadline)
                            }
                            
                            Button("Update Bio") {
                                updateUserBio()
                            }
                            .padding(.top, 8)
                        }
                    } else {
                        Text("No user logged in")
                            .foregroundColor(.secondary)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section("Actions") {
                    Button("Refresh Current User") {
                        Task {
                            await loadCurrentUser()
                        }
                    }
                    
                    Button("Sync with Firebase") {
                        Task {
                            await syncWithFirebase()
                        }
                    }
                }
            }
            .navigationTitle("User Repository Demo")
            .task {
                await loadCurrentUser()
            }
        }
    }
    
    // MARK: - Repository Actions
    
    /// Load the current user using the repository
    private func loadCurrentUser() async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentUser = try await userRepository.getCurrentUser()
        } catch {
            errorMessage = "Error loading user: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Sync local data with Firebase
    private func syncWithFirebase() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await userRepository.syncLocalWithRemote()
            // Reload user after sync
            await loadCurrentUser()
        } catch {
            errorMessage = "Sync error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Example of updating a user field
    private func updateUserBio() {
        guard let user = currentUser else { return }
        
        // Create a mutable copy
        let updatedUser = UserModel()
        updatedUser.id = user.id
        updatedUser.name = user.name
        updatedUser.email = user.email
        updatedUser.profileImageURL = user.profileImageURL
        // Add other properties as needed
        
        // Update the bio
        updatedUser.bio = "Updated at \(Date().formatted(date: .numeric, time: .shortened))"
        
        // Save changes
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                try await userRepository.updateUser(user: updatedUser)
                await loadCurrentUser() // Reload to see changes
            } catch {
                errorMessage = "Update error: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
}

/// Example showing how to integrate UserRepository in a view model
class ProfileViewModel: ObservableObject {
    @Published var user: UserModel?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userRepository: UserRepository
    
    init(repository: UserRepository) {
        self.userRepository = repository
    }
    
    func loadUser() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let loadedUser = try await userRepository.getCurrentUser()
                
                await MainActor.run {
                    self.user = loadedUser
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Could not load user: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func updateProfile(name: String, email: String, bio: String) {
        guard let user = self.user else { return }
        
        // Create a new instance with updated properties
        let updatedUser = UserModel()
        updatedUser.id = user.id
        // Set the updated values
        updatedUser.name = name
        updatedUser.email = email
        updatedUser.bio = bio
        // Copy other properties that should be preserved
        updatedUser.profileImageURL = user.profileImageURL
        // Add other properties as needed
        
        isLoading = true
        
        // Capture a local copy for the task
        let userToUpdate = updatedUser
        
        Task {
            do {
                try await userRepository.updateUser(user: userToUpdate)
                
                await MainActor.run {
                    self.user = userToUpdate
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Update failed: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

// Preview for the example view
#Preview {
    let container = try! ModelContainer(for: UserModel.self)
    return UserRepositoryExampleView()
        .modelContainer(container)
} 