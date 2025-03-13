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
                .padding(.horizontal)
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
                if viewModel.canEdit {
                    if viewModel.isEditMode {
                        Button("Save") {
                            // Save logic handled by view model
                            Task {
                                await saveProfile()
                            }
                        }
                    } else {
                        Button("Edit") {
                            viewModel.isEditMode = true
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
            
            // Only trigger a fresh load if we have no data yet to avoid unnecessary loading
            // This works with our debouncing mechanism in UserProfileViewModel
            if viewModel.isInitialDataLoad {
                print("🔍 DEBUG: ProfileView triggering initial profile load - Instance: \(viewInstanceId)")
                Task {
                    print("🔍 DEBUG: ProfileView starting loadProfile task - Instance: \(viewInstanceId)")
                    await viewModel.loadProfile()
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
                .font(.system(size: 30, weight: .bold))
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
            
            // Additional profile sections can be customized and added here
            // This could be conditionally shown based on view model properties
        }
    }
    
    // MARK: - Edit Form
    private var profileEditContent: some View {
        // This is a placeholder that should be implemented based on your app's requirements
        // This should only be visible when the profile is editable and in edit mode
        Text("Edit form would go here")
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
    private func saveProfile() async {
        // Profile save logic would depend on which view model is being used
        if let userProfileViewModel = viewModel as? UserProfileViewModel {
            userProfileViewModel.saveProfile()
            viewModel.isEditMode = false
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
