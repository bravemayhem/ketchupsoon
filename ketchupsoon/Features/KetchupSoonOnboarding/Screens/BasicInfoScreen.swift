import SwiftUI

struct BasicInfoScreen: View {
    @EnvironmentObject var viewModel: KetchupSoonOnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Your")
                        .font(.custom("SpaceGrotesk-Bold", size: 24))
                        .foregroundColor(.white)
                    Text("Profile ✨")
                        .font(.custom("SpaceGrotesk-Bold", size: 24))
                        .foregroundColor(Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)))
                }
                
                Text("Let's get to know you")
                    .font(.custom("SpaceGrotesk-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, 24)
            
            // Form fields
            ScrollView {
                VStack(spacing: 20) {
                    // Name field
                    CustomTextField(
                        title: "full name",
                        placeholder: "taylor morgan",
                        text: $viewModel.profileData.name
                    )
                    
                    // Birthday field - custom styled to match other fields
                    CustomDatePicker(
                        title: "birthday",
                        selection: Binding(
                            get: { viewModel.profileData.birthday ?? Date() },
                            set: { viewModel.profileData.birthday = $0 }
                        ),
                        style: .standard // Explicitly use standard style to match other fields
                    )
                    
                    // Example: To use the gradient style variant in the future:
                    // CustomDatePicker(
                    //     title: "special date",
                    //     selection: $someDate,
                    //     style: .gradient
                    // )
                    
                    // Email field
                    CustomTextField(
                        title: "email",
                        placeholder: "taylor@example.com 📧",
                        text: $viewModel.profileData.email
                    )
                    
                    // Bio field
                    CustomTextEditor(
                        title: "bio (optional)",
                        placeholder: "add a short bio about yourself...",
                        text: $viewModel.profileData.bio
                    )
                }
            }
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 12) {
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
                
                Button {
                    viewModel.nextStep()
                } label: {
                    Text("Continue")
                        .font(.custom("SpaceGrotesk-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)),
                                    Color(UIColor(red: 255/255, green: 138/255, blue: 66/255, alpha: 1.0))
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 0.3)), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.top, 24)
        }
        .padding(20)
    }
}

// Custom Date Picker Component that matches CustomTextField style
// Define DatePickerStyle enum
enum DatePickerStyle {
    case standard // Matches CustomTextField style
    case gradient // Original style with gradient border
}

struct CustomDatePicker: View {
    let title: String
    @Binding var selection: Date
    @State private var showingDatePicker = false
    var style: DatePickerStyle = .standard // Default to standard style
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("SpaceGrotesk-Regular", size: 14)) // Match CustomTextField font
                .foregroundColor(.white.opacity(0.7)) // Match CustomTextField opacity
            
            Button(action: {
                showingDatePicker = true
            }) {
                HStack {
                    // Use the shared DateFormatter.birthday for consistent formatting
                    Text(DateFormatter.birthday.string(from: selection))
                        .font(.custom("SpaceGrotesk-Regular", size: 16))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Calendar icon with accent color
                    Image(systemName: "calendar")
                        .foregroundColor(AppColors.accent)
                        .font(.system(size: 16, weight: .semibold))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16) // Match CustomTextField horizontal padding
                .frame(height: 50) // Match CustomTextField height
                .background(
                    RoundedRectangle(cornerRadius: style == .standard ? 16 : 12)
                        .fill(style == .standard ? 
                              Color(UIColor(red: 21/255, green: 17/255, blue: 50/255, alpha: 0.7)) : // Match CustomTextField background
                              Color.white.opacity(0.08)) // Original background
                        .overlay(
                            RoundedRectangle(cornerRadius: style == .standard ? 16 : 12)
                                .stroke(
                                    style == .standard ?
                                    LinearGradient( // Use LinearGradient for both cases
                                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) : 
                                    LinearGradient( // Original gradient border
                                        colors: [AppColors.accent.opacity(0.5), AppColors.accentSecondary.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())
        }
        .fullScreenCover(isPresented: $showingDatePicker) {
            ZStack {
                // Background that matches the app theme
                BackgroundView()
                
                // Our custom styled date picker
                StyledDatePicker(
                    selectedDate: $selection,
                    isShowingPicker: $showingDatePicker,
                    onSave: {
                        // Nothing extra needed here, binding handles the update
                    }
                )
                .transition(.opacity)
                .animation(.easeInOut, value: showingDatePicker)
            }
        }
    }
} 