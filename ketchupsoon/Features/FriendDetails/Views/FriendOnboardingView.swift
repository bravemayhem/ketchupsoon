import SwiftUI
import SwiftData
import FirebaseFirestore

// MARK: - Updated FriendOnboardingView
struct FriendOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FriendDetail.OnboardingViewModel
    @State private var showingTagsSheet = false
    @State private var showingDatePicker = false
    @State private var showingBirthdayPicker = false
    @State private var cityService = CitySearchService()
    @State private var error: FriendDetail.FriendError?
    @State private var showingError = false
    @State private var foundFirebaseUser: UserProfile?
    @State private var isCheckingFirebase = false
    @State private var showFirebaseUserInfoSheet = false
    @Query(sort: [SortDescriptor<Tag>(\.name)], animation: .default) private var allTags: [Tag]
    
    var onComplete: ((Friend?) -> Void)?
    
    init(contact: (name: String, identifier: String?, phoneNumber: String?, email: String?, imageData: Data?, city: String?), onComplete: ((Friend?) -> Void)? = nil) {
        let input = FriendDetail.NewFriendInput(
            name: contact.name,
            identifier: contact.identifier,
            phoneNumber: contact.phoneNumber,
            email: contact.email,
            imageData: contact.imageData,
            city: contact.city
        )
        self._viewModel = State(initialValue: FriendDetail.OnboardingViewModel(input: input))
        self.onComplete = onComplete
        
        // Initialize cityService if we have a city from contacts
        if let city = contact.city {
            let service = CitySearchService()
            service.searchInput = city
            service.selectedCity = city
            self._cityService = State(initialValue: service)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Firebase profile status section
                if foundFirebaseUser != nil {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Ketchupsoon User Found")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Spacer()
                                Button("View Profile") {
                                    showFirebaseUserInfoSheet = true
                                }
                                .font(.subheadline)
                                .foregroundColor(AppColors.accent)
                            }
                            
                            Text("This person has a Ketchupsoon account. Their profile information will be used.")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryLabel)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.green.opacity(0.1))
                } else if isCheckingFirebase {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Checking for Ketchupsoon account...")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryLabel)
                        }
                    }
                }
                
                FriendOnboardingDetailsSection(
                    isFromContacts: viewModel.isFromContacts,
                    contact: viewModel.input,
                    manualName: $viewModel.friendName,
                    phoneNumber: $viewModel.phoneNumber,
                    email: $viewModel.email,
                    cityService: cityService
                )
                
                FriendTagsSection(
                    tags: viewModel.selectedTags,
                    onManageTags: { showingTagsSheet = true }
                )
                
                FriendConnectSection(
                    wantToConnectSoon: $viewModel.wantToConnectSoon
                )
                
                FriendCatchUpSection(
                    hasCatchUpFrequency: $viewModel.hasCatchUpFrequency,
                    selectedFrequency: $viewModel.selectedFrequency
                )
                
                FriendLastSeenSection(
                    hasLastSeen: $viewModel.hasLastSeen,
                    lastSeenDate: $viewModel.lastSeenDate,
                    showingDatePicker: $showingDatePicker
                )
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.systemBackground)
            .listStyle(.insetGrouped)
            .navigationTitle("Add Friend Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: handleCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add", action: handleAdd)
                        .disabled(!viewModel.isFromContacts && viewModel.friendName.isEmpty)
                }
            }
            .sheet(isPresented: $showingTagsSheet) {
                TagsSelectionView(selectedTags: $viewModel.selectedTags)
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerView(date: $viewModel.lastSeenDate, isPresented: $showingDatePicker)
            }
            .sheet(isPresented: $showingBirthdayPicker) {
                NavigationStack {
                    VStack {
                        DatePicker(
                            "Birthday",
                            selection: Binding(
                                get: { viewModel.birthday ?? Date() },
                                set: { viewModel.birthday = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                    }
                    .navigationTitle("Select Birthday")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingBirthdayPicker = false
                            }
                        }
                        
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                if viewModel.birthday == nil {
                                    viewModel.birthday = Date()
                                }
                                showingBirthdayPicker = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showFirebaseUserInfoSheet) {
                if let profile = foundFirebaseUser {
                    FirebaseUserProfileSheet(profile: profile)
                }
            }
            .alert("Cannot Add Friend", isPresented: $showingError, presenting: error) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error.message)
            }
            .task {
                await checkForFirebaseUser()
            }
        }
    }
    
    private func checkForFirebaseUser() async {
        // Only check if we have an email or phone number
        guard let input = viewModel.input,
              (input.email != nil && !input.email!.isEmpty) || 
              (input.phoneNumber != nil && !input.phoneNumber!.isEmpty) else {
            return
        }
        
        isCheckingFirebase = true
        
        let firebaseService = FirebaseUserSearchService.shared
        
        // Try email first
        if let email = input.email, !email.isEmpty {
            let foundUser = await firebaseService.searchUsers(byEmailOrPhone: email)
            if foundUser && !firebaseService.searchResults.isEmpty {
                foundFirebaseUser = firebaseService.searchResults.first
                isCheckingFirebase = false
                return
            }
        }
        
        // Try phone if email didn't match
        if let phone = input.phoneNumber, !phone.isEmpty {
            let foundUser = await firebaseService.searchUsers(byEmailOrPhone: phone)
            if foundUser && !firebaseService.searchResults.isEmpty {
                foundFirebaseUser = firebaseService.searchResults.first
                isCheckingFirebase = false
                return
            }
        }
        
        isCheckingFirebase = false
    }
    
    private func handleCancel() {
        onComplete?(nil)
        dismiss()
    }
    
    private func handleAdd() {
        viewModel.selectedCity = cityService.selectedCity
        
        // If we found a Firebase user, create Friend with that connection
        if let firebaseUser = foundFirebaseUser {
            let friend = FirebaseUserSearchService.shared.createFriendFromFirebaseUser(
                firebaseUser, 
                in: modelContext
            )
            
            // Apply any additional settings from the form
            friend.location = cityService.selectedCity
            friend.needsToConnectFlag = viewModel.wantToConnectSoon
            
            if viewModel.hasCatchUpFrequency {
                friend.catchUpFrequency = viewModel.selectedFrequency
            }
            
            if viewModel.hasLastSeen {
                friend.lastSeen = viewModel.lastSeenDate
            }
            
            // Apply tags
            friend.tags = Array(viewModel.selectedTags)
            
            // Handle completion
            onComplete?(friend)
            dismiss()
            return
        }
        
        // Otherwise, create a regular friend
        do {
            let friend = try viewModel.createFriend(in: modelContext)
            onComplete?(friend)
            dismiss()
        } catch let friendError as FriendDetail.FriendError {
            // For duplicate errors, treat it as a skip and move to next friend
            if case .duplicateContact = friendError {
                onComplete?(nil)
                dismiss()
            } else {
                error = friendError
                showingError = true
            }
        } catch {
            print("Unexpected error: \(error)")
            onComplete?(nil)
            dismiss()
        }
    }
}

