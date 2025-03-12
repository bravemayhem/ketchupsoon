import SwiftUI
import FirebaseAuth
import PhotosUI
import FirebaseStorage
import OSLog
import Combine

struct UserProfileView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var userSettings = UserSettings.shared
    
    // Cache-related state
    @State private var cachedProfileImage: UIImage? = nil
    
    // Profile data (initialized as empty, populated from real data)
    @State private var userName = ""
    @State private var userBio = ""
    @State private var userInfo = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var birthday: Date? = nil
    
    // Profile appearance (using a default gradient for the ring)
    @State private var profileRingGradient: LinearGradient = AppColors.accentGradient2
    
    // UI elements (these can stay as emojis since they're UI elements, not data)
    @State private var profileEmoji = "😎"
    @State private var cameraEmoji = "📸"
    
    // Photo selection states
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var isUploadingImage = false
    @State private var showPhotoPicker = false
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    // Alert state
    @State private var showAlert = false
    @State private var alertTitle = "Profile Photo"
    @State private var alertMessage = ""
    
    // New state variables added at the top along with existing states
    @State private var croppingImage: UIImage? = nil
    @State private var showCropView: Bool = false
    @State private var showSourceTypeActionSheet = false
    
    // Edit mode states
    @State private var isEditMode = false
    @State private var saveInProgress = false
    @State private var hasChanges = false
    @State private var isInitialDataLoad = true
    
    // Debounce timer for auto-saving
    @State private var autoSaveTimer: AnyCancellable?
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "UserProfileView")
    
    // Get a date 18 years ago for default birthday range
    private var defaultDate: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background with decorative elements
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            // Use our shared decorative elements
            DecorativeBubbles.profile
            BackgroundElementFactory.profileElements()
            
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    if !isEditMode {
                        // Profile content in view mode
                        profileContentView
                    } else {
                        // Edit form when in edit mode
                        editFormSection
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .foregroundColor(.white)
        }
        .padding(.bottom, 80)
        .onAppear {
            Task {
                if let userId = Auth.auth().currentUser?.uid {
                    // Refresh profile from Firestore
                    await profileManager.fetchUserProfile(userId: userId)
                }
                
                // Then load it into the view
                await MainActor.run {
                    loadProfileData()
                    preloadProfileImage()
                    
                    // Set a small delay before allowing auto-saves
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        isInitialDataLoad = false
                        logger.info("📋 Initial data load complete, auto-save enabled")
                    }
                }
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { oldValue, newValue in
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
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $profileImage, sourceType: sourceType)
                .ignoresSafeArea()
                .onDisappear {
                    if let image = profileImage {
                        // Instead of uploading immediately, set up for cropping
                        croppingImage = image
                        showCropView = true
                    }
                }
        }
        .sheet(isPresented: $showCropView) {
            CropImageView(image: $croppingImage, onCrop: { croppedImage in
                profileImage = croppedImage
                showCropView = false
                Task {
                    await uploadProfileImage(croppedImage)
                }
            }, onCancel: {
                showCropView = false
            })
        }
        .actionSheet(isPresented: $showSourceTypeActionSheet) {
            ActionSheet(
                title: Text("Choose Image Source"),
                buttons: [
                    .default(Text("Camera")) {
                        sourceType = .camera
                        showImagePicker = true
                    },
                    .default(Text("Photo Library")) {
                        sourceType = .photoLibrary
                        showImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
        .onChange(of: isEditMode) { oldValue, newValue in
            // When exiting edit mode, save any changes
            if oldValue == true && newValue == false && hasChanges {
                saveProfile()
            }
        }
    }
    
    // MARK: - Profile Content View
    private var profileContentView: some View {
        VStack(spacing: 20) {
            // Profile picture
            ZStack {
                // Gradient ring with glow effect
                Circle()
                    .fill(profileRingGradient)
                    .frame(width: 150, height: 150)
                    .glow(color: AppColors.purple, radius: 10, opacity: 0.6)
                
                // Profile image or emoji
                if let profileImage = profileImage {
                    // Show selected image while processing
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                } else if let cachedImage = cachedProfileImage {
                    // Show cached image
                    Image(uiImage: cachedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                } else if let photoURL = profileManager.currentUserProfile?.profileImageURL,
                          !photoURL.isEmpty {
                    // Profile image from URL with loading indicator
                    ZStack {
                        // Show emoji placeholder while loading
                        Text(profileEmoji)
                            .font(.system(size: 50))
                            .frame(width: 140, height: 140)
                        
                        // Add a progress indicator
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    .onAppear {
                        preloadProfileImage()
                    }
                } else {
                    // Emoji placeholder when no image is available
                    Text(profileEmoji)
                        .font(.system(size: 50))
                        .frame(width: 140, height: 140)
                }
                
                // Loading overlay when uploading
                if isUploadingImage {
                    ProgressView()
                        .frame(width: 140, height: 140)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                // Camera button
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Text(cameraEmoji)
                        .font(.system(size: 18))
                }
                .offset(x: 45, y: 45)
                .onTapGesture {
                    showSourceTypeActionSheet = true
                }
            }
            .padding(.top, 20)
            
            // User name
            Text(userName)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                .padding(.top, 10)
            
            // User bio (as regular text)
            if !userBio.isEmpty {
                Text(userBio)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.top, 2)
            }
            
            // User info as simple text lines with emoji
            VStack(spacing: 12) {
                if !phoneNumber.isEmpty {
                    HStack(spacing: 8) {
                        Text("📱")
                        Text(formatPhoneForDisplay(phoneNumber))
                            .font(.system(size: 16))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                if let birthday = birthday {
                    HStack(spacing: 8) {
                        Text("🎂")
                        Text(formatBirthdayForDisplay(birthday))
                            .font(.system(size: 16))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.top, 10)
            
            // Edit profile button
            Button(action: {
                isEditMode.toggle()
            }) {
                Text("edit profile")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
            }
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .clayMorphism(cornerRadius: 30)
        .padding(.horizontal, 10)
    }
    
    // MARK: - Edit Form Section
    private var editFormSection: some View {
        VStack(spacing: 20) {
            // Navigation bar with save/back buttons
            HStack {
                Button(action: {
                    isEditMode.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Save button
                Button(action: {
                    saveProfile()
                    hasChanges = false // Prevent double save from onChange handler
                    isEditMode.toggle()
                }) {
                    Text("Save")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(16)
                }
            }
            .padding(.top, 10)
            
            // Form fields
            VStack(spacing: 24) {
                // Profile image display at top
                ZStack {
                    // Avatar circle with gradient and glow
                    Circle()
                        .fill(profileRingGradient)
                        .frame(width: 120, height: 120)
                        .glow(color: AppColors.purple, radius: 8, opacity: 0.6)
                    
                    // Profile image or emoji
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                    } else if let cachedImage = cachedProfileImage {
                        Image(uiImage: cachedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                    } else {
                        Text(profileEmoji)
                            .font(.system(size: 40))
                            .frame(width: 110, height: 110)
                    }
                    
                    // Camera button
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Text(cameraEmoji)
                            .font(.system(size: 18))
                    }
                    .offset(x: 35, y: 35)
                    .onTapGesture {
                        showSourceTypeActionSheet = true
                    }
                }
                .padding(.bottom, 10)
                
                // Form fields in a card
                VStack(spacing: 20) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("Your name", text: $userName)
                            .font(.system(size: 16))
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .onChange(of: userName) { oldValue, newValue in
                                triggerAutoSave()
                            }
                    }
                    
                    // Bio field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextEditor(text: $userBio)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden)
                            .background(Color.white.opacity(0.1))
                            .frame(minHeight: 80)
                            .cornerRadius(10)
                            .onChange(of: userBio) { oldValue, newValue in
                                triggerAutoSave()
                            }
                    }
                    
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("email@example.com", text: $email)
                            .font(.system(size: 16))
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .onChange(of: email) { oldValue, newValue in
                                triggerAutoSave()
                            }
                    }
                    
                    // Phone field (non-editable display)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(phoneNumber.isEmpty ? "Not set" : formatPhoneForDisplay(phoneNumber))
                            .font(.system(size: 16))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                    }
                    
                    // Birthday field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Birthday")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { birthday ?? defaultDate },
                                set: { 
                                    birthday = $0
                                    triggerAutoSave()
                                }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .colorScheme(.dark)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 5)
                
                if saveInProgress {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.top, 10)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .clayMorphism(cornerRadius: 30)
        .padding(.horizontal, 10)
    }
    
    // MARK: - Auto Save Functionality
    private func triggerAutoSave() {
        // Don't auto-save during initial data loading
        if isInitialDataLoad {
            logger.info("📸 Change ignored during initial data load")
            return
        }
        
        hasChanges = true
        logger.info("📸 Change detected, triggering auto-save")
        
        // Cancel existing timer if there is one
        autoSaveTimer?.cancel()
        
        // Set up a new timer to save after 1.5 seconds of inactivity
        autoSaveTimer = Just(())
            .delay(for: .seconds(1.5), scheduler: RunLoop.main)
            .sink { _ in
                if hasChanges {
                    logger.info("📸 Auto-save timer fired, calling saveProfile()")
                    saveProfile()
                } else {
                    logger.info("📸 Auto-save timer fired but no changes detected")
                }
            }
    }
    
    private func saveProfile() {
        logger.info("📸 saveProfile() called")
        
        // Check if we have a user profile or if the user is logged in
        if profileManager.currentUserProfile == nil {
            logger.warning("📸 Cannot save - no current user profile")
            alertTitle = "Profile Update"
            alertMessage = "You must be logged in to update your profile"
            showAlert = true
            return
        }
        
        saveInProgress = true
        hasChanges = false
        
        // Build updates dictionary
        var updates: [String: Any] = [:]
        
        if !userName.isEmpty {
            updates["name"] = userName
            logger.info("📸 Adding name to updates: \(userName)")
        }
        
        if !email.isEmpty {
            updates["email"] = email
            logger.info("📸 Adding email to updates: \(email)")
        }
        
        if let birthday = birthday {
            updates["birthday"] = birthday.timeIntervalSince1970
            logger.info("📸 Adding birthday to updates: \(birthday)")
        }
                      
        
        if !userBio.isEmpty {
            updates["bio"] = userBio
            logger.info("📸 Adding bio to updates: \(userBio)")
        }
        
        logger.info("📸 Total updates to save: \(updates.count)")
        
        // Skip if no updates
        if updates.isEmpty {
            logger.info("📸 No updates to save, returning early")
            saveInProgress = false
            return
        }
        
        // Also update UserSettings
        logger.info("📸 Updating UserSettings")
        userSettings.updateName(userName.isEmpty ? nil : userName)
        userSettings.updateEmail(email.isEmpty ? nil : email)
        
        // Update profile in Firestore
        logger.info("📸 Starting Firestore update")
        Task {
            do {
                logger.info("📸 Calling profileManager.updateUserProfile")
                try await profileManager.updateUserProfile(updates: updates)
                await MainActor.run {
                    saveInProgress = false
                    logger.info("📸 Profile updated successfully")
                    // Show a temporary alert for debug builds
                    #if DEBUG
                    alertTitle = "Profile Update"
                    alertMessage = "Profile updated successfully"
                    showAlert = true
                    #endif
                    
                    // After successful save, update the displayed info
                    updateDisplayedInfo()
                }
            } catch {
                logger.error("📸 Error updating profile: \(error.localizedDescription)")
                await MainActor.run {
                    saveInProgress = false
                    alertTitle = "Profile Update"
                    alertMessage = "Error updating profile: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
   
    // MARK: - Helper Methods
    private func loadProfileData() {
        if let profile = profileManager.currentUserProfile {
            // Use real name if available, otherwise use a sensible default
            userName = profile.name?.isEmpty == false ? profile.name! : "User"
            
            // Load bio if available, otherwise use empty
            userBio = profile.bio ?? ""
            
            // Load email and phone
            email = profile.email ?? ""
            phoneNumber = profile.phoneNumber ?? ""
            
            // Load birthday
            birthday = profile.birthday
            
                                    
            // Construct userInfo
            updateDisplayedInfo()
            
            // Set profile gradient based on name (for consistency)
            if let name = profile.name, !name.isEmpty {
                let index = abs(name.hash % AppColors.avatarGradients.count)
                profileRingGradient = AppColors.avatarGradients[index]
            }
            
            // Preload the profile image for faster display
            preloadProfileImage()
        } else {
            // Set empty/default values when no profile exists
            userName = "User"
            userBio = ""
            userInfo = ""
            email = ""
            phoneNumber = ""         
        }
    }
    
    private func updateDisplayedInfo() {
        var infoComponents: [String] = []
        
        // Format phone for display if available
        if !phoneNumber.isEmpty {
            let formattedPhone = formatPhoneForDisplay(phoneNumber)
            infoComponents.append("📱 \(formattedPhone)")
        }
        
        // Format birthday for display if available
        if let birthday = birthday {
            let formattedBirthday = formatBirthdayForDisplay(birthday)
            infoComponents.append("🎂 \(formattedBirthday)")
        }
        
        // Join components with bullet separator
        userInfo = infoComponents.isEmpty ? "" : infoComponents.joined(separator: " • ")
    }
    
    // Helper to format phone number for display
    private func formatPhoneForDisplay(_ phone: String) -> String {
        // Only keep digits
        let cleaned = phone.filter { $0.isNumber }
        
        // For short numbers, just return the original
        if cleaned.count < 10 {
            return phone
        }
        
        var formatted = ""
        
        // If there are more than 10 digits, add the extra digits at the beginning
        if cleaned.count > 10 {
            let extraDigits = String(cleaned.prefix(cleaned.count - 10))
            formatted += extraDigits + " "
        }
        
        // Get the last 10 digits for standard formatting
        let lastTenDigits = cleaned.count > 10 ? 
            String(cleaned.suffix(10)) : cleaned
        
        // Format the last 10 digits as (XXX) XXX-XXXX
        for (index, character) in lastTenDigits.enumerated() {
            if index == 0 {
                formatted += "("
            }
            if index == 3 {
                formatted += ") "
            }
            if index == 6 {
                formatted += "-"
            }
            formatted.append(character)
        }
        
        return formatted
    }
    
    // Helper to format birthday for display
    private func formatBirthdayForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Image Loading and Upload Functions
    private func loadTransferableImage(from item: PhotosPickerItem) async {
        logger.info("📸 Loading transferable image")
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            logger.error("📸 Failed to load transferable image data")
            await MainActor.run {
                alertTitle = "Photo Error"
                alertMessage = "Could not load the selected image"
                showAlert = true
            }
            return
        }
        
        guard let uiImage = UIImage(data: data) else {
            logger.error("📸 Failed to create UIImage from data")
            await MainActor.run {
                alertTitle = "Photo Error"
                alertMessage = "The selected image appears to be invalid"
                showAlert = true
            }
            return
        }
        
        // Update the UI with the selected image
        await MainActor.run {
            logger.info("📸 Successfully loaded image, updating UI")
            profileImage = uiImage
        }
        
        // Upload the image to Firebase Storage
        await uploadProfileImage(uiImage)
    }
    
    private func uploadProfileImage(_ image: UIImage) async {
        logger.info("📸 Starting profile image upload")
        guard let userId = profileManager.currentUserProfile?.id else {
            logger.error("📸 No user profile ID available for image upload")
            await MainActor.run {
                alertTitle = "Photo Error"
                alertMessage = "You must have a profile before setting a profile picture"
                showAlert = true
            }
            return
        }
        
        await MainActor.run {
            isUploadingImage = true
        }
        
        do {
            // Resize image for storage efficiency
            guard let resizedImage = image.resized(to: CGSize(width: 500, height: 500)) else {
                logger.error("📸 Failed to resize image")
                throw NSError(domain: "UserProfileView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not resize image"])
            }
            
            guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
                logger.error("📸 Failed to convert image to JPEG data")
                throw NSError(domain: "UserProfileView", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to JPEG data"])
            }
            
            logger.info("📸 Image prepared for upload: \(imageData.count) bytes")
            
            // Create a reference to Firebase Storage
            let storage = Storage.storage()
            let storageRef = storage.reference()
            let profileImagesRef = storageRef.child("profile_images/\(userId).jpg")
            
            logger.info("📸 Uploading image to Firebase Storage")
            // Upload the image
            _ = try await profileImagesRef.putDataAsync(imageData)
            logger.info("📸 Image upload successful, getting download URL")
            
            // Get the download URL
            let downloadURL = try await profileImagesRef.downloadURL()
            logger.info("📸 Got download URL: \(downloadURL.absoluteString)")
            
            // Update profile with new image URL
            logger.info("📸 Updating profile with new image URL")
            try await profileManager.updateUserProfile(updates: ["profileImageURL": downloadURL.absoluteString])
            
            await MainActor.run {
                isUploadingImage = false
                alertTitle = "Profile Photo"
                alertMessage = "Profile photo updated successfully"
                showAlert = true
                logger.info("📸 Profile photo update completed successfully")
            }
        } catch {
            logger.error("📸 Error uploading profile image: \(error.localizedDescription)")
            await MainActor.run {
                isUploadingImage = false
                alertTitle = "Photo Error"
                alertMessage = "Error uploading photo: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func preloadProfileImage() {
        guard let photoURL = profileManager.currentUserProfile?.profileImageURL,
              !photoURL.isEmpty,
              let url = URL(string: photoURL) else {
            return
        }
        
        // Check if image is already in cache
        if let cachedImage = ImageCacheManager.shared.getImage(for: photoURL) {
            self.cachedProfileImage = cachedImage
            return
        }
        
        // Not in cache, start downloading
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  error == nil,
                  let downloadedImage = UIImage(data: data) else {
                return
            }
            
            // Cache the image
            ImageCacheManager.shared.storeImage(downloadedImage, for: photoURL)
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.cachedProfileImage = downloadedImage
            }
        }.resume()
    }
}

#Preview {
    UserProfileView()
        .preferredColorScheme(.dark)
} 
