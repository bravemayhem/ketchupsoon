import SwiftUI
import FirebaseAuth

class KetchupSoonOnboardingViewModel: ObservableObject {
    // Current step in the onboarding flow
    @Published var currentStep = 0
    
    // Authentication state
    @Published var phoneNumber = ""
    @Published var formattedPhoneNumber = ""
    @Published var verificationCode = ""
    @Published var verificationID: String?
    @Published var isVerifying = false
    @Published var isVerified = false
    @Published var showVerificationView = false
    @Published var authError: Error?
    @Published var showingError = false
    
    // Image picker state
    @Published var showImagePicker = false
    @Published var sourceType: UIImagePickerController.SourceType = .camera
    
    // User profile data
    @Published var profileData = ProfileData()
    
    // Profile data structure
    struct ProfileData {
        var name: String = ""
        var birthday: Date? = nil
        var email: String = ""
        var bio: String = ""
        var avatarEmoji: String = "🌟"
        var avatarImage: UIImage? = nil
        var useImageAvatar: Bool = false
    }
    
    // Navigation methods
    func nextStep() {
        if currentStep < 5 {
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
        if step >= 0 && step <= 5 {
            withAnimation {
                currentStep = step
            }
        }
    }
    
    // MARK: - Phone Authentication
    
    // Format phone number for display
    func formatPhoneNumber(_ input: String) -> String {
        // Only keep digits
        let cleaned = input.filter { $0.isNumber }
        // Store raw digits for authentication
        phoneNumber = cleaned
        
        // Format as (XXX) XXX-XXXX
        var formatted = ""
        for (index, character) in cleaned.enumerated() {
            if index == 0 {
                formatted += "("
            }
            if index == 3 {
                formatted += ") "
            }
            if index == 6 {
                formatted += "-"
            }
            if index < 10 { // Limit to 10 digits
                formatted.append(character)
            }
        }
        return formatted
    }
    
    // Request verification code
    func requestVerificationCode() {
        // Ensure there's a valid phone number
        guard !phoneNumber.isEmpty, phoneNumber.filter({ $0.isNumber }).count == 10 else {
            self.authError = NSError(domain: "com.ketchupsoon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid 10-digit phone number"])
            self.showingError = true
            return
        }
        
        isVerifying = true
        let fullPhoneNumber = "+1\(phoneNumber)" // Assuming US numbers, add country code logic as needed
        
        // Request verification code from Firebase
        PhoneAuthProvider.provider().verifyPhoneNumber(fullPhoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
            DispatchQueue.main.async {
                self?.isVerifying = false
                
                if let error = error {
                    self?.authError = error
                    self?.showingError = true
                    return
                }
                
                // Store verification ID for later use
                self?.verificationID = verificationID
                self?.showVerificationView = true
            }
        }
    }
    
    // Verify code and sign in
    func verifyCode() {
        guard let verificationID = verificationID, !verificationCode.isEmpty else {
            self.authError = NSError(domain: "com.ketchupsoon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Please enter the verification code"])
            self.showingError = true
            return
        }
        
        isVerifying = true
        
        // Create credential
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        
        // Sign in with credential
        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
            DispatchQueue.main.async {
                self?.isVerifying = false
                
                if let error = error {
                    self?.authError = error
                    self?.showingError = true
                    return
                }
                
                // Authentication successful
                self?.isVerified = true
                self?.savePhoneNumber()
                
                // Move to next screen
                self?.nextStep()
            }
        }
    }
    
    // Save authenticated phone number to user profile
    private func savePhoneNumber() {
        // Add code to save the verified phone number to UserSettings or other user data store
        UserSettings.shared.updatePhoneNumber(phoneNumber)
    }
    
    // MARK: - Avatar Methods
    
    // Set avatar to use emoji
    func setEmojiAvatar(_ emoji: String) {
        profileData.avatarEmoji = emoji
        profileData.useImageAvatar = false
    }
    
    // Set avatar to use image
    func setImageAvatar(_ image: UIImage) {
        profileData.avatarImage = image
        profileData.useImageAvatar = true
    }
    
    // Show camera for taking photo
    func showCamera() {
        sourceType = .camera
        showImagePicker = true
    }
    
    // Show photo library for choosing image
    func showPhotoLibrary() {
        sourceType = .photoLibrary
        showImagePicker = true
    }
} 