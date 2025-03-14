import SwiftUI
import SwiftData
import FirebaseAuth
import OSLog
import PhotosUI

struct ProfileView<ViewModel>: View where ViewModel: AnyObject & ProfileViewModel {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Dependencies
    @EnvironmentObject private var firebaseSyncService: FirebaseSyncService
    
    // MARK: - ViewModel
    @ObservedObject var viewModel: ViewModel
    
    // MARK: - UI State
    @State private var showPhotoPicker = false
    @State private var showImagePicker = false
    @State private var showSourceTypeActionSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showCropView: Bool = false
    
    // Edit form state
    @State private var editName: String = ""
    @State private var editBio: String = ""
    @State private var isSaving: Bool = false
    
    // MARK: - Logger
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "ProfileView")
    
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
                    if viewModel.isEditMode && viewModel.canEdit {
                        // Edit form when in edit mode and editable
                        profileEditContent
                    } else {
                        // Profile content in view mode
                        profileContent
                    }
                }
                .padding(.bottom, 80) // Extra padding for bottom action buttons
            }
            .refreshable {
                // Using SwiftUI's native refreshable which provides better system integration
                // and avoids constant refresh triggers we saw with custom implementation
                print("🔄 Native refreshable: Starting profile refresh")
                await viewModel.refreshProfile()
                print("✅ Native refreshable: Completed profile refresh")
            }
            
            // Conditional action buttons at bottom
            if viewModel.showActions {
                profileActionButtons
            }
            
            // Edit button with the proper styling and position
            if viewModel.canEdit && !viewModel.isEditMode {
                VStack {
                    Spacer() // Push to bottom
                    HStack {
                        Spacer() // Push to right side
                        Button(action: {
                            print("🛠️ DEBUG: Edit button tapped")
                            viewModel.isEditMode = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.accentGradient)
                                    .frame(width: 56, height: 56)
                                    .shadow(color: AppColors.purple.opacity(0.5), radius: 5, x: 0, y: 3)
                                
                                Image(systemName: "pencil")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 100)
                        .zIndex(10) // Ensure it's above other content
                    }
                }
            }
            
            // Loading overlay
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.isEditMode && viewModel.canEdit {
                    Button("Cancel") {
                        viewModel.isEditMode = false
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.canEdit && viewModel.isEditMode {
                    Button("Save") {
                        // Save logic handled by view model
                        Task {
                            await saveProfile(name: editName, bio: editBio)
                        }
                    }
                }
            }
        }                        
        .onAppear {
            // Add debugging to track view lifecycle
            // Use a UUID instead of ObjectIdentifier since 'self' is a struct
            let viewInstanceId = UUID().uuidString.prefix(6)
            print("🔍 DEBUG: ProfileView.onAppear - Instance: \(viewInstanceId)")
            
            // ADDED: Additional detailed debug information
            print("🔬 DETAILED DEBUG: Profile View Model Analysis:")
            print("- Type: \(type(of: viewModel))")
            print("- canEdit: \(viewModel.canEdit)")
            print("- isEditMode: \(viewModel.isEditMode)")
            print("- userName: \"\(viewModel.userName)\"")
            print("- Protocol conformance: Yes (guaranteed by generic constraint)")
            
            // Original debug
            print("🛠️ DEBUG: canEdit = \(viewModel.canEdit), isEditMode = \(viewModel.isEditMode)")
            print("🛠️ DEBUG: View model type: \(type(of: viewModel))")
            print("🛠️ DEBUG: userName = \(viewModel.userName)")
            
            // ADDED: Debug the profile type in CombinedProfileViewModel
            if let combinedVM = viewModel as? CombinedProfileViewModel {
                print("🔍 DEBUG: ProfileType = \(combinedVM.profileTypeDescription)")
            }
            
            // Initialize edit form state with current values
            editName = viewModel.userName
            editBio = viewModel.userBio
            
            // Only trigger a fresh load if we have no data yet to avoid unnecessary loading
            // This works with our debouncing mechanism in UserProfileViewModel
            if viewModel.isInitialDataLoad {
                print("🔍 DEBUG: ProfileView triggering initial profile load - Instance: \(viewInstanceId)")
                Task {
                    print("🔍 DEBUG: ProfileView starting loadProfile task - Instance: \(viewInstanceId)")
                    await viewModel.loadProfile()
            
                    // Update edit form state after loading
                    editName = viewModel.userName
                    editBio = viewModel.userBio
                    
                    // Print debug info after loading
                    print("🛠️ DEBUG: After loading - canEdit = \(viewModel.canEdit), isEditMode = \(viewModel.isEditMode)")
            
                    print("🔍 DEBUG: ProfileView completed loadProfile task - Instance: \(viewInstanceId)")
                }
            } else {
                print("🔍 DEBUG: ProfileView skipping load (not initial) - Instance: \(viewInstanceId)")
            }
        }
        .onDisappear {
            // Add debugging to track view lifecycle
            // Use a simple string identifier since we can't use ObjectIdentifier with structs
            print("🔍 DEBUG: ProfileView.onDisappear")
            // Additional cleanup if needed
        }
        .sheet(isPresented: $showPhotoPicker) {
            if #available(iOS 16.0, *) {
                PhotosPicker(selection: $selectedPhoto,
                             matching: .images,
                             photoLibrary: .shared()) {
                    Text("Select Photo")
                }
                .photosPickerStyle(.inline)
                .photosPickerAccessoryVisibility(.visible)
                .presentationDetents([.medium, .large])
            } else {
                PhotosPicker(selection: $selectedPhoto,
                             matching: .images,
                             photoLibrary: .shared()) {
                    Text("Select Photo")
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
        }
        .sheet(isPresented: $showCropView) {
            CropViewWrapper(viewModel: viewModel)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .actionSheet(isPresented: $showSourceTypeActionSheet) {
            ActionSheet(
                title: Text("Select Photo Source"),
                buttons: [
                    .default(Text("Camera")) {
                        self.sourceType = .camera
                        self.showImagePicker = true
                    },
                    .default(Text("Photo Library")) {
                        self.sourceType = .photoLibrary
                        self.showImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
    }
    
    // MARK: - Profile Content
    private var profileContent: some View {
        VStack(spacing: 20) {
            // Profile picture
            ZStack {
                // Gradient ring with enhanced glow effect
                Circle()
                    .fill(viewModel.profileRingGradient)
                    .frame(width: 150, height: 150)
                    .modifier(GlowModifier(color: AppColors.purple, radius: 12, opacity: 0.8))
                    .shadow(color: AppColors.purple.opacity(0.5), radius: 8, x: 0, y: 0)
                
                // Profile image or emoji
                if let image = viewModel.profileImage ?? viewModel.cachedProfileImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                } else if let profileImageURL = viewModel.profileImageURL, !profileImageURL.isEmpty, let url = URL(string: profileImageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                    } placeholder: {
                        ZStack {
                            // Show emoji placeholder while loading
                            Text(viewModel.profileEmoji)
                                .font(.system(size: 50))
                                .frame(width: 140, height: 140)
                            
                            // Add a progress indicator
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    }
                } else {
                    // Emoji placeholder when no image is available
                    Text(viewModel.profileEmoji)
                        .font(.system(size: 50))
                        .frame(width: 140, height: 140)
                }
                
                // Camera button for current user
                if viewModel.canEdit {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                showSourceTypeActionSheet = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.accentGradient)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .offset(x: 10, y: 10)
                        }
                    }
                    .frame(width: 140, height: 140)
                }
            }
            .padding(.top, 20)
            
            // User name
            Text(viewModel.userName)
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                .padding(.top, 10)
            
            // Bio section
            if !viewModel.userBio.isEmpty {
                Text(viewModel.userBio)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 5)
            }
            
            // User info section for phone and birthday
            VStack(spacing: 12) {
                if !viewModel.phoneNumber.isEmpty {
                    HStack(spacing: 8) {
                        Text("📱")
                        Text(formatPhoneForDisplay(viewModel.phoneNumber))
                            .font(.system(size: 16))
                        // Add lock icon to show phone number is not editable
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                if let birthday = viewModel.birthday {
                    HStack(spacing: 8) {
                        Text("🎂")
                        Text(formatBirthdayForDisplay(birthday))
                            .font(.system(size: 16))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .clayMorphism(cornerRadius: 30)
        .padding(.horizontal, 10)
    }
    
    // MARK: - Edit Form
    private var profileEditContent: some View {
        // This is a placeholder that should be implemented based on your app's requirements
        // This should only be visible when the profile is editable and in edit mode
        VStack(spacing: 20) {
            Text("Edit Profile")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 10)
            
            // Wrap the entire content in claymorphism, not just the form fields
            VStack(spacing: 20) {
                // Profile image section
                ZStack {
                    // Circle background with gradient
                    Circle()
                        .fill(viewModel.profileRingGradient)
                        .frame(width: 150, height: 150)
                        .modifier(GlowModifier(color: AppColors.purple, radius: 12, opacity: 0.8))
                        .shadow(color: AppColors.purple.opacity(0.5), radius: 8, x: 0, y: 0)
                    
                    // Profile image or emoji
                    if let image = viewModel.profileImage ?? viewModel.cachedProfileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                    } else {
                        Text(viewModel.profileEmoji)
                            .font(.system(size: 50))
                            .frame(width: 140, height: 140)
                    }
                    
                    // Camera button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                showSourceTypeActionSheet = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.accentGradient)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .offset(x: 10, y: 10)
                        }
                    }
                    .frame(width: 140, height: 140)
                }
                .padding(.bottom, 10)
                
                // Form fields
                VStack(spacing: 16) {
                    // Name field - Now using local state variable
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("Your name", text: $editName)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    
                    // Bio field - Now using local state variable
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("Your bio", text: $editBio)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    
                    // Birthday field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Birthday")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Get a date 18 years ago for default birthday
                        let defaultDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { viewModel.birthday ?? defaultDate },
                                set: { newDate in
                                    // This is needed since ProfileViewModel has birthday as a get-only property
                                    if let userVM = viewModel as? UserProfileViewModel {
                                        userVM.birthday = newDate
                                    } else if let combinedVM = viewModel as? CombinedProfileViewModel {
                                        combinedVM.birthday = newDate
                                    }
                                }
                            ),
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .datePickerStyle(.compact)
                        .tint(.white)
                    }
                    
                    // Phone number display (not editable) with lock icon
                    if !viewModel.phoneNumber.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            HStack {
                                Text(formatPhoneForDisplay(viewModel.phoneNumber))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.trailing, 10)
                            }
                        }
                    }
                    
                    // Add other fields as needed
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
            .clayMorphism(cornerRadius: 30)
            .padding(.horizontal, 10)
            
            // Save and cancel buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    // Reset edit form state and exit edit mode
                    editName = viewModel.userName
                    editBio = viewModel.userBio
                    viewModel.isEditMode = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .foregroundColor(.white)
                
                Button("Save") {
                    Task {
                        // Pass the edited values to save method
                        await saveProfile(name: editName, bio: editBio)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppColors.accentGradient)
                .cornerRadius(10)
                .foregroundColor(.white)
                .disabled(isSaving)
                .overlay(
                    Group {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Action Buttons
    private var profileActionButtons: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                // These buttons should be customized based on the profile type
                // For example, for friends you might have buttons to message, remove, etc.
                Button(action: {
                    // Action handled by view model or parent view
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Message")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.accentGradient)
                    .cornerRadius(12)
                    .shadow(color: AppColors.purple.opacity(0.5), radius: 5, x: 0, y: 3)
                }
                
                Button(action: {
                    // Action handled by view model or parent view
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.xmark")
                        Text("Remove")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.accentGradient1)
                    .cornerRadius(12)
                    .shadow(color: Color.red.opacity(0.5), radius: 5, x: 0, y: 3)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    // MARK: - Helper Methods
    private func saveProfile(name: String, bio: String) async {
        // Set local save progress state
        isSaving = true
        defer { isSaving = false }
        
        // Profile save logic would depend on which view model is being used
        if let userProfileViewModel = viewModel as? UserProfileViewModel {
            // Set the edited values on the view model before saving
            userProfileViewModel.name = name
            userProfileViewModel.bio = bio
            // Birthday changes are set directly on the viewModel via the DatePicker binding
            
            userProfileViewModel.saveProfile()
            viewModel.isEditMode = false
            
            print("🔍 DEBUG: Saving profile with name: \(name), bio: \(bio), birthday: \(String(describing: userProfileViewModel.birthday))")
        } else if let combinedViewModel = viewModel as? CombinedProfileViewModel {
            // If using the CombinedProfileViewModel
            combinedViewModel.name = name
            combinedViewModel.bio = bio
            // Birthday changes are set directly on the viewModel via the DatePicker binding
            
            await combinedViewModel.saveProfile()
            viewModel.isEditMode = false
            
            print("🔍 DEBUG: Saving profile with name: \(name), bio: \(bio), birthday: \(String(describing: combinedViewModel.birthday))")
        }
    }
    
    // MARK: - Image Selection State
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    
    // MARK: - Alert State
    @State private var showAlert = false
    @State private var alertTitle = "Profile"
    @State private var alertMessage = ""
}

// MARK: - CropViewWrapper
extension ProfileView {
    struct CropViewWrapper: View {
        let viewModel: any ProfileViewModel
        
        var body: some View {
            if let userVM = viewModel as? UserProfileViewModel,
               let croppingImage = userVM.croppingImage {
                CropView(image: croppingImage) { croppedImage in
                    Task {
                        await userVM.uploadProfileImage(croppedImage)
                    }
                }
            } else {
                Text("Unable to crop image")
            }
        }
    }
}

// MARK: - Helper Methods
extension ProfileView {
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
}

// MARK: - Preview
#Preview {
    // Create a sample user for preview
    let container = try! ModelContainer(for: UserModel.self)
    let firebaseSyncService = FirebaseSyncService(modelContext: container.mainContext)
    
    NavigationView {
        ProfileView(viewModel: PreviewProfileViewModel(modelContext: container.mainContext))
            .environmentObject(firebaseSyncService)
            .environment(\.modelContext, container.mainContext)
    }
}

// A simple implementation for previews
class PreviewProfileViewModel: ProfileViewModel {
    var id: String = "preview123"
    var userName: String = "Preview User"
    var userBio: String = "This is a preview of the profile view component."
    var profileImageURL: String? = nil
    var profileImage: UIImage? = nil
    var cachedProfileImage: UIImage? = nil
    var isLoadingImage: Bool = false
    var profileRingGradient: LinearGradient = AppColors.accentGradient2
    var isEditMode: Bool = false
    var isRefreshing: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var canEdit: Bool = true
    var showActions: Bool = false
    var isInitialDataLoad: Bool = true
    var phoneNumber: String = "(555) 123-4567" 
    var birthday: Date? = Date() // Current date as placeholder
    
    // Repository and services
    var userRepository: UserRepository?
    var firebaseSyncService: FirebaseSyncService?
    
    // Initializer with modelContext
    init(modelContext: ModelContext? = nil) {
        if let context = modelContext {
            self.userRepository = UserRepositoryFactory.createRepository(modelContext: context)
        }
    }
    
    func loadProfile() async {
        // Preview implementation
    }
    
    func refreshProfile() async {
        // Preview implementation
    }
}
