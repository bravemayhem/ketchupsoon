import SwiftUI
import PhotosUI
import SwiftData
import Combine

// Helper extension to simplify getting objectWillChange publisher from any ProfileViewModel
extension ProfileViewModel {
    var anyObjectWillChange: AnyPublisher<Void, Never> {
        // Create a subject we control that has the correct types
        let subject = PassthroughSubject<Void, Never>()
        
        // Set up our own observation mechanism
        Task { @MainActor in
            // Use the objectWillChange property but treat it as just a trigger
            // The actual value doesn't matter - we just forward to our subject
            let _ = self.objectWillChange.sink { _ in
                subject.send()
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
}

// Add type erasing wrapper
@MainActor
class AnyProfileViewModel: ObservableObject {
    private var _viewModel: any ProfileViewModel
    private var updateTimer: Timer?
    
    // Forward properties from the wrapped viewModel
    var profileRingGradient: LinearGradient { _viewModel.profileRingGradient }
    var profileImage: UIImage? { _viewModel.profileImage }
    var cachedProfileImage: UIImage? { _viewModel.cachedProfileImage }
    var isLoadingImage: Bool { _viewModel.isLoadingImage }
    var profileEmoji: String { _viewModel.profileEmoji }
    var isEditMode: Bool { 
        get { _viewModel.isEditMode }
        set { _viewModel.isEditMode = newValue }
    }
    var canEdit: Bool { _viewModel.canEdit }
    
    // Additional properties needed specifically for this component
    var cameraEmoji: String {
        if let combinedVM = _viewModel as? CombinedProfileViewModel {
            return combinedVM.cameraEmoji
        }
        return "📸" // Default
    }
    
    init(wrapping viewModel: any ProfileViewModel) {
        self._viewModel = viewModel
        
        // Set up a timer to check for updates every 100ms
        // This avoids complex publisher type issues while still keeping the UI responsive
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}

struct UserProfileImageComponent: View {
    // MARK: - Properties
    @ObservedObject private var viewModel: AnyProfileViewModel
    
    @Binding var showPhotoPicker: Bool
    @Binding var showImagePicker: Bool
    @Binding var showCropView: Bool
    @Binding var showSourceTypeActionSheet: Bool
    @Binding var sourceType: UIImagePickerController.SourceType
    
    var isEditable: Bool
    
    // Initialize with the type-erased wrapper
    init(viewModel: any ProfileViewModel, 
         showPhotoPicker: Binding<Bool>,
         showImagePicker: Binding<Bool>,
         showCropView: Binding<Bool>,
         showSourceTypeActionSheet: Binding<Bool> = .constant(false),
         sourceType: Binding<UIImagePickerController.SourceType> = .constant(.camera),
         isEditable: Bool = false) {
        
        _viewModel = ObservedObject(initialValue: AnyProfileViewModel(wrapping: viewModel))
        _showPhotoPicker = showPhotoPicker
        _showImagePicker = showImagePicker
        _showCropView = showCropView
        _showSourceTypeActionSheet = showSourceTypeActionSheet
        _sourceType = sourceType
        self.isEditable = isEditable
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Profile Image/Avatar
            ZStack {
                // Base circle with gradient
                Circle()
                    .fill(viewModel.profileRingGradient)
                    .frame(width: 120, height: 120)
                
                // Profile image or placeholder
                if let profileImage = viewModel.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                } else if let cachedImage = viewModel.cachedProfileImage {
                    Image(uiImage: cachedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                } else {
                    // Default placeholder with emoji
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 110, height: 110)
                        
                        Text(viewModel.profileEmoji)
                            .font(.system(size: 50))
                    }
                }
                
                // Loading indicator when uploading
                if viewModel.isLoadingImage {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 110, height: 110)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                }
                
                // Edit button (only when in edit mode and for own profile)
                if viewModel.isEditMode && viewModel.canEdit {
                    Button(action: {
                        showSourceTypeActionSheet = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppColors.accentGradient1)
                                .frame(width: 30, height: 30)
                            
                            Text(viewModel.cameraEmoji)
                                .font(.system(size: 16))
                        }
                    }
                    .offset(x: 40, y: 40)
                }
            }
        }
    }
    
    // MARK: - Sheet Actions
    
    private func openSourceTypeActionSheet() {
        showImagePicker = true
    }
}

// MARK: - Preview Provider
struct UserProfileImageComponent_Previews: PreviewProvider {
    static var previews: some View {
        let previewContainer = try! ModelContainer(for: UserModel.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        let viewModel = CombinedProfileViewModel(
            modelContext: previewContainer.mainContext,
            firebaseSyncService: FirebaseSyncServiceFactory.preview
        )
        
        return ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            UserProfileImageComponent(
                viewModel: viewModel, 
                showPhotoPicker: .constant(false),
                showImagePicker: .constant(false),
                showCropView: .constant(false),
                showSourceTypeActionSheet: .constant(false),
                sourceType: .constant(.camera),
                isEditable: true
            )
        }
        .frame(width: 300, height: 200)
        .preferredColorScheme(.dark)
    }
}
