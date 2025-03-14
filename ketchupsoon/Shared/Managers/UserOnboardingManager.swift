import SwiftUI
import FirebaseAuth

@MainActor
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("useUserOnboarding") var useUserOnboarding = true
    @Published var isShowingOnboarding = false
    @Published var isOnboardingComplete = false
    
    private init() {
        // Check if onboarding needs to be shown, but only if we are authenticated
        checkOnboardingStatus()
        
        // Listen for auth state changes to update onboarding state
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        // Set up auth state listener to update onboarding state when auth changes
        let _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.checkOnboardingStatus()
            }
        }
    }
    
    private func checkOnboardingStatus() {
        // Only show onboarding if user is authenticated but hasn't completed onboarding
        let isAuthenticated = Auth.auth().currentUser != nil
        isShowingOnboarding = isAuthenticated && !hasCompletedOnboarding
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
        
        // Only show onboarding if user is authenticated
        if Auth.auth().currentUser != nil {
            isShowingOnboarding = true
        }
    }
    
    // Enhanced method that handles both internal state and app-level UserDefaults
    func resetOnboardingAndNavigateToOnboarding() {
        // Reset internal OnboardingManager state
        resetOnboarding()
        
        // Update the UserDefaults value that the app uses to determine whether to show onboarding
        UserDefaults.standard.set(false, forKey: "onboardingComplete")
        
        // Ensure isShowingOnboarding is set to true only if authenticated
        if Auth.auth().currentUser != nil {
            isShowingOnboarding = true
        }
        
        // Optional: Post notification that onboarding has been reset
        NotificationCenter.default.post(name: Notification.Name("onboardingReset"), object: nil)
        
        // Force UI update by setting objectWillChange
        self.objectWillChange.send()
    }
} 
