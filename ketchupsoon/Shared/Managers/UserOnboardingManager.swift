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
        checkOnboardingStatus()
        
        // Listen for auth state changes to update onboarding state
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        // Set up auth state listener to update onboarding state when auth changes
        logger.debug("🔄 DEBUG: Setting up auth state listener")
        let _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let userId = user?.uid {
                    self?.logger.debug("🔄 DEBUG: Auth state changed, user ID: \(userId)")
                } else {
                    self?.logger.debug("🔄 DEBUG: Auth state changed, user signed out")
                }
                self?.checkOnboardingStatus()
            }
        }
    }
    
    private func checkOnboardingStatus() {
        // Only show onboarding if user is authenticated but hasn't completed onboarding
        let isAuthenticated = Auth.auth().currentUser != nil
        let previousOnboardingStatus = self.isShowingOnboarding
        
        // Only change isShowingOnboarding if we're not already in the onboarding process
        if !self.isCurrentlyOnboarding {
            // If authenticated and onboarding is not complete, show onboarding
            self.isShowingOnboarding = isAuthenticated && !hasCompletedOnboarding
            logger.debug("🔍 DEBUG: Setting isShowingOnboarding to \(self.isShowingOnboarding)")
        } else {
            // If we're already in the onboarding process, don't change isShowingOnboarding
            // This prevents the onboarding flow from being interrupted
            logger.debug("🔍 DEBUG: Already in onboarding process, not changing isShowingOnboarding")
            
            // Ensure that if we're currently onboarding, isShowingOnboarding is true
            // This prevents the app from showing HomeView during onboarding
            if isAuthenticated && !hasCompletedOnboarding && !self.isShowingOnboarding {
                logger.debug("🔍 DEBUG: Forcing isShowingOnboarding to true because user is in onboarding process")
                self.isShowingOnboarding = true
            }
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
            // If critical fields are missing, log a warning but continue (for now)
            logger.warning("⚠️ WARNING: Completing onboarding with incomplete profile - Name: \(hasName), Phone: \(hasPhone)")
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
        if let userId = Auth.auth().currentUser?.uid {
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
        if Auth.auth().currentUser != nil {
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
        if Auth.auth().currentUser != nil {
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
