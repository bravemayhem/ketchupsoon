import SwiftUI
import FirebaseAuth
import OSLog

@MainActor
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("useUserOnboarding") var useUserOnboarding = true
    @Published var isShowingOnboarding = false
    @Published var isOnboardingComplete = false
    
    // Add flag to track if we're already in the onboarding process
    @Published var isCurrentlyOnboarding = false
    
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "OnboardingManager")
    
    private init() {
        // Check if onboarding needs to be shown, but only if we are authenticated
        logger.debug("🔍 DEBUG: Initializing OnboardingManager")
        
        // Subscribe to AuthStateService instead of creating a direct listener
        AuthStateService.shared.subscribe(self)
        
        // Initial check
        checkOnboardingStatus()
    }
    
    // MARK: - Onboarding Status Management
    
    private func checkOnboardingStatus() {
        // Only show onboarding if user is authenticated but hasn't completed onboarding
        let isAuthenticated = AuthStateService.shared.currentState.isAuthenticated
        let previousOnboardingStatus = self.isShowingOnboarding
        
        // Only change isShowingOnboarding if we're not already in the onboarding process
        if !self.isCurrentlyOnboarding {
            // If authenticated and onboarding is not complete, show onboarding
            self.isShowingOnboarding = isAuthenticated && !hasCompletedOnboarding
            logger.debug("🔍 DEBUG: Setting isShowingOnboarding to \(self.isShowingOnboarding)")
        } else {
            // If we're already in the onboarding process, don't change isShowingOnboarding at all
            // This prevents the onboarding flow from being interrupted or restarted
            logger.debug("🔍 DEBUG: Already in onboarding process, not changing isShowingOnboarding")
        }
        
        self.isOnboardingComplete = hasCompletedOnboarding
        
        logger.debug("🔍 DEBUG: Checking onboarding status")
        logger.debug("🔍 DEBUG: isAuthenticated: \(isAuthenticated)")
        logger.debug("🔍 DEBUG: hasCompletedOnboarding: \(self.hasCompletedOnboarding)")
        logger.debug("🔍 DEBUG: isShowingOnboarding: \(self.isShowingOnboarding)")
        logger.debug("🔍 DEBUG: isCurrentlyOnboarding: \(self.isCurrentlyOnboarding)")
        
        if previousOnboardingStatus != self.isShowingOnboarding {
            logger.debug("🔄 DEBUG: Onboarding display status changed: \(self.isShowingOnboarding)")
        }
    }
    
    // Add method to set the current onboarding state
    func setCurrentlyOnboarding(_ isOnboarding: Bool) {
        logger.debug("🔍 DEBUG: Setting isCurrentlyOnboarding to \(isOnboarding)")
        isCurrentlyOnboarding = isOnboarding
    }
    
    func completeOnboarding() {
        logger.debug("✅ DEBUG: Marking onboarding as complete")
        logger.debug("✅ DEBUG: Previous state - hasCompletedOnboarding: \(self.hasCompletedOnboarding)")
        
        // Before marking onboarding as complete, verify that critical user profile fields exist
        let userSettings = UserSettings.shared
        let hasName = userSettings.name != nil && !userSettings.name!.isEmpty
        let hasPhone = userSettings.phoneNumber != nil && !userSettings.phoneNumber!.isEmpty
        
        if !hasName || !hasPhone {
            // Don't complete onboarding if critical fields are missing
            logger.warning("⚠️ WARNING: Cannot complete onboarding with incomplete profile - Name: \(hasName), Phone: \(hasPhone)")
            logger.warning("⚠️ WARNING: Onboarding will not be marked as complete until all required fields are provided")
            return // Exit without marking onboarding complete
        }
        
        hasCompletedOnboarding = true
        isOnboardingComplete = true
        isShowingOnboarding = false
        isCurrentlyOnboarding = false
        
        logger.debug("✅ DEBUG: New state - hasCompletedOnboarding: \(self.hasCompletedOnboarding)")
        logger.debug("✅ DEBUG: New state - isOnboardingComplete: \(self.isOnboardingComplete)")
        logger.debug("✅ DEBUG: New state - isShowingOnboarding: \(self.isShowingOnboarding)")
        
        // Also update UserDefaults directly as a backup
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        logger.debug("✅ DEBUG: Updated UserDefaults: onboardingComplete = true")
        
        // Check user settings
        if let userId = AuthStateService.shared.currentState.userID {
            logger.debug("🔍 DEBUG: Checking UserSettings for user \(userId)")
            logger.debug("🔍 DEBUG: UserSettings.name: \(UserSettings.shared.name ?? "nil")")
            logger.debug("🔍 DEBUG: UserSettings.email: \(UserSettings.shared.email ?? "nil")")
            logger.debug("🔍 DEBUG: UserSettings.phoneNumber: \(UserSettings.shared.phoneNumber ?? "nil")")
        }
    }
    
    func resetOnboarding() {
        logger.debug("🔄 DEBUG: Resetting onboarding status")
        hasCompletedOnboarding = false
        isOnboardingComplete = false
        
        // Only show onboarding if user is authenticated
        if AuthStateService.shared.currentState.isAuthenticated {
            isShowingOnboarding = true
        }
    }
    
    // Enhanced method that handles both internal state and app-level UserDefaults
    func resetOnboardingAndNavigateToOnboarding() {
        logger.debug("🔄 DEBUG: Resetting onboarding and navigating to onboarding flow")
        // Reset internal OnboardingManager state
        resetOnboarding()
        
        // Update the UserDefaults value that the app uses to determine whether to show onboarding
        UserDefaults.standard.set(false, forKey: "onboardingComplete")
        logger.debug("🔄 DEBUG: Updated UserDefaults: onboardingComplete = false")
        
        // Ensure isShowingOnboarding is set to true only if authenticated
        if AuthStateService.shared.currentState.isAuthenticated {
            isShowingOnboarding = true
            logger.debug("🔄 DEBUG: Set isShowingOnboarding = true (user is authenticated)")
        } else {
            logger.debug("🔄 DEBUG: User not authenticated, not showing onboarding yet")
        }
        
        // Optional: Post notification that onboarding has been reset
        NotificationCenter.default.post(name: Notification.Name("onboardingReset"), object: nil)
        logger.debug("🔄 DEBUG: Posted onboardingReset notification")
        
        // Force UI update by setting objectWillChange
        self.objectWillChange.send()
    }
}

// MARK: - AuthStateSubscriber Implementation
extension OnboardingManager: AuthStateSubscriber {
    nonisolated func onAuthStateChanged(newState: AuthState, previousState: AuthState?) {
        // Handle auth state changes
        // Since this method is now nonisolated, we need to dispatch to the main actor for UI updates
        Task { @MainActor in
            logger.debug("🔄 DEBUG: Auth state changed via AuthStateService: \(newState.description)")
            
            // Update onboarding status based on new auth state
            checkOnboardingStatus()
        }
    }
} 
