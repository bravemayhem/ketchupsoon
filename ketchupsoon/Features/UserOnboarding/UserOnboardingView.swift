import SwiftUI
import FirebaseAuth
import SwiftData

struct KetchupSoonOnboardingView: View {
    @StateObject private var viewModel: KetchupSoonOnboardingViewModel
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var userProfileManager = UserProfileManager.shared
    
    init(container: ModelContainer) {
        self._viewModel = StateObject(wrappedValue: KetchupSoonOnboardingViewModel(container: container))
    }    
    
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
                    
                    // New Phone Authentication Screen
                    PhoneAuthScreen()
                        .tag(1)
                        .environmentObject(viewModel)
                    
                    BasicInfoScreen()
                        .tag(2)
                        .environmentObject(viewModel)
                    
                    AvatarScreen()
                        .tag(3)
                        .environmentObject(viewModel)
                    
                    SuccessScreen()
                        .tag(4)
                        .environmentObject(viewModel)
                        .environmentObject(onboardingManager)
                    
                    PermissionsScreen()
                        .tag(5)
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
            
            // Check if user is already authenticated
            if let currentUser = Auth.auth().currentUser {
                // User is already signed in
                viewModel.isVerified = true
                if let phoneNumber = currentUser.phoneNumber {
                    // Format and store the phone number
                    let digits = phoneNumber.filter { $0.isNumber }
                    let usDigits = digits.hasPrefix("1") ? String(digits.dropFirst()) : digits
                    viewModel.phoneNumber = String(usDigits.suffix(10))
                    viewModel.formattedPhoneNumber = viewModel.formatPhoneNumber(viewModel.phoneNumber)
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    
                    if abs(horizontalAmount) > abs(verticalAmount) {
                        if horizontalAmount < 0 {
                            // Only allow swiping forward if authenticated at the phone auth step
                            if viewModel.currentStep == 1 && !viewModel.isVerified {
                                return
                            }
                            viewModel.nextStep()
                        } else {
                            viewModel.previousStep()
                        }
                    }
                }
        )
    }
} 
