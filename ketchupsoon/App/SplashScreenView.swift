import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @StateObject private var onboardingManager = OnboardingManager.shared
    @EnvironmentObject private var colorSchemeManager: ColorSchemeManager
    
    var body: some View {
        if isActive {
            ContentView()
                .environmentObject(onboardingManager)
        } else {
            ZStack {
                // Background from UserOnboardingView
                BackgroundView()
                
                VStack(spacing: 12) {
                    // App name with gradient and glow effect
                    Text("ketchupsoon")
                        .font(.custom("SpaceGrotesk-Bold", size: 42))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.accent, AppColors.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: AppColors.accent.opacity(0.7), radius: 10, x: 0, y: 0)
                    
                    // Tagline
                    Text("a social app without all the noise")
                        .font(.custom("SpaceGrotesk-Regular", size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            .ignoresSafeArea() // Ignore safe areas to use entire screen
            .preferredColorScheme(.dark) // Force dark mode
            .onAppear {
                // Simulate a loading delay and then show the main content
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}
