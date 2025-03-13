import SwiftUI
import PhotosUI
import SwiftData

struct UserProfileImageComponent: View {
    // MARK: - Properties
    @ObservedObject var viewModel: UserProfileViewModel
    @Binding var showPhotoPicker: Bool
    @Binding var showImagePicker: Bool
    @Binding var showCropView: Bool
    @Binding var showSourceTypeActionSheet: Bool
    @Binding var sourceType: UIImagePickerController.SourceType
    
    var isEditable: Bool
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Gradient ring with glow effect
            Circle()
                .fill(viewModel.profileRingGradient)
                .frame(width: 150, height: 150)
                .glow(color: AppColors.purple, radius: 10, opacity: 0.6)
            
            // Profile image or emoji
            if let profileImage = viewModel.profileImage {
                // Show selected image while processing
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
            } else if let cachedImage = viewModel.cachedProfileImage {
                // Show cached image
                Image(uiImage: cachedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
            } else if let photoURL = UserProfileManager.shared.currentUserProfile?.profileImageURL,
                      !photoURL.isEmpty {
                // Profile image from URL with loading indicator
                ZStack {
                    // Show emoji placeholder while loading
                    Text(viewModel.profileEmoji)
                        .font(.system(size: 50))
                        .frame(width: 140, height: 140)
                    
                    // Add a progress indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                .onAppear {
                    viewModel.preloadProfileImage(from: photoURL)
                }
            } else {
                // Emoji placeholder when no image is available
                Text(viewModel.profileEmoji)
                    .font(.system(size: 50))
                    .frame(width: 140, height: 140)
            }
            
            // Loading overlay when uploading
            if viewModel.isUploadingImage {
                ProgressView()
                    .frame(width: 140, height: 140)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            // Camera button only shown in edit mode
            if isEditable {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Text(viewModel.cameraEmoji)
                        .font(.system(size: 18))
                }
                .offset(x: 45, y: 45)
                .onTapGesture {
                    showSourceTypeActionSheet = true
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: UserModel.self)
    let firebaseSyncService = FirebaseSyncService(modelContext: container.mainContext)
    let viewModel = UserProfileViewModel(
        modelContext: container.mainContext,
        firebaseSyncService: firebaseSyncService
    )
    
    UserProfileImageComponent(
        viewModel: viewModel,
        showPhotoPicker: .constant(false),
        showImagePicker: .constant(false),
        showCropView: .constant(false),
        showSourceTypeActionSheet: .constant(false),
        sourceType: .constant(.photoLibrary),
        isEditable: true
    )
    .preferredColorScheme(.dark)
    .modelContainer(container)
}
