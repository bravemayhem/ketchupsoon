import SwiftUI

struct AvatarScreen: View {
    @EnvironmentObject var viewModel: UserOnboardingViewModel
    @State private var tempImage: UIImage? = nil
    let emojis = ["✨", "🌟", "🚀", "🎸", "🎨", "🎮", "🎵", "💫", "😎"]
    
    // Colors
    private let primaryAccentColor = Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0))
    private let secondaryAccentColor = Color(UIColor(red: 255/255, green: 138/255, blue: 66/255, alpha: 1.0))
    private let purpleAccentColor = Color(UIColor(red: 100/255, green: 66/255, blue: 255/255, alpha: 1.0))
    private let darkBackgroundColor = Color(UIColor(red: 21/255, green: 17/255, blue: 50/255, alpha: 0.7))
    
    // Computed properties to simplify expressions
    private var accentGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [primaryAccentColor, secondaryAccentColor]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var avatarCircleGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [purpleAccentColor, primaryAccentColor]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var darkBackgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [darkBackgroundColor, darkBackgroundColor]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView
            
            ScrollView {
                VStack(spacing: 0) {
                    // Avatar preview
                    avatarPreviewView
                    
                    // Photo options
                    photoOptionsView
                    
                    // Emoji selection
                    emojiSelectionView
                }
            }
            
            Spacer()
            
            // Navigation buttons
            navigationButtonsView
        }
        .padding(20)
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(selectedImage: $tempImage, sourceType: viewModel.sourceType)
                .onDisappear {
                    if let image = tempImage {
                        viewModel.setImageAvatar(image)
                        tempImage = nil
                    }
                }
        }
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("Your")
                    .font(.custom("SpaceGrotesk-Bold", size: 24))
                    .foregroundColor(.white)
                Text("Avatar ✨")
                    .font(.custom("SpaceGrotesk-Bold", size: 24))
                    .foregroundColor(primaryAccentColor)
            }
            
            Text("Personalize your profile")
                .font(.custom("SpaceGrotesk-Regular", size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.bottom, 24)
    }
    
    private var avatarPreviewView: some View {
        HStack {
            Spacer()
            ZStack {
                Circle()
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2.5, dash: [5])
                    )
                    .frame(width: 128, height: 128)
                    .foregroundStyle(avatarCircleGradient)
                    .shadow(color: purpleAccentColor.opacity(0.3), radius: 15)
                
                Circle()
                    .fill(darkBackgroundGradient)
                    .frame(width: 118, height: 118)
                
                if viewModel.profileData.useImageAvatar, let image = viewModel.profileData.avatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Text(viewModel.profileData.avatarEmoji)
                        .font(.system(size: 48))
                }
            }
            Spacer()
        }
        .padding(.bottom, 30)
    }
    
    private var photoOptionsView: some View {
        VStack(spacing: 12) {
            // Camera button
            cameraButton
            
            // Gallery button
            galleryButton
        }
        .padding(.bottom, 30)
    }
    
    private var cameraButton: some View {
        Button {
            viewModel.showCamera()
        } label: {
            Text("take a photo 📸")
                .font(.custom("SpaceGrotesk-SemiBold", size: 16))
                .foregroundColor(.white)
                .frame(width: 200)
                .padding(.vertical, 12)
                .background(accentGradient)
                .cornerRadius(20)
                .shadow(color: primaryAccentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var galleryButton: some View {
        Button {
            viewModel.showPhotoLibrary()
        } label: {
            Text("choose from library")
                .font(.custom("SpaceGrotesk-Regular", size: 16))
                .foregroundColor(.white)
                .frame(width: 200)
                .padding(.vertical, 12)
                .background(darkBackgroundGradient)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity)
    }
    
    private var emojiSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("or choose an emoji")
                .font(.custom("SpaceGrotesk-SemiBold", size: 16))
                .foregroundColor(.white)
            
            emojiGrid
        }
    }
    
    private var emojiGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 12)], spacing: 12) {
            ForEach(emojis, id: \.self) { emoji in
                emojiButton(for: emoji)
            }
        }
    }
    
    private func emojiButton(for emoji: String) -> some View {
        let isSelected = !viewModel.profileData.useImageAvatar && viewModel.profileData.avatarEmoji == emoji
        
        return Button {
            viewModel.setEmojiAvatar(emoji)
        } label: {
            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 48, height: 48)
                .background(
                    isSelected ? accentGradient : darkBackgroundGradient
                )
                .cornerRadius(24)
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? Color.clear : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isSelected ? primaryAccentColor.opacity(0.3) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
    }
    
    private var navigationButtonsView: some View {
        HStack(spacing: 12) {
            // Back button
            Button {
                viewModel.previousStep()
            } label: {
                Text("Back")
                    .font(.custom("SpaceGrotesk-Regular", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
            }
            
            // Finish button
            Button {
                viewModel.nextStep()
            } label: {
                Text("Finish")
                    .font(.custom("SpaceGrotesk-SemiBold", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accentGradient)
                    .cornerRadius(20)
                    .shadow(color: primaryAccentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
} 