// Firebase user profile sheet to show more details
struct FirebaseUserProfileSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Profile image
                    HStack {
                        Spacer()
                        if let photoURL = profile.profileImageURL,
                           !photoURL.isEmpty,
                           let url = URL(string: photoURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .padding(.vertical, 8)
                        } else {
                            Circle()
                                .fill(AppColors.avatarColor(for: profile.name ?? "User"))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(getInitials(from: profile.name ?? "User"))
                                        .font(.system(size: 30, weight: .medium))
                                        .foregroundColor(.white)
                                )
                                .padding(.vertical, 8)
                        }
                        Spacer()
                    }
                    
                    if let name = profile.name {
                        HStack {
                            Text("Name")
                                .foregroundColor(AppColors.label)
                            Spacer()
                            Text(name)
                                .foregroundColor(AppColors.secondaryLabel)
                        }
                    }
                    
                    if let email = profile.email {
                        HStack {
                            Text("Email")
                                .foregroundColor(AppColors.label)
                            Spacer()
                            Text(email)
                                .foregroundColor(AppColors.secondaryLabel)
                        }
                    }
                    
                    if let phone = profile.phoneNumber {
                        HStack {
                            Text("Phone")
                                .foregroundColor(AppColors.label)
                            Spacer()
                            Text(phone)
                                .foregroundColor(AppColors.secondaryLabel)
                        }
                    }
                    
                    if let bio = profile.bio, !bio.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bio")
                                .foregroundColor(AppColors.label)
                            Text(bio)
                                .foregroundColor(AppColors.secondaryLabel)
                                .padding(.top, 4)
                        }
                    }
                }
                
                Section {
                    Text("This person has a Ketchupsoon account. When you add them as a friend, their profile information will be used and updated automatically.")
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryLabel)
                }
            }
            .navigationTitle("Ketchupsoon User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getInitials(from name: String) -> String {
        name.components(separatedBy: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
    }
}

// Date formatter for displaying birthdays
private var birthdayFormatter: DateFormatter {
    return DateFormatter.birthday
}

#Preview("From Contacts") {
    NavigationStack {
        FriendOnboardingView(
            contact: (
                name: "John Smith",
                identifier: "123",
                phoneNumber: "(555) 123-4567",
                email: "john.smith@email.com",
                imageData: nil,
                city: "San Francisco"
            )
        )
    }
    .modelContainer(for: [Friend.self, Tag.self], inMemory: true)
}

#Preview("Manual Entry") {
    NavigationStack {
        FriendOnboardingView(
            contact: (
                name: "",
                identifier: nil,
                phoneNumber: nil,
                email: nil,
                imageData: nil,
                city: nil
            )
        )
    }
    .modelContainer(for: [Friend.self, Tag.self], inMemory: true)
}

