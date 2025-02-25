import Foundation
import GoogleAPIClientForREST_Calendar
import GoogleSignIn
import FirebaseAuth

actor GoogleCalendarAuth: GoogleCalendarAuthProtocol {
    private var service: GTLRCalendarService?
    private var currentUser: GIDGoogleUser?
    private let tokenRefreshBuffer: TimeInterval = 5 * 60 // 5 minutes buffer
    
    var isAuthorized: Bool {
        currentUser != nil
    }
    
    var userEmail: String? {
        currentUser?.profile?.email
    }
    
    init(service: GTLRCalendarService?) {
        self.service = service
    }
    
    func setup() async throws {
        print("🔄 Setting up Google Calendar Auth...")
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "558448152377-448mdad95e743dnankqcrevjs1oruf8g.apps.googleusercontent.com")
        
        do {
            print("🔄 Attempting to restore previous sign-in...")
            let signInResult = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            currentUser = signInResult
            service?.authorizer = signInResult.fetcherAuthorizer
            print("✅ Successfully restored previous sign-in for user: \(signInResult.profile?.email ?? "unknown")")
            
            // Immediately refresh token if needed
            try await refreshAuthorization()
        } catch {
            print("⚠️ Failed to restore previous sign-in: \(error)")
            currentUser = nil
            service?.authorizer = nil
            throw error
        }
    }
    
    func requestAccess(from viewController: UIViewController) async throws {
        print("🔄 Requesting Google Calendar access...")
        
        // Use the viewController directly since we'll ensure this runs on the main thread
        // Use a different approach to ensure we're on the main thread
        let result: GIDSignInResult = try await nonisolatedSignIn(presentingViewController: viewController)
        
        print("✅ Successfully signed in user: \(result.user.profile?.email ?? "unknown")")
        currentUser = result.user
        service?.authorizer = result.user.fetcherAuthorizer
    }
    
    // Nonisolated helper method that ensures sign-in happens on the main thread
    private nonisolated func nonisolatedSignIn(presentingViewController: UIViewController) async throws -> GIDSignInResult {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    let result = try await GIDSignIn.sharedInstance.signIn(
                        withPresenting: presentingViewController,
                        hint: nil,
                        additionalScopes: [
                            "https://www.googleapis.com/auth/calendar",
                            "https://www.googleapis.com/auth/calendar.events",
                            "https://www.googleapis.com/auth/calendar.readonly"
                        ]
                    )
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func signOut() async {
        print("🔄 Signing out Google Calendar user...")
        GIDSignIn.sharedInstance.signOut()
        currentUser = nil
        service?.authorizer = nil
        print("✅ Successfully signed out")
    }
    
    func refreshAuthorization() async throws {
        guard let user = currentUser else {
            print("❌ No current user found during token refresh")
            throw CalendarError.unauthorized
        }
        
        guard let expirationDate = user.accessToken.expirationDate else {
            print("❌ No token expiration date found")
            throw CalendarError.unauthorized
        }
        
        // Refresh if we're within the buffer period of expiration
        if expirationDate.timeIntervalSinceNow <= tokenRefreshBuffer {
            print("🔄 Token needs refresh, current expiration: \(expirationDate)")
            do {
                try await user.refreshTokensIfNeeded()
                service?.authorizer = user.fetcherAuthorizer
                print("✅ Successfully refreshed tokens")
            } catch {
                print("❌ Failed to refresh tokens: \(error)")
                // If refresh fails, try to restore previous sign-in
                try await setup()
            }
        } else {
            print("✅ Token is still valid until: \(expirationDate)")
        }
    }
    
    func handleURL(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
} 