import Foundation
import FirebaseAuth
import SwiftUI
import GoogleSignIn
import FirebaseCore

@MainActor
class SocialAuthManager: NSObject, ObservableObject {
    static let shared = SocialAuthManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var authProvider: SocialAuthProvider?
    
    // Store the auth state listener handle
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // Reference to UserProfileManager for updating profile data
    private let profileManager = UserProfileManager.shared
    
    private override init() {
        super.init()
        // Set up Firebase Auth listener
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            Task { @MainActor in
                self.currentUser = user
                self.isAuthenticated = user != nil
                
                // Determine authentication provider if user is signed in
                if let user = user {
                    self.determineAuthProvider(for: user)
                } else {
                    self.authProvider = nil
                }
            }
        }
    }
    
    deinit {
        // Remove auth state listener when this instance is deallocated
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Authentication Provider Detection
    
    private func determineAuthProvider(for user: User) {
        if user.providerData.contains(where: { $0.providerID == "google.com" }) {
            self.authProvider = .google
        } else if user.providerData.contains(where: { $0.providerID == "password" }) {
            self.authProvider = .emailPassword
        } else {
            self.authProvider = .unknown
        }
    }
    
    // MARK: - Google Authentication
    
    func signInWithGoogle(from viewController: UIViewController) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            defer {
                isLoading = false
            }
            
            // Configure Google Sign In
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw NSError(
                    domain: "SocialAuthManager",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Firebase client ID not found"]
                )
            }
            
            // Create Google Sign In configuration object
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            // Start the sign in flow! 
            // Note: Not requesting calendar scopes here as this is for social profile
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: viewController
            )
            
            // Get the user's ID token
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(
                    domain: "SocialAuthManager",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "No ID token found"]
                )
            }
            
            // Create a Firebase credential with Google ID token
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            // Sign in with Firebase using the Google credential
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // Update social profile status
            try await updateSocialProfileStatus(for: authResult.user)
            
            print("Successfully signed in with Google for social profile: \(authResult.user.uid)")
            
        } catch {
            errorMessage = error.localizedDescription
            print("Error signing in with Google for social profile: \(error)")
            isLoading = false
            throw error
        }
    }
    
    // MARK: - Email/Password Authentication
    
    func signIn(withEmail email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            defer {
                isLoading = false
            }
            
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Update social profile status
            try await updateSocialProfileStatus(for: result.user)
            
            print("User signed in for social profile: \(result.user.uid)")
        } catch {
            errorMessage = error.localizedDescription
            print("Error signing in for social profile: \(error)")
            isLoading = false
            throw error
        }
    }
    
    func createUser(withEmail email: String, password: String, name: String? = nil) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            defer {
                isLoading = false
            }
            
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Set display name if provided
            if let name = name, !name.isEmpty {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = name
                try await changeRequest.commitChanges()
            }
            
            // Update social profile status
            try await updateSocialProfileStatus(for: result.user)
            
            print("User created for social profile: \(result.user.uid)")
        } catch {
            errorMessage = error.localizedDescription
            print("Error creating user for social profile: \(error)")
            isLoading = false
            throw error
        }
    }
    
    func signOut() async throws {
        do {
            // First update profile to mark social profile as inactive
            try await profileManager.updateUserProfile(updates: [
                "isSocialProfileActive": false,
                "socialAuthProvider": NSNull()
            ])
            
            // Sign out from Firebase
            try Auth.auth().signOut()
            
            // Reset authentication provider
            authProvider = nil
            
            print("User signed out from social profile")
        } catch {
            errorMessage = error.localizedDescription
            print("Error signing out from social profile: \(error)")
            throw error
        }
    }
    
    // MARK: - Profile Management
    
    private func updateSocialProfileStatus(for user: User) async throws {
        // First determine and set the auth provider
        determineAuthProvider(for: user)
        
        // Update the user's profile to mark social profile as active
        try await profileManager.updateUserProfile(updates: [
            "isSocialProfileActive": true
        ])
        
        // Store the authentication provider information
        if let provider = authProvider?.rawValue {
            try await profileManager.updateUserProfile(updates: [
                "socialAuthProvider": provider
            ])
        }
    }
    
    // This function is no longer needed as we're handling deactivation in signOut
    // This wrapper is kept for backward compatibility
    func deactivateSocialProfile() async throws {
        // Update the user's profile to mark social profile as inactive
        try await profileManager.updateUserProfile(updates: [
            "isSocialProfileActive": false,
            "socialAuthProvider": NSNull()
        ])
    }
}

// MARK: - Supporting Types

enum SocialAuthProvider: String, Codable {
    case google = "google.com"
    case emailPassword = "password"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .google: return "Google"
        case .emailPassword: return "Email"
        case .unknown: return "Unknown Provider"
        }
    }
    
    var iconName: String {
        switch self {
        case .google: return "g.circle.fill"
        case .emailPassword: return "envelope.fill"
        case .unknown: return "questionmark.circle"
        }
    }
} 