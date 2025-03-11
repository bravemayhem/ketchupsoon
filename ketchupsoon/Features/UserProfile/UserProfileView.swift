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
    @State private var location: String = ""
    
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
                VStack(spacing: 20) {
                    // Profile header
                    profileHeaderSection
                    
                    if isEditMode {
                        editFormSection
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal)
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
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 35/255, green: 28/255, blue: 65/255, opacity: 0.85),
                            Color(red: 31/255, green: 24/255, blue: 59/255, opacity: 0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 12) {
                // Profile picture and edit button row
                HStack {
                    Spacer()
                    
                    // Profile image with data-aware display
                    ZStack {
                        // Main avatar circle with gradient ring
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [AppColors.gradient2Start, AppColors.gradient2End]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                            .shadow(color: AppColors.gradient2Start.opacity(0.3), radius: 8, x: 0, y: 0)
                        
                        // Profile image or emoji
                        if let profileImage = profileImage {
                            // Show selected image while processing
                            Image(uiImage: profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                        } else if let cachedImage = cachedProfileImage {
                            // Show cached image
                            Image(uiImage: cachedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                        } else if let photoURL = profileManager.currentUserProfile?.profileImageURL,
                                  !photoURL.isEmpty {
                            // Profile image from URL with loading indicator
                            ZStack {
                                // Show emoji placeholder while loading
                                Text(profileEmoji)
                                    .font(.system(size: 44))
                                    .frame(width: 110, height: 110)
                                
                                // Add a progress indicator
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            .onAppear {
                                // Trigger preload if not already done
                                preloadProfileImage()
                            }
                        } else {
                            // Emoji placeholder when no image is available
                            Text(profileEmoji)
                                .font(.system(size: 44))
                                .frame(width: 110, height: 110)
                        }
                        
                        // Loading overlay when uploading
                        if isUploadingImage {
                            ProgressView()
                                .frame(width: 110, height: 110)
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
                        .offset(x: 30, y: 30)
                        .onTapGesture {
                            // Show action sheet to choose image source
                            showSourceTypeActionSheet = true
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 20)
                
                // Name 
                if !isEditMode {
                    Text(userName)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: AppColors.gradient1Start.opacity(0.5), radius: 2, x: 0, y: 0)
                    
                    // Edit button
                    HStack(spacing: 30) {
                        Text(isEditMode ? "save" : "edit")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 44/255, green: 35/255, blue: 75/255),
                                        Color(red: 54/255, green: 45/255, blue: 85/255)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .cornerRadius(999)
                            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                            .onTapGesture {
                                isEditMode.toggle()
                            }
                    }
                    
                    // Bio with subtle highlight
                    if !userBio.isEmpty {
                        Text(userBio)
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 4)
                            .padding(.bottom, 8)
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(4)
                    } else {
                        Text("Add a bio to tell others about yourself")
                            .font(.system(size: 14, weight: .medium))
                            .italic()
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal)
                            .padding(.top, 4)
                            .padding(.bottom, 8)
                    }
                    
                    // Subtle divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 0.5)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 10)
                    
                    // User info cards - replacing the single line text
                    userInfoCardView
                }
            }
        }
        .padding(.top, 15)
    }
    
    // New view for displaying user info in cards
    private var userInfoCardView: some View {
        VStack(spacing: 12) {
            // Only show this section if we have any information to display
            if !location.isEmpty || !phoneNumber.isEmpty || birthday != nil {
                // If we have both location and phone, use an HStack
                // If we have just one, center it
                if !location.isEmpty && !phoneNumber.isEmpty {
                    HStack(spacing: 12) {
                        // Location Card
                        infoCard(icon: "📍", label: "Location", value: location)
                            .frame(maxWidth: .infinity)
                        
                        // Phone Card
                        infoCard(icon: "📱", label: "Phone", value: formatPhoneForDisplay(phoneNumber))
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    // If only one of them exists, display it centered
                    if !location.isEmpty {
                        infoCard(icon: "📍", label: "Location", value: location)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                    }
                    
                    if !phoneNumber.isEmpty {
                        infoCard(icon: "📱", label: "Phone", value: formatPhoneForDisplay(phoneNumber))
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                    }
                }
                
                // Birthday Card - on its own row for better layout
                if let birthday = birthday {
                    infoCard(icon: "🎂", label: "Birthday", value: formatBirthdayForDisplay(birthday))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    // Helper view for creating consistent info cards
    private func infoCard(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [AppColors.gradient1Start.opacity(0.6), AppColors.gradient1End.opacity(0.6)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Text(icon)
                    .font(.system(size: 16))
            }
            
            // Info content
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Edit Form Section
    private var editFormSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 31/255, green: 24/255, blue: 59/255, opacity: 0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            VStack(spacing: 16) {
                // Edit button at top
                HStack {
                    Spacer()
                    Text("save")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color(red: 44/255, green: 35/255, blue: 75/255))
                        .cornerRadius(999)
                        .onTapGesture {
                            isEditMode.toggle()
                        }
                }
                .padding([.top, .trailing], 16)
                
                // Form-like fields
                VStack(spacing: 16) {
                    // Name field
                    HStack {
                        Text("Name")
                            .foregroundColor(.white)
                        Spacer()
                        TextField("Not set", text: $userName)
                            .multilineTextAlignment(.trailing)
                            .textContentType(.name)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .onChange(of: userName) { oldValue, newValue in
                                triggerAutoSave()
                            }
                    }
                    
                    // Email field
                    HStack {
                        Text("Email")
                            .foregroundColor(.white)
                        Spacer()
                        TextField("Not set", text: $email)
                            .multilineTextAlignment(.trailing)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .onChange(of: email) { oldValue, newValue in
                                triggerAutoSave()
                            }
                    }
                    
                    // Phone field
                    HStack {
                        Text("Phone")
                            .foregroundColor(.white)
                        Spacer()
                        HStack {
                            Text(phoneNumber.isEmpty ? "Not set" : phoneNumber)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 12))
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                    
                    // Birthday field
                    HStack {
                        Text("Birthday")
                            .foregroundColor(.white)
                        Spacer()
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
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Location field
                    HStack {
                        Text("Location")
                            .foregroundColor(.white)
                        Spacer()
                        TextField("City, Country", text: $location)
                            .multilineTextAlignment(.trailing)
                            .textContentType(.addressCity)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .onChange(of: location) { oldValue, newValue in
                                triggerAutoSave()
                            }
                    }
                    
                    // Bio field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .foregroundColor(.white)
                        TextEditor(text: $userBio)
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden)
                            .background(Color.white.opacity(0.1))
                            .frame(minHeight: 80)
                            .padding(4)
                            .cornerRadius(8)
                            .onChange(of: userBio) { oldValue, newValue in
                                triggerAutoSave()
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                
                if saveInProgress {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                        Spacer()
                    }
                    .padding(.bottom, 16)
                }
            }
        }
        .padding(.top, 15)
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
        
        // Add location
        if !location.isEmpty {
            updates["location"] = location
            logger.info("📸 Adding location to updates: \(location)")
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
            
            // Load location
            location = profile.location ?? ""
                        
            // Construct userInfo from location
            updateDisplayedInfo()
            
            // Preload the profile image for faster display
            preloadProfileImage()
        } else {
            // Set empty/default values when no profile exists
            userName = "User"
            userBio = ""
            userInfo = ""
            email = ""
            phoneNumber = ""
            location = ""
        }
    }
    
    private func updateDisplayedInfo() {
        var infoComponents: [String] = []
        
        if !location.isEmpty {
            infoComponents.append(location)
        }
        
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
        // If phone number has 10 digits, mask the first 6 digits
        if phone.count >= 10 {
            let index = phone.index(phone.endIndex, offsetBy: -4)
            let lastFour = phone[index...]
            return "***-***-\(lastFour)"
        }
        return phone
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
