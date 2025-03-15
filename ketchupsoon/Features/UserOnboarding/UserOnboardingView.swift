import SwiftUI
import FirebaseAuth
import SwiftData

struct UserOnboardingView: View {
    @StateObject private var viewModel: UserOnboardingViewModel
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var userProfileManager = UserProfileManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var allowDismissal = false
    
    // Add a closure to handle dismissal
    var dismissAction: (() -> Void)?
    
    init(container: ModelContainer, dismissAction: (() -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: UserOnboardingViewModel(container: container))
        self.dismissAction = dismissAction
    }
    
    // Add a function to handle dismissal
    func dismissView() {
        if let customDismiss = dismissAction {
            customDismiss()
        } else {
            dismiss()
        }
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
                    WelcomeScreen(allowDismissal: $allowDismissal, dismissAction: dismissView)
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
        .interactiveDismissDisabled(!allowDismissal && viewModel.currentStep < 4) // Prevent dismissal until completion or explicitly allowed
        .onAppear {
            // Tell the OnboardingManager we're in the onboarding process
            onboardingManager.setCurrentlyOnboarding(true)
            
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
        .onDisappear {
            // Only mark onboarding as not in progress if we've reached at least the success screen (step 4)
            // This prevents premature termination of the onboarding flow
            if viewModel.currentStep >= 4 {
                // Tell the OnboardingManager we're no longer in the onboarding process
                onboardingManager.setCurrentlyOnboarding(false)
            }
        }
        .onChange(of: viewModel.currentStep) { oldValue, newValue in
            // Only allow dismissal when reaching the final step or when explicitly set
            allowDismissal = (newValue >= 4)
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
