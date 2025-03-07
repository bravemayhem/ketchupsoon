import SwiftUI

struct KetchupSoonOnboardingView: View {
    @StateObject private var viewModel = KetchupSoonOnboardingViewModel()
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var userProfileManager = UserProfileManager.shared
    
    var body: some View {
        ZStack {
            // Background
            BackgroundView()
            
            VStack(spacing: 0) {
                // Status bar and header
                StatusBarView(currentStep: $viewModel.currentStep)
                
                // Main content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeScreen()
                        .tag(0)
                        .environmentObject(viewModel)
                    
                    BasicInfoScreen()
                        .tag(1)
                        .environmentObject(viewModel)
                    
                    AvatarScreen()
                        .tag(2)
                        .environmentObject(viewModel)
                    
                    SuccessScreen()
                        .tag(3)
                        .environmentObject(viewModel)
                        .environmentObject(onboardingManager)
                    
                    PermissionsScreen()
                        .tag(4)
                        .environmentObject(viewModel)
                        .environmentObject(onboardingManager)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark) // Force dark mode for this view
        .ignoresSafeArea(edges: .top) // For the status bar
        .onAppear {
            // Pre-populate with any existing data
            if let name = userSettings.name {
                viewModel.profileData.name = name
            }
            
            if let email = userSettings.email {
                viewModel.profileData.email = email
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    
                    if abs(horizontalAmount) > abs(verticalAmount) {
                        if horizontalAmount < 0 {
                            viewModel.nextStep()
                        } else {
                            viewModel.previousStep()
                        }
                    }
                }
        )
    }
} 