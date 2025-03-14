import UserNotifications
import SwiftUI
// import FirebaseMessaging  // Temporarily commented out for testing

@MainActor
class NotificationsManager: ObservableObject {
    static let shared = NotificationsManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
}
