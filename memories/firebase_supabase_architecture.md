# Firebase & Supabase Architecture

## Overview
This document outlines our hybrid architecture approach using Firebase for authentication and Google Calendar integration, with Supabase for data storage. This unified approach ensures consistency across iOS and web platforms.

## Service Distribution

### Firebase Services (Auth & Google Integration)

#### Unified Authentication
- **Google Sign-In**: Single authentication method across platforms
- **Configuration**:
  - Shared Firebase project
  - Platform-specific client IDs:
    - iOS: `144315286048-7jasampp9nttpd09rd3d31iui3j9stif.apps.googleusercontent.com`
    - Web: `144315286048-qa5q5a9179co1igkbd0rtl6rk5kf5md8.apps.googleusercontent.com`
  - Unified token management
- **OAuth Scopes**: 
  - `https://www.googleapis.com/auth/calendar.events`
  - `https://www.googleapis.com/auth/calendar`
  - `https://www.googleapis.com/auth/calendar.readonly`
- **User Management**:
  - Cross-platform user profiles
  - Synchronized authentication state
  - Automatic token refresh
  - Offline persistence

#### Required Configuration
1. **Firebase Console Setup**:
   - Enable Google Sign-In provider
   - Configure Web SDK with client credentials
   - Add support email
   - Enable Google Calendar API

2. **iOS Configuration**:
   - Add GoogleService-Info.plist
   - Configure Firebase in AppDelegate
   - Set up Google Sign-In scopes

3. **Web Configuration**:
   - Add environment variables:
     ```env
     GOOGLE_CLIENT_ID=your_web_client_id
     GOOGLE_CLIENT_SECRET=your_web_client_secret
     ```
   - Configure authorized origins and redirect URIs:
     - Development: `http://localhost:3000`
     - Production: Your production domain
   - Set up callback URLs:
     - `/auth/callback`
     - `/api/auth/callback/google`

#### Google Calendar Integration
- Event creation and management
- Calendar synchronization
- Attendee management
- Real-time calendar updates
- Event invitations
- Cross-platform calendar state sync

#### Future Expansion Possibilities
- Push Notifications
- File Storage (profile pictures)
- Analytics
- Crash Reporting
- Performance Monitoring

### Supabase Services (Primary Data Store)

#### Database Tables
1. **events**
   - Primary event data storage
   - Linked to Firebase UID
   - Google Calendar event IDs
   - Event metadata

2. **event_attendees**
   - Attendee information
   - RSVP status
   - Contact details

3. **invites**
   - Invitation tokens
   - Expiration management
   - Verification status

4. **verification_attempts**
   - Security tracking
   - Rate limiting
   - Attempt logging

#### Row Level Security (RLS)
- Firebase UID-based access control
- Event-specific permissions
- Attendee verification
- Invite token validation

## Integration Points

### Authentication Flow
1. User authenticates with Firebase (iOS or Web)
2. Firebase handles Google Sign-In and token management
3. Firebase UID used consistently across platforms
4. Supabase RLS policies validate Firebase tokens

### Event Creation Flow
1. Create event in Google Calendar using Firebase auth
2. Store event data in Supabase with:
   - Firebase UID as creator
   - Google Calendar event ID
   - Event details and metadata

### Invite System
1. Generate invite tokens in Supabase
2. Verify phone numbers using Supabase functions
3. Link verified users to Google Calendar events
4. Manage RSVPs through both systems

## Code Architecture

### iOS App
```swift
// Firebase Configuration
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

// Calendar Manager
class CalendarManager {
    private func setupGoogleCalendar() async {
        // Configure Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "your-client-id")
        
        // Check if user is already signed in
        if let signInResult = try? await GIDSignIn.sharedInstance.restorePreviousSignIn() {
            isGoogleAuthorized = true
            googleService?.authorizer = signInResult.fetcherAuthorizer
        }
    }
    
    func requestGoogleAccess() async throws {
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: nil,
            additionalScopes: [
                "https://www.googleapis.com/auth/calendar",
                "https://www.googleapis.com/auth/calendar.events"
            ]
        )
        
        // Create Firebase credential
        let credential = GoogleAuthProvider.credential(
            withIDToken: result.user.idToken?.tokenString ?? "",
            accessToken: result.user.accessToken.tokenString
        )
        
        // Sign in to Firebase
        let authResult = try await auth.signIn(with: credential)
    }
}
```

### Web App
```typescript
// Firebase Configuration
const firebaseConfig = {
  apiKey: "...",
  authDomain: "...",
  projectId: "...",
};

// Initialize Firebase
initializeApp(firebaseConfig);

// Google Calendar Integration
const getGoogleAuthToken = async () => {
  const supabase = createClientComponentClient();
  const { data: { provider_token } } = await supabase.auth.getUser();
  return provider_token;
};
```

## Security Considerations

### Firebase Security
- Unified token management across platforms
- Secure Google Calendar access
- Automatic token refresh
- Offline token persistence
- Cross-platform session management

### Supabase Security
- RLS policies based on Firebase tokens
- Phone verification system
- Rate limiting on verification attempts
- Secure invite token generation

## Testing Strategy

### Cross-Platform Testing
- Authentication flow on both platforms
- Token management and refresh
- Session persistence
- Error handling

### Calendar Testing
- Event creation on both platforms
- Cross-platform invitation flow
- RSVP handling
- Calendar sync verification

### Database Testing
- CRUD operations
- RLS policy validation
- Invite system
- Phone verification

## Monitoring & Maintenance

### Firebase Monitoring
- Cross-platform authentication rates
- Token refresh patterns
- Error tracking
- Performance metrics

### Supabase Monitoring
- Database performance
- RLS policy effectiveness
- Verification system usage
- Storage utilization

## Future Considerations

### Scalability
- Monitor Firebase quotas
- Track Supabase database usage
- Plan for data growth
- Consider caching strategies

### Feature Expansion
- Cross-platform push notifications
- Real-time updates
- File storage
- Analytics integration

### Performance Optimization
- Token caching
- Offline support
- Background sync
- Cross-platform state management 