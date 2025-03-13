/*
import SwiftUI
import SwiftData

struct UserProfileContentView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: UserProfileViewModel
    @Binding var showPhotoPicker: Bool
    @Binding var showImagePicker: Bool
    @Binding var showCropView: Bool
    @Binding var showSourceTypeActionSheet: Bool
    @Binding var sourceType: UIImagePickerController.SourceType
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            // Profile picture
            UserProfileImageComponent(
                viewModel: viewModel,
                showPhotoPicker: $showPhotoPicker,
                showImagePicker: $showImagePicker,
                showCropView: $showCropView,
                showSourceTypeActionSheet: $showSourceTypeActionSheet,
                sourceType: $sourceType,
                isEditable: false
            )
            .padding(.top, 20)
            
            // User name
            Text(viewModel.userName)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                .padding(.top, 10)
            
            // User bio (as regular text)
            if !viewModel.userBio.isEmpty {
                Text(viewModel.userBio)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.top, 2)
            }
            
            // User info as simple text lines with emoji
            VStack(spacing: 12) {
                if !viewModel.phoneNumber.isEmpty {
                    HStack(spacing: 8) {
                        Text("📱")
                        Text(viewModel.formatPhoneForDisplay(viewModel.phoneNumber))
                            .font(.system(size: 16))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                if let birthday = viewModel.birthday {
                    HStack(spacing: 8) {
                        Text("🎂")
                        Text(viewModel.formatBirthdayForDisplay(birthday))
                            .font(.system(size: 16))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.top, 10)
            
            // Edit profile button
            Button(action: {
                viewModel.isEditMode.toggle()
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
}

#Preview {
    let container = try! ModelContainer(for: UserModel.self)
    let firebaseSyncService = FirebaseSyncService(modelContext: container.mainContext)
    let viewModel = UserProfileViewModel(
        modelContext: container.mainContext,
        firebaseSyncService: firebaseSyncService
    )
    
    UserProfileContentView(
        viewModel: viewModel,
        showPhotoPicker: .constant(false),
        showImagePicker: .constant(false),
        showCropView: .constant(false),
        showSourceTypeActionSheet: .constant(false),
        sourceType: .constant(.photoLibrary)
    )
    .preferredColorScheme(.dark)
    .modelContainer(container)
}
*/
