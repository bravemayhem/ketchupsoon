import SwiftUI

class KetchupSoonOnboardingViewModel: ObservableObject {
    // Current step in the onboarding flow
    @Published var currentStep = 0
    
    // User profile data
    @Published var profileData = ProfileData()
    
    // Profile data structure
    struct ProfileData {
        var name: String = ""
        var birthday: String = ""
        var email: String = ""
        var bio: String = ""
        var avatarEmoji: String = "🌟"
    }
    
    // Navigation methods
    func nextStep() {
        if currentStep < 4 {
            withAnimation {
                currentStep += 1
            }
        }
    }
    
    func previousStep() {
        if currentStep > 0 {
            withAnimation {
                currentStep -= 1
            }
        }
    }
    
    // Go to specific step
    func goToStep(_ step: Int) {
        if step >= 0 && step <= 4 {
            withAnimation {
                currentStep = step
            }
        }
    }
} 