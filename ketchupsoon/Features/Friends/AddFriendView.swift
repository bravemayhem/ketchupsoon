import SwiftUI
import FirebaseFirestore
import SwiftData

struct AddFriendView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchQuery = ""
    @State private var searchResult: UserProfile?
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var friendAdded = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Friend search section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Find Friends")
                        .font(.headline)
                    
                    TextField("Email or phone number", text: $searchQuery)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Button(action: searchForUser) {
                        HStack {
                            Spacer()
                            if isSearching {
                                ProgressView()
                            } else {
                                Text("Search")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(AppColors.accent)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(searchQuery.isEmpty || isSearching)
                }
                .padding(.horizontal)
                
                // Display search result
                if let profile = searchResult {
                    VStack(spacing: 12) {
                        if let photoURL = profile.profileImageURL,
                           !photoURL.isEmpty {
                            AsyncImage(url: URL(string: photoURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(AppColors.avatarColor(for: profile.name ?? "User"))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(getInitials(from: profile.name ?? "User"))
                                        .font(.system(size: 30, weight: .medium))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        Text(profile.name ?? "Unnamed User")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        if let email = profile.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if !friendAdded {
                            Button(action: addFriend) {
                                HStack {
                                    Spacer()
                                    Text("Add Friend")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                .padding()
                                .background(AppColors.accent)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        } else {
                            Text("Friend Added")
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                                .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK") { 
                    if friendAdded {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchForUser() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        searchResult = nil
        
        let db = Firestore.firestore()
        let usersCollection = db.collection("users")
        
        // Try to search by email first
        let emailQuery = usersCollection.whereField("email", isEqualTo: searchQuery)
        
        Task {
            do {
                let snapshot = try await emailQuery.getDocuments()
                
                if !snapshot.documents.isEmpty {
                    // Process first matching user
                    if let userData = snapshot.documents.first?.data(),
                       let userId = userData["id"] as? String {
                        let name = userData["name"] as? String
                        let email = userData["email"] as? String
                        let phoneNumber = userData["phoneNumber"] as? String
                        let bio = userData["bio"] as? String
                        let profileImageURL = userData["profileImageURL"] as? String
                        
                        // Skip if it's the current user
                        if userId == profileManager.currentUserProfile?.id {
                            await MainActor.run {
                                isSearching = false
                                errorMessage = "You cannot add yourself as a friend."
                            }
                            return
                        }
                        
                        let userProfile = UserProfile(
                            id: userId,
                            name: name,
                            email: email,
                            phoneNumber: phoneNumber,
                            bio: bio,
                            profileImageURL: profileImageURL
                        )
                        
                        await MainActor.run {
                            searchResult = userProfile
                            isSearching = false
                        }
                    }
                } else {
                    // If not found by email, try phone number
                    let phoneQuery = usersCollection.whereField("phoneNumber", isEqualTo: searchQuery)
                    let phoneSnapshot = try await phoneQuery.getDocuments()
                    
                    if !phoneSnapshot.documents.isEmpty {
                        // Process first matching user
                        if let userData = phoneSnapshot.documents.first?.data(),
                           let userId = userData["id"] as? String {
                            let name = userData["name"] as? String
                            let email = userData["email"] as? String
                            let phoneNumber = userData["phoneNumber"] as? String
                            let bio = userData["bio"] as? String
                            let profileImageURL = userData["profileImageURL"] as? String
                            
                            // Skip if it's the current user
                            if userId == profileManager.currentUserProfile?.id {
                                await MainActor.run {
                                    isSearching = false
                                    errorMessage = "You cannot add yourself as a friend."
                                }
                                return
                            }
                            
                            let userProfile = UserProfile(
                                id: userId,
                                name: name,
                                email: email,
                                phoneNumber: phoneNumber,
                                bio: bio,
                                profileImageURL: profileImageURL
                            )
                            
                            await MainActor.run {
                                searchResult = userProfile
                                isSearching = false
                            }
                        }
                    } else {
                        await MainActor.run {
                            isSearching = false
                            errorMessage = "No user found with that email or phone number."
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    errorMessage = "Error searching for user: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func addFriend() {
        guard let userToAdd = searchResult else { return }
        
        // Create a Friend object and add it to SwiftData using the convenience initializer
        let newFriend = Friend(from: userToAdd)
        
        modelContext.insert(newFriend)
        
        // Show confirmation
        friendAdded = true
        alertMessage = "Friend added successfully!"
        showAlert = true
    }
    
    private func getInitials(from name: String) -> String {
        name.components(separatedBy: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
    }
}

#Preview {
    AddFriendView()
        .modelContainer(for: [Friend.self], inMemory: true)
} 