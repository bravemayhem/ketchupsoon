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
                    
                    // Birthday field
                    CustomTextField(
                        title: "birthday",
                        placeholder: "july 14, 1992 🎂",
                        text: $viewModel.profileData.birthday
                    )
                    
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