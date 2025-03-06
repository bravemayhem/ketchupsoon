import SwiftUI
import PhotosUI
import FirebaseStorage
import Combine
import OSLog
import FirebaseAuth

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var profileManager = UserProfileManager.shared
    
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var birthday: Date? = nil
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Profile Update"
    @State private var saveInProgress = false
    @State private var hasChanges = false
    
    // Used to prevent auto-save during initial data loading
    @State private var isInitialDataLoad = true
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "ProfileSettingsView")
    
    // Debounce timer for auto-saving
    @State private var autoSaveTimer: AnyCancellable?
    
    // Photo selection states
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var isUploadingImage = false
    @State private var showPhotoPicker = false
    
    // Get a date 18 years ago for default birthday range
    private var defaultDate: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }
    
    var body: some View {
        Form {
            Section {
                // Profile Photo 
                HStack {
                    Spacer()
                    ZStack {
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else if let photoURL = profileManager.currentUserProfile?.profileImageURL,
                           !photoURL.isEmpty {
                            AsyncImage(url: URL(string: photoURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(20)
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        if isUploadingImage {
                            ProgressView()
                                .frame(width: 100, height: 100)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .onTapGesture {
                        showPhotoPicker = true
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.accent)
                            .background(Color.white)
                            .clipShape(Circle())
                            .offset(x: 3, y: 3)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets())
                
                HStack {
                    Text("Name")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $name)
                        .multilineTextAlignment(.trailing)
                        .textContentType(.name)
                        .onChange(of: name) { _ in
                            triggerAutoSave()
                        }
                }
                
                HStack {
                    Text("Email")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $email)
                        .multilineTextAlignment(.trailing)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onChange(of: email) { _ in
                            triggerAutoSave()
                        }
                }
                
                HStack {
                    Text("Phone")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $phoneNumber)
                        .multilineTextAlignment(.trailing)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .onChange(of: phoneNumber) { _ in
                            triggerAutoSave()
                        }
                }
                
                DatePicker(
                    "Birthday",
                    selection: Binding(
                        get: { birthday ?? defaultDate },
                        set: { 
                            birthday = $0
                            triggerAutoSave()
                        }
                    ),
                    displayedComponents: .date
                )
                .foregroundColor(AppColors.label)
            } header: {
                Text("PROFILE INFORMATION")
            } footer: {
                HStack {
                    Text("Your phone number is required to create hangouts. This helps your friends identify you when they receive invites.")
                    
                    if saveInProgress {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            }
            
            Section {
                NavigationLink {
                    SocialProfileView()
                } label: {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(AppColors.accent)
                            .font(.title3)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Social Profile")
                                .font(.headline)
                            
                            Text("Enable additional features")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let profile = profileManager.currentUserProfile, profile.isSocialProfileActive {
                            Text("Active")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppColors.accent.opacity(0.2))
                                .foregroundColor(AppColors.accent)
                                .cornerRadius(8)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("SOCIAL FEATURES")
            } footer: {
                Text("Create a social profile to unlock features like finding mutual free times and activity suggestions.")
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            logger.info("📋 ProfileSettingsView appeared")
            isInitialDataLoad = true
            
            // First, refresh the profile from Firestore
            Task {
                if let userId = Auth.auth().currentUser?.uid {
                    logger.info("📋 Refreshing profile data from server")
                    await profileManager.fetchUserProfile(userId: userId)
                }
                
                // Then load it into the view
                await MainActor.run {
                    loadProfileData()
                    
                    // Set a small delay before allowing auto-saves (increased to 2 seconds)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        isInitialDataLoad = false
                        logger.info("📋 Initial data load complete, auto-save enabled")
                    }
                }
            }
        }
        .onDisappear {
            logger.info("📋 ProfileSettingsView disappeared")
            // Ensure any pending changes are saved when leaving the view
            autoSaveTimer?.cancel()
            if hasChanges {
                logger.info("📋 Saving pending changes on disappear")
                saveProfile()
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { newValue in
            if let newValue = newValue {
                Task {
                    await loadTransferableImage(from: newValue)
                }
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { showAlert = false }
        } message: {
            Text(alertMessage)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Debug Save") {
                    logger.info("📋 Manual debug save triggered")
                    saveProfile()
                }
            }
        }
    }
    
    private func loadProfileData() {
        logger.info("📋 Loading profile data")
        
        // Load from profile manager if available
        if let profile = profileManager.currentUserProfile {
            logger.info("📋 Loading from profile manager: \(profile.id)")
            name = profile.name ?? ""
            email = profile.email ?? ""
            phoneNumber = profile.phoneNumber ?? ""
            birthday = profile.birthday
            
            logger.info("📋 Loaded values - name: \(name), email: \(email), phone: \(phoneNumber), birthday: \(birthday?.description ?? "nil")")
        } else {
            // Fall back to UserSettings
            logger.warning("📋 No profile available, falling back to UserSettings")
            name = userSettings.name ?? ""
            phoneNumber = userSettings.phoneNumber ?? ""
            email = userSettings.email ?? ""
            
            logger.info("📋 Loaded from UserSettings - name: \(name), email: \(email), phone: \(phoneNumber)")
        }
    }
    
    private func triggerAutoSave() {
        // Don't auto-save during initial data loading
        if isInitialDataLoad {
            logger.info("📋 Change ignored during initial data load")
            return
        }
        
        hasChanges = true
        logger.info("📋 Change detected, triggering auto-save")
        logger.info("📋 Current values - name: \(name), email: \(email), phone: \(phoneNumber), birthday: \(birthday?.description ?? "nil")")
        
        // Cancel existing timer if there is one
        autoSaveTimer?.cancel()
        
        // Set up a new timer to save after 1.5 seconds of inactivity
        autoSaveTimer = Just(())
            .delay(for: .seconds(1.5), scheduler: RunLoop.main)
            .sink { _ in
                if hasChanges {
                    logger.info("📋 Auto-save timer fired, calling saveProfile()")
                    saveProfile()
                } else {
                    logger.info("📋 Auto-save timer fired but no changes detected")
                }
            }
    }
    
    private func loadTransferableImage(from item: PhotosPickerItem) async {
        logger.info("📋 Loading transferable image")
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            logger.error("📋 Failed to load transferable image data")
            alertTitle = "Photo Error"
            alertMessage = "Could not load the selected image"
            showAlert = true
            return
        }
        
        guard let uiImage = UIImage(data: data) else {
            logger.error("📋 Failed to create UIImage from data")
            alertTitle = "Photo Error"
            alertMessage = "The selected image appears to be invalid"
            showAlert = true
            return
        }
        
        // Update the UI with the selected image
        await MainActor.run {
            logger.info("📋 Successfully loaded image, updating UI")
            profileImage = uiImage
        }
        
        // Upload the image to Firebase Storage
        await uploadProfileImage(uiImage)
    }
    
    private func uploadProfileImage(_ image: UIImage) async {
        logger.info("📋 Starting profile image upload")
        guard let userId = profileManager.currentUserProfile?.id else {
            logger.error("📋 No user profile ID available for image upload")
            alertTitle = "Photo Error"
            alertMessage = "You must have a profile before setting a profile picture"
            showAlert = true
            return
        }
        
        await MainActor.run {
            isUploadingImage = true
        }
        
        do {
            // Resize image for storage efficiency
            guard let resizedImage = image.resized(to: CGSize(width: 500, height: 500)) else {
                logger.error("📋 Failed to resize image")
                throw NSError(domain: "ProfileSettingsView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not resize image"])
            }
            
            guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
                logger.error("📋 Failed to convert image to JPEG data")
                throw NSError(domain: "ProfileSettingsView", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to JPEG data"])
            }
            
            logger.info("📋 Image prepared for upload: \(imageData.count) bytes")
            
            // Create a reference to Firebase Storage
            let storage = Storage.storage()
            let storageRef = storage.reference()
            let profileImagesRef = storageRef.child("profile_images/\(userId).jpg")
            
            logger.info("📋 Uploading image to Firebase Storage")
            // Upload the image
            _ = try await profileImagesRef.putDataAsync(imageData)
            logger.info("📋 Image upload successful, getting download URL")
            
            // Get the download URL
            let downloadURL = try await profileImagesRef.downloadURL()
            logger.info("📋 Got download URL: \(downloadURL.absoluteString)")
            
            // Update profile with new image URL
            logger.info("📋 Updating profile with new image URL")
            try await profileManager.updateUserProfile(updates: ["profileImageURL": downloadURL.absoluteString])
            
            await MainActor.run {
                isUploadingImage = false
                alertTitle = "Photo Update"
                alertMessage = "Profile photo updated successfully"
                showAlert = true
                logger.info("📋 Profile photo update completed successfully")
            }
        } catch {
            logger.error("📋 Error uploading profile image: \(error.localizedDescription)")
            await MainActor.run {
                isUploadingImage = false
                alertTitle = "Photo Error"
                alertMessage = "Error uploading photo: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func saveProfile() {
        logger.info("📋 saveProfile() called")
        
        // Check if we have a user profile or if the user is logged in
        if profileManager.currentUserProfile == nil {
            logger.warning("📋 Cannot save - no current user profile")
            alertTitle = "Profile Update"
            alertMessage = "You must be logged in to update your profile"
            showAlert = true
            return
        }
        
        saveInProgress = true
        hasChanges = false
        
        // Build updates dictionary
        var updates: [String: Any] = [:]
        
        if !name.isEmpty {
            updates["name"] = name
            logger.info("📋 Adding name to updates: \(name)")
        }
        
        if !email.isEmpty {
            updates["email"] = email
            logger.info("📋 Adding email to updates: \(email)")
        }
        
        if !phoneNumber.isEmpty {
            updates["phoneNumber"] = phoneNumber
            logger.info("📋 Adding phoneNumber to updates: \(phoneNumber)")
        }
        
        if let birthday = birthday {
            updates["birthday"] = birthday.timeIntervalSince1970
            logger.info("📋 Adding birthday to updates: \(birthday)")
        }
        
        logger.info("📋 Total updates to save: \(updates.count)")
        
        // Skip if no updates
        if updates.isEmpty {
            logger.info("📋 No updates to save, returning early")
            saveInProgress = false
            return
        }
        
        // Also update UserSettings
        logger.info("📋 Updating UserSettings")
        userSettings.updateName(name.isEmpty ? nil : name)
        userSettings.updateEmail(email.isEmpty ? nil : email)
        userSettings.updatePhoneNumber(phoneNumber.isEmpty ? nil : phoneNumber)
        
        // Update profile in Firestore
        logger.info("📋 Starting Firestore update")
        Task {
            do {
                logger.info("📋 Calling profileManager.updateUserProfile")
                try await profileManager.updateUserProfile(updates: updates)
                await MainActor.run {
                    saveInProgress = false
                    logger.info("📋 Profile updated successfully")
                    // Show a temporary alert for debug builds
                    #if DEBUG
                    alertTitle = "Profile Update"
                    alertMessage = "Profile updated successfully"
                    showAlert = true
                    #endif
                }
            } catch {
                logger.error("📋 Error updating profile: \(error.localizedDescription)")
                await MainActor.run {
                    saveInProgress = false
                    alertTitle = "Profile Update"
                    alertMessage = "Error updating profile: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

// Extension to resize UIImage
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#Preview {
    NavigationStack {
        ProfileSettingsView()
    }
} 
