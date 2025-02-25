import Foundation
import FirebaseAuth
import SwiftUI
import GoogleSignIn
import FirebaseCore

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var googleUser: GIDGoogleUser?
    
    // Store the auth state listener handle
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Set up Firebase Auth listener
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            Task { @MainActor in
                self.currentUser = user
                self.isAuthenticated = user != nil
            }
        }
        
        // Try to restore previous Google Sign-in
        Task {
            try? await restoreGoogleSignIn()
        }
    }
    
    deinit {
        // Remove auth state listener when this instance is deallocated
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Configuration Verification
    
    func verifyFirebaseConfiguration() -> [String: String] {
        guard let app = FirebaseApp.app() else {
            return ["error": "Firebase app not initialized"]
        }
        
        let options = app.options
        
        // Return a dictionary of configuration values for verification
        // This helps confirm you're using the correct GoogleService-Info.plist
        return [
            "API Key": options.apiKey ?? "Not found",
            "Project ID": options.projectID ?? "Not found",
            "Client ID": options.clientID ?? "Not found",
            "GCM Sender ID": options.gcmSenderID,
            "Google App ID": options.googleAppID
        ]
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
                    domain: "AuthManager",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Firebase client ID not found"]
                )
            }
            
            // Create Google Sign In configuration object
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            // Start the sign in flow!
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: viewController,
                hint: nil,
                additionalScopes: [
                    "https://www.googleapis.com/auth/calendar",
                    "https://www.googleapis.com/auth/calendar.events"
                ]
            )
            
            // Store Google user for Calendar access
            self.googleUser = result.user
            
            // Get the user's ID token and access token
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(
                    domain: "AuthManager",
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
            print("Successfully signed in with Google: \(authResult.user.uid)")
            
        } catch {
            self.googleUser = nil
            errorMessage = error.localizedDescription
            print("Error signing in with Google: \(error)")
            isLoading = false
            throw error
        }
    }
    
    func restoreGoogleSignIn() async throws {
        do {
            // Try to restore previous Google Sign-in
            let result = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            
            // Store Google user
            self.googleUser = result
            
            // Check if we need to re-authenticate with Firebase
            if Auth.auth().currentUser == nil {
                guard let idToken = result.idToken?.tokenString else {
                    throw NSError(
                        domain: "AuthManager",
                        code: 3,
                        userInfo: [NSLocalizedDescriptionKey: "No ID token in restored session"]
                    )
                }
                
                // Create and use credential with Firebase
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: result.accessToken.tokenString
                )
                
                let authResult = try await Auth.auth().signIn(with: credential)
                print("Restored previous Google Sign-In session: \(authResult.user.uid)")
            }
        } catch {
            // This is not a fatal error - user may simply not have signed in before
            print("Could not restore Google Sign-in: \(error)")
            // Only throw if this is not a "No previous sign-in found" error
            if (error as NSError).code != -4 { // GIDSignInError.notFound
                throw error
            }
        }
    }
    
    func refreshGoogleToken() async throws -> String? {
        guard let user = googleUser else {
            throw NSError(
                domain: "AuthManager",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "No Google user found"]
            )
        }
        
        // Check token expiration and refresh if needed
        if (user.accessToken.expirationDate?.timeIntervalSinceNow ?? 0) <= 5 * 60 { // 5 minutes buffer
            try await user.refreshTokensIfNeeded()
            
            // After token refresh, check if we need to update Firebase credential too
            if let idToken = user.idToken?.tokenString {
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: user.accessToken.tokenString
                )
                
                try await Auth.auth().currentUser?.reauthenticate(with: credential)
                print("Refreshed Google tokens and re-authenticated with Firebase")
            }
        }
        
        return user.accessToken.tokenString
    }
    
    // MARK: - Authentication Methods
    
    func signInAnonymously() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            defer {
                isLoading = false
            }
            
            let result = try await Auth.auth().signInAnonymously()
            print("User signed in anonymously with UID: \(result.user.uid)")
        } catch {
            errorMessage = error.localizedDescription
            print("Error signing in anonymously: \(error)")
            isLoading = false
            throw error
        }
    }
    
    func signIn(withEmail email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            defer {
                isLoading = false
            }
            
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("User signed in: \(result.user.uid)")
        } catch {
            errorMessage = error.localizedDescription
            print("Error signing in: \(error)")
            isLoading = false
            throw error
        }
    }
    
    func createUser(withEmail email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            defer {
                isLoading = false
            }
            
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("User created: \(result.user.uid)")
        } catch {
            errorMessage = error.localizedDescription
            print("Error creating user: \(error)")
            isLoading = false
            throw error
        }
    }
    
    func signOut() async throws {
        do {
            // Sign out from Firebase
            try Auth.auth().signOut()
            
            // Sign out from Google
            GIDSignIn.sharedInstance.signOut()
            googleUser = nil
            
            print("User signed out from Firebase and Google")
        } catch {
            errorMessage = error.localizedDescription
            print("Error signing out: \(error)")
            throw error
        }
    }
    
    func resetPassword(forEmail email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            defer {
                isLoading = false
            }
            
            try await Auth.auth().sendPasswordReset(withEmail: email)
            print("Password reset email sent to \(email)")
        } catch {
            errorMessage = error.localizedDescription
            print("Error sending password reset: \(error)")
            isLoading = false
            throw error
        }
    }
    
    // MARK: - User Management
    
    func updateDisplayName(_ name: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user is logged in"])
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        
        try await changeRequest.commitChanges()
        print("Display name updated to: \(name)")
    }
    
    func updateEmail(_ email: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user is logged in"])
        }
        
        try await user.sendEmailVerification(beforeUpdatingEmail: email)
        print("Email verification sent to: \(email). User needs to verify before email is updated.")
    }
    
    func updatePassword(_ password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user is logged in"])
        }
        
        try await user.updatePassword(to: password)
        print("Password updated")
    }
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user is logged in"])
        }
        
        try await user.delete()
        print("User account deleted")
    }
} 