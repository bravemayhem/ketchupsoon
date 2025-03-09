import SwiftUI

@MainActor
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("useUserOnboarding") var useUserOnboarding = true
    @Published var isShowingOnboarding = false
    @Published var isOnboardingComplete = false
    
    private init() {
        // Check if onboarding needs to be shown
        isShowingOnboarding = !hasCompletedOnboarding
        isOnboardingComplete = hasCompletedOnboarding
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        isOnboardingComplete = true
        isShowingOnboarding = false
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        isOnboardingComplete = false
        isShowingOnboarding = true
    }
} 
