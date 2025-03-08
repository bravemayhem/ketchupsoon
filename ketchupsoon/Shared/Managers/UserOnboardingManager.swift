import SwiftUI

@MainActor
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("useUserOnboarding") var useUserOnboarding = true
    @Published var isShowingOnboarding = false
    
    private init() {
        // Check if onboarding needs to be shown
        isShowingOnboarding = !hasCompletedOnboarding
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        isShowingOnboarding = false
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        isShowingOnboarding = true
    }
} 
