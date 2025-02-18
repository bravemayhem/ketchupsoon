import Foundation
import GoogleAPIClientForREST_Calendar
import GoogleSignIn
import FirebaseAuth

actor GoogleCalendarAuth: GoogleCalendarAuthProtocol {
    private var service: GTLRCalendarService?
    private var currentUser: GIDGoogleUser?
    private let tokenRefreshBuffer: TimeInterval = 5 * 60 // 5 minutes buffer
    
    var isAuthorized: Bool {
        guard let expirationDate = currentUser?.accessToken.expirationDate else { return false }
        // Consider token unauthorized if it's within refresh buffer of expiration
        return expirationDate.timeIntervalSinceNow > tokenRefreshBuffer
    }
    
    var userEmail: String? {
        currentUser?.profile?.email
    }
    
    init(service: GTLRCalendarService?) {
        self.service = service
    }
    
    func setup() async {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "144315286048-7jasampp9nttpd09rd3d31iui3j9stif.apps.googleusercontent.com")
        
        do {
            let signInResult = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            currentUser = signInResult
            service?.authorizer = signInResult.fetcherAuthorizer
        } catch {
            currentUser = nil
            service?.authorizer = nil
        }
    }
    
    func requestAccess(from viewController: UIViewController) async throws {
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: viewController,
            hint: nil,
            additionalScopes: [
                "https://www.googleapis.com/auth/calendar",
                "https://www.googleapis.com/auth/calendar.events",
                "https://www.googleapis.com/auth/calendar.readonly"
            ]
        )
        
        currentUser = result.user
        service?.authorizer = result.user.fetcherAuthorizer
    }
    
    func signOut() async {
        GIDSignIn.sharedInstance.signOut()
        currentUser = nil
        service?.authorizer = nil
    }
    
    func refreshAuthorization() async throws {
        guard let user = currentUser else {
            throw CalendarError.unauthorized
        }
        
        guard let expirationDate = user.accessToken.expirationDate else {
            throw CalendarError.unauthorized
        }
        
        // Refresh if we're within the buffer period of expiration
        if expirationDate.timeIntervalSinceNow > tokenRefreshBuffer {
            return
        }
        
        try await user.refreshTokensIfNeeded()
        service?.authorizer = user.fetcherAuthorizer
    }
    
    func handleURL(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
} 