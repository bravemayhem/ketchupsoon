/*
import SwiftUI
import FirebaseFirestore
import SwiftData


enum AddFriendTab: String, CaseIterable {
    case contacts = "contacts"
    // Temporarily commented out
    // case qrCode = "qr code"
    // case inviteViaText = "invite via text"
}

enum FriendViewMode {
    case addFriends
    case friendRequests
}



struct AddFriendView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: AddFriendTab = .contacts
    @State private var viewMode: FriendViewMode = .addFriends
    @State private var searchQuery = ""
    @State private var searchResult: UserProfile?
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var friendAdded = false
    
    // Sample contacts data for UI mockup
    let contactsOnApp = [
        ContactPerson(name: "Jamie Chen", phoneNumber: "+(123) 456-7890", isOnApp: true),
        ContactPerson(name: "Riley Smith", phoneNumber: "+(123) 555-1234", isOnApp: true)
    ]
    
    let contactsToInvite = [
        ContactPerson(name: "Avery Singh", phoneNumber: "+(123) 555-6789", isOnApp: false),
        ContactPerson(name: "Jordan Lee", phoneNumber: "+(123) 555-4321", isOnApp: false),
        ContactPerson(name: "Morgan Park", phoneNumber: "+(123) 555-9876", isOnApp: false)
    ]
    
    var body: some View {
        ZStack {
            // Background
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                customNavigationBar
                
                // Tab Selection
                tabSelectionView
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // Search Bar
                searchBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // Optionally, show search results if any
                searchResultsView
                    .padding(.top, 10)
                
                // Content based on selected tab
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case .contacts:
                            contactsView
                        // Temporarily commented out
                        /*
                        case .qrCode:
                            qrCodeView
                        case .inviteViaText:
                            inviteViaTextView
                        */
                        }
                    }
                    .padding(.bottom, 100) // Add padding for bottom safe area
                }
                .padding(.top, 20)
            }
        }
        .navigationBarHidden(true)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK") { 
                if friendAdded {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Custom Navigation Bar
    private var customNavigationBar: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    Text("add")
                        .font(.custom("SpaceGrotesk-Bold", size: 26))
                        .foregroundColor(.white)
                    
                    Text("friends")
                        .font(.custom("SpaceGrotesk-Bold", size: 26))
                        .foregroundColor(AppColors.accent)
                }
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(AppColors.cardBackground)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(AppColors.backgroundPrimary.opacity(0.9))
    }
    
    // MARK: - Tab Selection
    private var tabSelectionView: some View {
        HStack(spacing: 10) {
            ForEach(AddFriendTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(height: 40)
                }
                .background(
                    Capsule()
                        .fill(selectedTab == tab ? AppColors.accentGradient1 : AppColors.cardBackground)
                )
                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: selectedTab == tab ? 0 : 1)
                )
                .shadow(color: selectedTab == tab ? AppColors.accent.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.5))
                .padding(.leading, 12)
            
            TextField("search contacts...", text: $searchQuery)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(12)
                .onSubmit {
                    searchForUser()
                }
        }
        .background(AppColors.cardBackground)
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Contacts View
    private var contactsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // On KetchupSoon section
            Text("on ketchupsoon")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            ForEach(contactsOnApp) { contact in
                ContactRowView(contact: contact, onAddAction: {
                    // Action for adding this contact
                    print("Adding contact: \(contact.name)")
                })
                .padding(.horizontal, 20)
            }
            
            // Invite to KetchupSoon section
            Text("invite to ketchupsoon")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 10)
            
            ForEach(contactsToInvite) { contact in
                ContactRowView(contact: contact, onAddAction: {
                    // Action for inviting this contact
                    print("Inviting contact: \(contact.name)")
                })
                .padding(.horizontal, 20)
            }
            
            // Invite multiple button
            Button(action: {
                // Action for inviting multiple
            }) {
                Text("invite multiple")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.accentGradient2)
                    .cornerRadius(25)
                    .shadow(color: AppColors.purple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 60)
            .padding(.top, 20)
        }
    }
    
    // MARK: - QR Code View
    /* Temporarily commented out
    private var qrCodeView: some View {
        VStack(spacing: 30) {
            // QR Code display area
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.cardBackground)
                    .frame(width: 280, height: 280)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                Image(systemName: "qrcode")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .foregroundColor(.white)
            }
            
            // Instructions
            Text("Share your QR code with friends")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text("They can scan it to add you on KetchupSoon")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 5)
            
            // Share button
            Button(action: {
                // Action to share QR code
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                    
                    Text("share qr code")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 16)
                .background(AppColors.accentGradient2)
                .cornerRadius(25)
                .shadow(color: AppColors.purple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 20)
    }
    */
    
    // MARK: - Invite via Text View
    /* Temporarily commented out
    private var inviteViaTextView: some View {
        VStack(spacing: 20) {
            // Selected contacts section
            VStack(alignment: .leading, spacing: 10) {
                Text("Selected contacts")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(contactsToInvite) { contact in
                            HStack {
                                Text(contact.name)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                
                                Button(action: {
                                    // Remove contact
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(5)
                                        .background(Circle().fill(Color.white.opacity(0.2)))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.cardBackground)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding(.horizontal, 20)
            
            // Invitation message
            VStack(alignment: .leading, spacing: 10) {
                Text("Invitation message")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                TextEditor(text: .constant("Hey! I'm using KetchupSoon to hangout with friends. It's an awesome app to schedule time with people you actually want to see! Join me: https://ketchupsoon.app/invite"))
                    .padding()
                    .frame(height: 120)
                    .background(AppColors.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            
            // Message preview
            VStack(alignment: .leading, spacing: 10) {
                Text("Message preview")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.accent)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("SMS to 3 contacts")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Hey! I'm using KetchupSoon to hangout with friends. It's an awesome app to schedule time with people you actually want to see! Join me: https://ketchupsoon.app/invite")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(3)
                    }
                }
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            
            // Send invites button
            Button(action: {
                // Action to send invites
            }) {
                Text("send invites")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.accentGradient1)
                    .cornerRadius(25)
                    .shadow(color: AppColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 60)
            .padding(.top, 20)
        }
    }
    */
    
    // MARK: - Search Results View (Integrated into AddFriendView)
    private var searchResultsView: some View {
        VStack {
            if isSearching {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                    .padding()
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .background(AppColors.cardBackground)
                    .cornerRadius(10)
            } else if let result = searchResult {
                HStack {
                    // Avatar or initials
                    ZStack {
                        Circle()
                            .fill(AppColors.avatarGradient(for: result.name ?? "User"))
                            .frame(width: 50, height: 50)
                        
                        Text(AppColors.avatarEmoji(for: result.name ?? "User"))
                            .font(.system(size: 24))
                    }
                    
                    // User info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.name ?? "Unknown User")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        if let email = result.email {
                            Text(email)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    // Add Button
                    Button(action: {
                        addFriend()
                    }) {
                        Text("add")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(AppColors.accentGradient1)
                            .cornerRadius(20)
                            .shadow(color: AppColors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(AppColors.cardBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Search & Friend Functions
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

// MARK: - Supporting Views
struct ContactRowView: View {
    let contact: ContactPerson
    var onAddAction: () -> Void
    
    var body: some View {
        HStack {
            // Profile Image/Avatar
            ZStack {
                Circle()
                    .fill(contact.isOnApp ? AppColors.avatarGradient(for: contact.name) : Color.clear)
                    .frame(width: 50, height: 50)
                
                if contact.isOnApp {
                    Text(AppColors.avatarEmoji(for: contact.name))
                        .font(.system(size: 24))
                } else {
                    Circle()
                        .fill(AppColors.cardBackground)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    Text(contact.initials)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            // Contact Info
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Text(contact.phoneNumber)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Add/Invite Button
            Button(action: {
                onAddAction()
            }) {
                Text(contact.isOnApp ? "add" : "invite")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        contact.isOnApp ?
                        AppColors.accentGradient1 :
                        AppColors.cardBackground
                    )
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(contact.isOnApp ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: contact.isOnApp ? AppColors.accent.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(AppColors.cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Model
struct ContactPerson: Identifiable {
    let id = UUID()
    let name: String
    let phoneNumber: String
    let isOnApp: Bool
    
    var initials: String {
        name.components(separatedBy: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
    }
}

// MARK: - Preview
#Preview {
    AddFriendView()
        .modelContainer(for: [Friend.self], inMemory: true)
        .preferredColorScheme(.dark)
} 


*/
