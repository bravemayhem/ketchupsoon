import SwiftUI

struct WelcomeScreen: View {
    @EnvironmentObject var viewModel: KetchupSoonOnboardingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // App logo
            VStack(spacing: 10) {
                HStack(spacing: 0) {
                    Text("Ketchup")
                        .font(.custom("SpaceGrotesk-Bold", size: 38))
                        .foregroundColor(.white)
                    Text("Soon")
                        .font(.custom("SpaceGrotesk-Bold", size: 38))
                        .foregroundColor(Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)))
                }
                
                Text("Never lose touch with friends who matter")
                    .font(.custom("SpaceGrotesk-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 40)
            
            // Welcome card
            VStack(alignment: .leading, spacing: 16) {
                Text("Welcome to Ketchup Soon! 🌟")
                    .font(.custom("SpaceGrotesk-Bold", size: 24))
                    .foregroundColor(.white)
                
                Text("Create your profile to keep track of friends, schedule hangouts, and make sure you never forget to catch up with your social circle.")
                    .font(.custom("SpaceGrotesk-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
                
                Button {
                    viewModel.nextStep()
                } label: {
                    Text("Let's get started! 🙌")
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
            .padding(24)
            .background(Color(UIColor(red: 21/255, green: 17/255, blue: 50/255, alpha: 0.7)))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
} 