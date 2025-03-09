import SwiftUI
import FirebaseAuth
import PhotosUI
import FirebaseStorage
import OSLog

struct UserProfileView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = UserProfileManager.shared
    
    // Cache-related state
    @State private var cachedProfileImage: UIImage? = nil
    
    // Mock data for UI display - some will be replaced with real data when available
    @State private var userName = "User"
    @State private var userStatus = "available"
    @State private var userBio = "Always up for coffee and deep conversations"
    @State private var userInfo = "LA • poor (but not for long!) • hacker"
    @State private var profileEmoji = "😎"
    @State private var cameraEmoji = "📸"
    
    // Mock stats
    @State private var friendsCount = 8
    @State private var hangoutsCount = 12
    @State private var pendingCount = 4
    
    // Mock preferences
    @State private var availableTimes = ["evenings", "weekends"]
    @State private var favoriteActivities = ["coffee", "food"]
    @State private var travelRadius = "5 miles"
    
    // Mock calendar integration
    @State private var isGoogleCalendarConnected = true
    
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
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "UserProfileView")
    
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
                    
                    // Stats section
                    statsSection
                    
                    // Preferences section
                    preferencesSection
                    
                    // Calendar integration
                    calendarIntegrationSection
                    
                    // Account settings
                    accountSettingsSection
                    
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
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 31/255, green: 24/255, blue: 59/255, opacity: 0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
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
                
                // Name and status
                Text(userName)
                    .font(.system(size: 26, weight: .bold))
                
                // Status and edit button
                HStack(spacing: 30) {
                    // Available status
                    Text(userStatus)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(999)
                    
                    // Edit button
                    Text("edit")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color(red: 44/255, green: 35/255, blue: 75/255))
                        .cornerRadius(999)
                }
                
                // Bio
                Text(userBio)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 4)
                
                // Location and interests
                Text(userInfo)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 20)
            }
        }
        .padding(.top, 15)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 31/255, green: 24/255, blue: 59/255, opacity: 0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            HStack {
                // Friends count
                Spacer()
                VStack(spacing: 8) {
                    Text("\(friendsCount)")
                        .font(.system(size: 28, weight: .bold))
                    Text("friends")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                
                // Vertical divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 40)
                
                // Hangouts count
                Spacer()
                VStack(spacing: 8) {
                    Text("\(hangoutsCount)")
                        .font(.system(size: 28, weight: .bold))
                    Text("hangouts")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                
                // Vertical divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 40)
                
                // Pending count
                Spacer()
                VStack(spacing: 8) {
                    Text("\(pendingCount)")
                        .font(.system(size: 28, weight: .bold))
                    Text("pending")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("preferences")
                    .font(.system(size: 18, weight: .bold))
                    .padding(.leading, 4)
                
                Spacer()
                
                NavigationLink(destination: PreferencesEditView()) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 140/255, green: 69/255, blue: 250/255))
                }
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 31/255, green: 24/255, blue: 59/255, opacity: 0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 20) {
                    // Available times
                    HStack {
                        Text("available times")
                            .font(.system(size: 16))
                        
                        Spacer()
                        
                        ForEach(availableTimes, id: \.self) { time in
                            Text(time)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(red: 100/255, green: 66/255, blue: 255/255, opacity: 0.3))
                                .cornerRadius(999)
                        }
                    }
                    
                    // Favorite activities
                    HStack {
                        Text("favorite activities")
                            .font(.system(size: 16))
                        
                        Spacer()
                        
                        ForEach(favoriteActivities, id: \.self) { activity in
                            Text(activity)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(red: 255/255, green: 68/255, blue: 94/255, opacity: 0.3))
                                .cornerRadius(999)
                        }
                        
                        // Add button
                        ZStack {
                            Circle()
                                .fill(Color(red: 255/255, green: 68/255, blue: 94/255, opacity: 0.3))
                                .frame(width: 32, height: 32)
                            
                            Text("+")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    
                    // Travel radius
                    HStack {
                        Text("travel radius")
                            .font(.system(size: 16))
                        
                        Spacer()
                        
                        Text(travelRadius)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(red: 44/255, green: 111/255, blue: 90/255, opacity: 0.5))
                            .cornerRadius(999)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Calendar Integration Section
    private var calendarIntegrationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("calendar integration")
                    .font(.system(size: 18, weight: .bold))
                    .padding(.leading, 4)
                
                Spacer()
                
                NavigationLink(destination: PreferencesEditView()) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 140/255, green: 69/255, blue: 250/255))
                }
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 31/255, green: 24/255, blue: 59/255, opacity: 0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                HStack {
                    // Google icon
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 40, height: 40)
                        
                        Text("G")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Google Calendar")
                        .font(.system(size: 16))
                    
                    Spacer()
                    
                    // Connected checkmark
                    if isGoogleCalendarConnected {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Account Settings Section
    private var accountSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("account settings")
                .font(.system(size: 18, weight: .bold))
                .padding(.leading, 4)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 31/255, green: 24/255, blue: 59/255, opacity: 0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                HStack {
                    Text("Notifications")
                        .font(.system(size: 16))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadProfileData() {
        if let profile = profileManager.currentUserProfile {
            // Use real name if available, otherwise default to "User"
            userName = profile.name?.isEmpty == false ? profile.name! : "User"
            
            // Load bio if available
            if let profileBio = profile.bio, !profileBio.isEmpty {
                userBio = profileBio
            }
            
            // Preload the profile image for faster display
            preloadProfileImage()
            
            // Keep other mock data for now until we have real data for these
        }
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
