import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit

// MARK: - Helper Extensions
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var onboardingManager: OnboardingManager
    @EnvironmentObject private var firebaseSyncService: FirebaseSyncService
    @State private var phoneNumber = ""
    @State private var formattedPhoneNumber = ""
    @State private var verificationID: String?
    @State private var verificationCode = ""
    @State private var isVerifying = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var animateContent = false
    @State private var showCreateAccountPrompt = false
    @State private var showOnboarding = false
    
    // Debug mode state
    #if DEBUG
    @State private var showDebugOptions = false
    #endif
    
    @Environment(\.modelContext) private var modelContext
    
    var onAuthSuccess: () -> Void
    var onBackButtonTapped: () -> Void
    
    private var isPhoneValid: Bool {
        // Basic validation - requires at least 10 digits
        return phoneNumber.filter { $0.isNumber }.count >= 10
    }
    
    private var isVerificationCodeValid: Bool {
        return verificationCode.count == 6
    }
    
    // MARK: - Keyboard Dismissal
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Format phone number for display
    private func formatPhoneNumber(_ input: String) -> String {
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
    
    var body: some View {
        ZStack {
            // Background gradient
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            // Content
            ScrollView {
                VStack(spacing: 30) {
                    // Back button
                    HStack {
                        Button(action: onBackButtonTapped) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.system(size: 16, weight: .medium))
                                Text("Back")
                                    .font(.custom("SpaceGrotesk-Medium", size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        .padding(.leading, 20)
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    .opacity(animateContent ? 1 : 0)
                    
                    // App logo and branding
                    VStack(spacing: 12) {
                        Text("ketchupsoon")
                            .font(.custom("SpaceGrotesk-Bold", size: 42))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.accent, AppColors.accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: AppColors.accent.opacity(0.7), radius: 10, x: 0, y: 0)
                    }
                    .padding(.top, 20) // Reduced top padding to account for back button
                    .padding(.bottom, 20)
                    .offset(y: animateContent ? 0 : -20)
                    .opacity(animateContent ? 1 : 0)
                    
                    // DEBUG MODE BUTTON
                    #if DEBUG
                    Button(action: {
                        showDebugOptions = true
                    }) {
                        HStack {
                            Image(systemName: "ladybug.fill")
                                .foregroundColor(.white)
                            Text("Debug Options")
                                .font(.custom("SpaceGrotesk-Regular", size: 14))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(20)
                    }
                    .padding(.bottom, 10)
                    .transition(.opacity)
                    #endif
                    
                    // Form fields
                    VStack(spacing: 16) {
                        if isVerifying {
                            // Verification code input
                            customTextField(
                                text: $verificationCode,
                                placeholder: "6-digit code",
                                icon: "key.fill",
                                keyboardType: .numberPad
                            )
                            
                            Text("Enter the 6-digit code sent to \(formattedPhoneNumber)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            // Phone number input
                            AuthPhoneInputView(formattedPhoneNumber: $formattedPhoneNumber, formatFunction: formatPhoneNumber)
                        }
                    }
                    .padding(.horizontal, 30)
                    .offset(y: animateContent ? 0 : -5)
                    .opacity(animateContent ? 1 : 0)
                    
                    // Create account prompt
                    if showCreateAccountPrompt {
                        VStack(spacing: 10) {
                            Text("No account found with this phone number")
                                .font(.callout)
                                .foregroundColor(AppColors.warning)
                                .multilineTextAlignment(.center)
                            
                            Text("Please create a new account to continue")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                
                            Button(action: startOnboarding) {
                                Text("Create New Account Now")
                                    .font(.callout)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.accent)
                                    .underline()
                            }
                            .padding(.top, 5)
                        }
                        .padding(.horizontal, 30)
                        .offset(y: animateContent ? 0 : -5)
                        .opacity(animateContent ? 1 : 0)
                    }
                    
                    // Error message
                    if let errorMessage = errorMessage, showError {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(AppColors.error)
                            .padding(.horizontal, 30)
                            .transition(.opacity)
                            .offset(y: animateContent ? 0 : -5)
                            .opacity(animateContent ? 1 : 0)
                    }
                    
                    // Sign in/verify button
                    Button(action: isVerifying ? verifyCode : sendVerificationCode) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    isVerifying 
                                    ? (isVerificationCodeValid ? AppColors.accentGradient1 : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    : (isPhoneValid ? AppColors.accentGradient1 : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                )
                                .frame(height: 56)
                                .glow(color: (isVerifying ? isVerificationCodeValid : isPhoneValid) ? AppColors.accent : .clear, radius: 5)
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                            } else {
                                Text(isVerifying ? "Verify Code" : "Sign In")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled((isVerifying ? !isVerificationCodeValid : !isPhoneValid) || isLoading || showCreateAccountPrompt)
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                    .offset(y: animateContent ? 0 : -5)
                    .opacity(animateContent ? 1 : 0)
                    
                    if isVerifying {
                        Button(action: {
                            isVerifying = false
                            verificationCode = ""
                        }) {
                            Text("Change Phone Number")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                                .underline()
                        }
                        .padding(.top, 5)
                    }
                    
                    // Additional info
                    Text("By signing in, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                        .offset(y: animateContent ? 0 : -5)
                        .opacity(animateContent ? 1 : 0)
                }
                .padding()
            }
        }
        .simultaneousGesture(TapGesture().onEnded { hideKeyboard() })
        .preferredColorScheme(.dark)
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                showError = false
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        #if DEBUG
        .alert("Debug Options", isPresented: $showDebugOptions) {
            Button("Reset Onboarding State", role: .destructive) {
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                onboardingManager.resetOnboardingAndNavigateToOnboarding()
                print("DEBUG: Reset onboarding state to false")
            }
            
            Button("Clear All UserDefaults", role: .destructive) {
                let domain = Bundle.main.bundleIdentifier!
                
                // Clear UserDefaults
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
                
                // Also clear UserSettings keychain data
                UserSettings.shared.clearAll()
                
                print("DEBUG: Cleared all UserDefaults and UserSettings data")
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Debug options for testing (not visible in release builds)")
        }
        #endif
        .fullScreenCover(isPresented: $showOnboarding) {
            // Present UserOnboardingView directly
            UserOnboardingView(
                container: modelContext.container,
                dismissAction: { showOnboarding = false }
            )
                .environmentObject(onboardingManager)
                .environmentObject(firebaseSyncService)
                .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            // Animate content when view appears
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
        .onChange(of: phoneNumber) { _, _ in
            // Reset create account prompt if phone number changes
            if showCreateAccountPrompt {
                showCreateAccountPrompt = false
            }
        }
    }
    
    // MARK: - UI Components
    
    func customTextField(
        text: Binding<String>,
        placeholder: String,
        icon: String,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .never
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 24)
            
            TextField("", text: text)
                .foregroundColor(Color.white)
                .overlay(
                    ZStack(alignment: .leading) {
                        if text.wrappedValue.isEmpty {
                            Text(placeholder)
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                    }
                )
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.outline, lineWidth: 1)
        )
    }
    
    // MARK: - Authentication Methods
    
    func sendVerificationCode() {
        isLoading = true
        errorMessage = nil
        showError = false
        showCreateAccountPrompt = false
        
        // Use the raw phone number that's been populated by the formatter
        let formattedNumber = "+1" + phoneNumber
        
        Task {
            do {
                // First check if this phone number exists in your database
                let userExists = try await checkIfUserExists(phoneNumber: formattedNumber)
                
                if !userExists {
                    // Show prompt that this user doesn't exist and should create an account
                    await MainActor.run {
                        isLoading = false
                        showCreateAccountPrompt = true
                    }
                    return
                }
                
                // User exists, proceed with verification
                let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(formattedNumber, uiDelegate: nil)
                
                await MainActor.run {
                    self.verificationID = verificationID
                    isVerifying = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to verify phone number: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    func checkIfUserExists(phoneNumber: String) async throws -> Bool {
        // Query your Firestore users collection
        let querySnapshot = try await Firestore.firestore()
            .collection("users")
            .whereField("phoneNumber", isEqualTo: phoneNumber)
            .limit(to: 1)
            .getDocuments()
        
        // If we have documents, user exists
        return !querySnapshot.documents.isEmpty
    }
    
    func verifyCode() {
        guard let verificationID = verificationID else {
            errorMessage = "Missing verification ID. Please try again."
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        Task {
            do {
                let credential = PhoneAuthProvider.provider().credential(
                    withVerificationID: verificationID,
                    verificationCode: verificationCode
                )
                
                // Sign in with the credential
                try await Auth.auth().signIn(with: credential)
                
                await MainActor.run {
                    isLoading = false
                    
                    // Check if the user needs to go through onboarding
                    if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                        // This is a new user or they haven't completed onboarding
                        // Show the onboarding flow
                        startOnboarding()
                    } else {
                        // User has completed onboarding before, proceed to home
                        onAuthSuccess()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to verify code: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    func startOnboarding() {
        // Set the OnboardingManager state to indicate we're starting onboarding
        // This prevents the app from interrupting the onboarding flow
        onboardingManager.setCurrentlyOnboarding(true)
        
        // For new users, we don't want to authenticate them in AuthView
        // Instead, we immediately show the onboarding flow and let PhoneAuthScreen handle verification
        showOnboarding = true
        
        // Log that we're starting the onboarding flow for a new user
        print("DEBUG: Starting onboarding flow for new user")
    }
}

// MARK: - Phone Input Component
struct AuthPhoneInputView: View {
    @Binding var formattedPhoneNumber: String
    @FocusState private var isInputFocused: Bool
    var formatFunction: (String) -> String
    
    var body: some View {
        VStack(spacing: 16) {
            // Phone number field
            VStack(alignment: .leading, spacing: 6) {
                Text("phone number")
                    .font(.custom("SpaceGrotesk-SemiBold", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                HStack {
                    // Country code prefix
                    Text("+1")
                        .font(.custom("SpaceGrotesk-Regular", size: 16))
                        .foregroundColor(.white)
                        .padding(.leading, 4)
                    
                    Divider()
                        .frame(width: 1)
                        .background(Color.white.opacity(0.3))
                        .padding(.vertical, 4)
                    
                    // Phone number input
                    TextField("(555) 555-5555", text: $formattedPhoneNumber)
                        .font(.custom("SpaceGrotesk-Regular", size: 16))
                        .foregroundColor(.white)
                        .keyboardType(.phonePad)
                        .focused($isInputFocused)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isInputFocused = true
                            }
                        }
                        .onChange(of: formattedPhoneNumber) { _, newValue in
                            formattedPhoneNumber = formatFunction(newValue)
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isInputFocused = false
                                }
                                .font(.headline)
                                .foregroundColor(AppColors.accent)
                            }
                        }
                }
                .frame(height: 45)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Privacy info
            Text("We'll send a text with a verification code. Message and data rates may apply.")
                .font(.custom("SpaceGrotesk-Regular", size: 12))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    AuthView(onAuthSuccess: {}, onBackButtonTapped: {})
} 
