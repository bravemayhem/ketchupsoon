# Firebase Migration Guide

## Current Setup
Currently using:
- Google Sign-In (GIDSignIn)
- GoogleAPIClientForREST_Calendar
- Direct Google Calendar API access

## Migration Steps

### 1. Add Firebase Dependencies
Add to Podfile:
```ruby
pod 'FirebaseAuth'
pod 'FirebaseFirestore'
pod 'FirebaseAnalytics'
```

Or SPM:
- Add Firebase iOS SDK through Xcode's package manager
- Select FirebaseAuth, FirebaseFirestore, and FirebaseAnalytics

### 2. Configure Firebase

#### Add GoogleService-Info.plist
1. Download from Firebase Console
2. Add to Xcode project
3. Ensure it's included in target

#### Initialize Firebase
```swift
// AppDelegate.swift
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

// If using SwiftUI
@main
struct ketchupsoonApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 3. Update CalendarManager

#### Before (Current Implementation):
```swift
class CalendarManager: ObservableObject {
    private var googleService: GTLRCalendarService?
    @Published var isGoogleAuthorized = false
    
    func requestGoogleAccess() async throws {
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: nil,
            additionalScopes: [
                "https://www.googleapis.com/auth/calendar",
                "https://www.googleapis.com/auth/calendar.events"
            ]
        )
        googleService?.authorizer = result.user.fetcherAuthorizer
    }
}
```

#### After (Firebase Implementation):
```swift
class CalendarManager: ObservableObject {
    private var googleService: GTLRCalendarService?
    @Published var isGoogleAuthorized = false
    
    private let auth = Auth.auth()
    
    func requestGoogleAccess() async throws {
        let provider = GoogleAuthProvider()
        provider.addScope("https://www.googleapis.com/auth/calendar")
        provider.addScope("https://www.googleapis.com/auth/calendar.events")
        
        let result = try await auth.signIn(with: provider)
        
        // Get OAuth token for Google Calendar
        let credential = GoogleAuthProvider.credential(
            withIDToken: try await result.user.getIDToken(),
            accessToken: result.credential?.accessToken ?? ""
        )
        
        // Configure Google Calendar service
        let config = GTMAppAuthFetcherAuthorization(
            authState: credential.authState,
            serviceProvider: "Google"
        )
        googleService?.authorizer = config
        isGoogleAuthorized = true
    }
    
    func getGoogleCalendarToken() async throws -> String {
        return try await auth.currentUser?.getIDToken() ?? ""
    }
}
```

### 4. Update Event Creation

#### Before:
```swift
func createHangoutEvent(activity: String, date: Date) async throws -> CalendarEventResult {
    guard let service = googleService else { throw CalendarError.unauthorized }
    
    let event = GTLRCalendar_Event()
    // ... event setup ...
    
    let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: "primary")
    
    return try await withCheckedThrowingContinuation { continuation in
        service.executeQuery(query) { ticket, response, error in
            // ... handle response ...
        }
    }
}
```

#### After:
```swift
func createHangoutEvent(activity: String, date: Date) async throws -> CalendarEventResult {
    guard let service = googleService else { throw CalendarError.unauthorized }
    
    // Get fresh token
    let token = try await getGoogleCalendarToken()
    service.authorizer = GTMBearerAuthorizer(token: token)
    
    let event = GTLRCalendar_Event()
    // ... event setup ...
    
    let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: "primary")
    
    return try await withCheckedThrowingContinuation { continuation in
        service.executeQuery(query) { ticket, response, error in
            // ... handle response ...
        }
    }
}
```

### 5. Update User Session Management

```swift
class UserSession: ObservableObject {
    @Published var isAuthenticated = false
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateHandler()
    }
    
    private func setupAuthStateHandler() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isAuthenticated = user != nil
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
}
```

### 6. Testing Steps

1. **Auth Flow Testing**
   - Test sign in
   - Test token refresh
   - Test sign out
   - Verify auth state persistence

2. **Calendar Integration Testing**
   - Create event
   - Update event
   - Delete event
   - Verify attendee management

3. **Error Handling Testing**
   - Network errors
   - Token expiration
   - Permission errors
   - Invalid states

### 7. Rollback Plan

Keep old implementation in place but commented out until testing is complete:
```swift
class CalendarManager {
    // New Firebase implementation
    func requestGoogleAccess() async throws {
        // ... new code ...
    }
    
    // Old implementation (commented out)
    /*
    func requestGoogleAccessLegacy() async throws {
        // ... old code ...
    }
    */
}
```

## Verification Checklist

- [ ] Firebase properly initialized
- [ ] Google Sign-In working through Firebase
- [ ] Calendar API access working
- [ ] Token refresh working
- [ ] Auth state properly persisted
- [ ] Event creation working
- [ ] Attendee management working
- [ ] Error handling tested
- [ ] Performance metrics normal 