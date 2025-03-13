/*
import SwiftUI
import SwiftData

struct UserProfileEditForm: View {
    // MARK: - Properties
    @ObservedObject var viewModel: UserProfileViewModel
    @Binding var showPhotoPicker: Bool
    @Binding var showImagePicker: Bool
    @Binding var showCropView: Bool
    @Binding var showSourceTypeActionSheet: Bool
    @Binding var sourceType: UIImagePickerController.SourceType
    
    // Get a date 18 years ago for default birthday range
    private var defaultDate: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            // Navigation bar with save/back buttons
            HStack {
                Button(action: {
                    viewModel.isEditMode.toggle()
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
                    viewModel.saveProfile()
                    viewModel.hasChanges = false // Prevent double save from onChange handler
                    viewModel.isEditMode.toggle()
                }) {
                    if viewModel.saveInProgress {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 20, height: 20)
                    } else {
                        Text("Save")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .disabled(viewModel.saveInProgress)
            }
            .padding(.bottom, 20)
            
            // Main form content
            VStack(spacing: 24) {
                // Profile image display at top
                UserProfileImageComponent(
                    viewModel: viewModel,
                    showPhotoPicker: $showPhotoPicker,
                    showImagePicker: $showImagePicker,
                    showCropView: $showCropView,
                    showSourceTypeActionSheet: $showSourceTypeActionSheet,
                    sourceType: $sourceType,
                    isEditable: true
                )
                .padding(.bottom, 20)
                
                // Form fields in a styled container
                VStack(spacing: 20) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("", text: $viewModel.userName)
                            .font(.system(size: 16))
                            .padding()
                            .background(Color.white.opacity(0.07))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .onChange(of: viewModel.userName) { oldValue, newValue in
                                viewModel.triggerAutoSave()
                            }
                    }
                    
                    // Bio field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextEditor(text: $viewModel.userBio)
                            .font(.system(size: 16))
                            .padding(10)
                            .frame(height: 100)
                            .background(Color.white.opacity(0.07))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .onChange(of: viewModel.userBio) { oldValue, newValue in
                                viewModel.triggerAutoSave()
                            }
                    }
                    
                    // Birthday field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Birthday")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { viewModel.birthday ?? defaultDate },
                                set: { viewModel.birthday = $0 }
                            ),
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .onChange(of: viewModel.birthday) { oldValue, newValue in
                            viewModel.triggerAutoSave()
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
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
    
    UserProfileEditForm(
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
