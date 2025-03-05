import SwiftUI
import SwiftData
import FirebaseFirestore
#if canImport(MessageUI)
import MessageUI
#endif

/// FriendExistingView provides the interface for viewing and editing existing friend details.
///
/// # Overview
/// This view serves as the primary interface for managing an existing friend's information.
/// It can be presented either through navigation or as a modal sheet, and provides
/// full editing capabilities for all friend properties.

struct FriendExistingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: FriendDetail.ViewModel
    @State private var cityService = CitySearchService()
    @State private var showingFirebaseProfile = false
    @State private var firebaseProfile: UserProfile?
    @State private var isLoadingFirebaseProfile = false
    
    init(friend: Friend) {
        self._viewModel = State(initialValue: FriendDetail.ViewModel(friend: friend))
        // Initialize cityService with friend's location
        let service = CitySearchService()
        if let location = friend.location {
            service.searchInput = location
            service.selectedCity = location
        }
        self._cityService = State(initialValue: service)
    }
    
    var body: some View {
        BaseFriendForm(configuration: FormConfiguration.existing) { config in
            Group {
                // Ketchupsoon account badge
                if viewModel.friend.firebaseUserId != nil {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .foregroundColor(.green)
                                Text("Ketchupsoon User")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Spacer()
                                Button("View Profile") {
                                    loadFirebaseProfile()
                                }
                                .font(.subheadline)
                                .foregroundColor(AppColors.accent)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.green.opacity(0.1))
                }
                
                if config.showsLocation || config.showsLastSeen || config.showsName || config.showsCatchUpFrequency {
                    FriendInfoExistingSection(
                        friend: viewModel.friend,
                        cityService: cityService
                    )
                    .onTapGesture {
                        if viewModel.friend.contactIdentifier != nil {
                            viewModel.showingContactSheet = true
                        }
                    }
                    
                    FriendKetchupSection(
                        friend: viewModel.friend,
                        onLastSeenTap: {
                            viewModel.showingDatePicker = true
                        },
                        onFrequencyTap: {
                            viewModel.showingFrequencyPicker = true
                        }
                    )
                }
                
                if config.showsTags {
                    FriendTagsSection(
                        friend: viewModel.friend,
                        onManageTags: {
                            viewModel.showingTagsManager = true
                        }
                    )
                }
                
                if config.showsActions {
                    FriendActionSection(
                        friend: viewModel.friend,
                        onMessageTap: {
                            viewModel.showingMessageSheet = true
                        },
                        onScheduleTap: {
                            viewModel.showingScheduler = true
                        },
                        onMarkSeenTap: {
                            viewModel.markAsSeen()
                        }
                    )
                }
                
                if config.showsHangouts {
                    FriendHangoutsSection(hangouts: viewModel.friend.scheduledHangouts)
                }
            }
        }
        .navigationTitle(viewModel.friend.name)
        .navigationBarTitleDisplayMode(.inline)
        .datePickerSheet(
            isPresented: $viewModel.showingDatePicker,
            date: $viewModel.lastSeenDate,
            onSave: viewModel.updateLastSeenDate
        )
        .sheet(isPresented: $viewModel.showingFrequencyPicker) {
            NavigationStack {
                FrequencyPickerView(friend: viewModel.friend)
            }
        }
        .sheet(isPresented: $viewModel.showingTagsManager) {
            TagsSelectionView(friend: viewModel.friend)
        }
        .sheet(isPresented: $viewModel.showingScheduler) {
            CreateHangoutView(initialSelectedFriends: [viewModel.friend])
        }
        .sheet(isPresented: $viewModel.showingMessageSheet) {
            if let phoneNumber = viewModel.friend.phoneNumber {
                MessageComposeView(recipient: phoneNumber)
            }
        }
        .sheet(isPresented: $viewModel.showingContactSheet) {
            if let contactIdentifier = viewModel.friend.contactIdentifier {
                ContactDisplayView(
                    contactIdentifier: contactIdentifier,
                    position: "friend_existing",
                    isPresented: $viewModel.showingContactSheet
                )
            }
        }
        .sheet(isPresented: $showingFirebaseProfile) {
            if let profile = firebaseProfile {
                FirebaseUserProfileSheet(profile: profile)
            } else if isLoadingFirebaseProfile {
                VStack {
                    ProgressView()
                    Text("Loading profile...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.systemBackground)
            }
        }
        .onChange(of: cityService.selectedCity) { _, newCity in
            viewModel.friend.location = newCity
        }
        // Check for Firebase profile updates if needed
        .task {
            if let firebaseId = viewModel.friend.firebaseUserId {
                checkForFirebaseProfileUpdates(userId: firebaseId)
            }
        }
    }
    
    private func loadFirebaseProfile() {
        guard let firebaseId = viewModel.friend.firebaseUserId else { return }
        
        isLoadingFirebaseProfile = true
        showingFirebaseProfile = true
        
        Task {
            do {
                // Fetch from Firestore
                let db = Firestore.firestore()
                let docRef = db.collection("users").document(firebaseId)
                let document = try await docRef.getDocument()
                
                if let data = document.data(), let userId = data["id"] as? String {
                    // Convert Firestore data to UserProfile
                    let name = data["name"] as? String
                    let email = data["email"] as? String
                    let phoneNumber = data["phoneNumber"] as? String
                    let bio = data["bio"] as? String
                    let profileImageURL = data["profileImageURL"] as? String
                    
                    var createdAt = Date()
                    if let createdTimestamp = data["createdAt"] as? TimeInterval {
                        createdAt = Date(timeIntervalSince1970: createdTimestamp)
                    }
                    
                    var updatedAt = Date() 
                    if let updatedTimestamp = data["updatedAt"] as? TimeInterval {
                        updatedAt = Date(timeIntervalSince1970: updatedTimestamp)
                    }
                    
                    let profile = UserProfile(
                        id: userId,
                        name: name,
                        email: email,
                        phoneNumber: phoneNumber,
                        bio: bio,
                        profileImageURL: profileImageURL,
                        createdAt: createdAt,
                        updatedAt: updatedAt
                    )
                    
                    await MainActor.run {
                        firebaseProfile = profile
                        isLoadingFirebaseProfile = false
                    }
                } else {
                    await MainActor.run {
                        isLoadingFirebaseProfile = false
                    }
                }
            } catch {
                print("Error loading Firebase profile: \(error)")
                await MainActor.run {
                    isLoadingFirebaseProfile = false
                }
            }
        }
    }
    
    private func checkForFirebaseProfileUpdates(userId: String) {
        Task {
            do {
                // Fetch user profile
                let db = Firestore.firestore()
                let docRef = db.collection("users").document(userId)
                let document = try await docRef.getDocument()
                
                guard let data = document.data() else { return }
                
                // Check if local data is up-to-date
                var needsUpdate = false
                let friend = viewModel.friend
                
                // Compare name
                if let name = data["name"] as? String, name != friend.name {
                    friend.name = name
                    needsUpdate = true
                }
                
                // Compare email
                if let email = data["email"] as? String, email != friend.email {
                    friend.email = email
                    needsUpdate = true
                }
                
                // Compare phone number
                if let phoneNumber = data["phoneNumber"] as? String, phoneNumber != friend.phoneNumber {
                    // Only update if the friend wasn't from contacts (to avoid overwriting contact info)
                    if friend.contactIdentifier == nil {
                        friend.phoneNumber = phoneNumber
                        needsUpdate = true
                    }
                }
                
                // Handle profile image
                if let profileImageURL = data["profileImageURL"] as? String, 
                   let url = URL(string: profileImageURL) {
                    // Only download if we don't have an image already
                    if friend.photoData == nil {
                        // This is a placeholder - you'd implement actual image loading
                        print("Profile image available at: \(url)")
                    }
                }
                
                if needsUpdate {
                    print("Updated friend with Firebase profile data")
                }
            } catch {
                print("Error checking Firebase profile updates: \(error)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        FriendExistingView(
            friend: Friend(
                name: "Aleah Goldstein",
                lastSeen: Date(),
                location: "Los Angeles, CA",
                phoneNumber: "+1234567890"
            )
        )
    }
    .modelContainer(for: Friend.self)
} 

