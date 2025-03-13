import SwiftUI
import FirebaseAuth
import PhotosUI
import OSLog
import SwiftData

struct UserProfileView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Dependencies
    @EnvironmentObject private var firebaseSyncService: FirebaseSyncService
    
    // MARK: - ViewModel
    @StateObject private var viewModel = UserProfileViewModel()
    
    // MARK: - UI State
    @State private var showPhotoPicker = false
    @State private var showImagePicker = false
    @State private var showSourceTypeActionSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showCropView: Bool = false
    
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
                    if !viewModel.isEditMode {
                        // Profile content in view mode
                        UserProfileContentView(
                            viewModel: viewModel,
                            showPhotoPicker: $showPhotoPicker,
                            showImagePicker: $showImagePicker,
                            showCropView: $showCropView,
                            showSourceTypeActionSheet: $showSourceTypeActionSheet,
                            sourceType: $sourceType
                        )
                    } else {
                        // Edit form when in edit mode
                        UserProfileEditForm(
                            viewModel: viewModel,
                            showPhotoPicker: $showPhotoPicker,
                            showImagePicker: $showImagePicker,
                            showCropView: $showCropView,
                            showSourceTypeActionSheet: $showSourceTypeActionSheet,
                            sourceType: $sourceType
                        )
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
            // Initialize the ViewModel with dependencies
            viewModel.firebaseSyncService = firebaseSyncService
            viewModel.userRepository = UserRepositoryFactory.createRepository(modelContext: modelContext)
            
            Task {
                await viewModel.loadProfile()
            }
        }
        // Photo picker integration
        .photosPicker(isPresented: $showPhotoPicker, selection: $viewModel.selectedPhoto, matching: .images)
        .onChange(of: viewModel.selectedPhoto) { oldValue, newValue in
            if let newValue = newValue {
                Task {
                    await viewModel.loadTransferableImage(from: newValue)
                }
            }
        }
        // Alert for various messages
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK") { viewModel.showAlert = false }
        } message: {
            Text(viewModel.alertMessage)
        }
        // Camera/photo library integration
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $viewModel.profileImage, sourceType: sourceType)
                .ignoresSafeArea()
                .onDisappear {
                    if let image = viewModel.profileImage {
                        viewModel.croppingImage = image
                        showCropView = true
                    }
                }
        }
        // Crop view integration
        .sheet(isPresented: $showCropView) {
            if viewModel.croppingImage != nil {
                CropImageView(image: $viewModel.croppingImage, onCrop: { croppedImage in
                    viewModel.profileImage = croppedImage
                    showCropView = false
                    Task {
                        await viewModel.uploadProfileImage(croppedImage)
                    }
                }, onCancel: {
                    showCropView = false
                })
            }
        }
        // Image source action sheet
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
        .onChange(of: viewModel.isEditMode) { oldValue, newValue in
            // When exiting edit mode, save any changes
            if oldValue == true && newValue == false && viewModel.hasChanges {
                viewModel.saveProfile()
            }
        }
    }
}

#Preview {
    
    let container = try! ModelContainer(for: UserModel.self)
    let firebaseSyncService = FirebaseSyncService(modelContext: container.mainContext)
    
    UserProfileView()
        .preferredColorScheme(.dark)
        .environmentObject(firebaseSyncService)
        .modelContainer(container)
}
