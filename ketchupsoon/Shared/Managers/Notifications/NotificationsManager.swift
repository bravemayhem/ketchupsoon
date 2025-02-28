import UserNotifications
import SwiftUI
// import FirebaseMessaging  // Temporarily commented out for testing

@MainActor
class NotificationsManager: ObservableObject {
    static let shared = NotificationsManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    // @Published var fcmToken: String?  // Temporarily commented out for testing
    @AppStorage("catchUpNotificationsEnabled") private var catchUpNotificationsEnabled = true
    
    private init() {
        Task {
            await updateAuthorizationStatus()
            // setupTokenMonitoring()  // Temporarily commented out for testing
        }
    }
    
    private func updateAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        self.authorizationStatus = await center.notificationSettings().authorizationStatus
    }
    
    /* Temporarily commented out for testing
    private func setupTokenMonitoring() {
        // Add observer for FCM token updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleFCMTokenNotification(_:)),
            name: Notification.Name("FCMToken"),
            object: nil
        )
        
        // Try to get current token
        if let token = Messaging.messaging().fcmToken {
            self.fcmToken = token
        }
    }
    
    @objc private func handleFCMTokenNotification(_ notification: Foundation.Notification) {
        if let token = notification.userInfo?["token"] as? String {
            self.fcmToken = token
            
            // Here you would typically send this token to your backend
            saveTokenToBackend(token: token)
        }
    }
    
    private func saveTokenToBackend(token: String) {
        // Implementation to send the FCM token to your backend server
        guard let url = URL(string: "https://api.ketchupsoon.com/users/register-device") else {
            print("Invalid API URL")
            return
        }
        
        // Get the user identifier if logged in
        let userId = AuthManager.shared.currentUser?.uid ?? "anonymous"
        
        // Prepare request body with token and user info
        let requestBody: [String: Any] = [
            "token": token,
            "userId": userId,
            "deviceType": "ios",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]
        
        // Convert body to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to serialize request body")
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Send the request without auth header for now
        // We can add auth header later when needed
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending FCM token to backend: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response from server")
                return
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                print("FCM token successfully registered with backend")
            } else {
                print("Failed to register FCM token with backend: HTTP \(httpResponse.statusCode)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
            }
        }
        
        task.resume()
    }
    */
    
    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .provisional]
        
        do {
            let granted = try await center.requestAuthorization(options: options)
            print("🔔 Notification authorization request result: \(granted ? "granted" : "denied")")
            
            // Always update status after request
            await updateAuthorizationStatus()
            print("🔔 Updated authorization status: \(authorizationStatus.rawValue)")
            
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("🔔 Registered for remote notifications")
                }
            }
        } catch {
            print("🔔 Error requesting notification authorization: \(error)")
            // Still update status even after error
            await updateAuthorizationStatus()
            throw error
        }
    }
    
    // Add a debug method to manually refresh status
    func refreshAuthorizationStatus() async {
        await updateAuthorizationStatus()
        print("🔔 Manually refreshed authorization status: \(authorizationStatus.rawValue)")
    }
    
    /* Temporarily commented out for testing
    // MARK: - Firebase Topics

    func subscribeToTopic(_ topic: String) {
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
                print("Error subscribing to \(topic): \(error)")
            } else {
                print("Subscribed to \(topic) successfully")
            }
        }
    }
    
    func unsubscribeFromTopic(_ topic: String) {
        Messaging.messaging().unsubscribe(fromTopic: topic) { error in
            if let error = error {
                print("Error unsubscribing from \(topic): \(error)")
            } else {
                print("Unsubscribed from \(topic) successfully")
            }
        }
    }
    */
    
    // MARK: - Local Notifications
    
    func scheduleHangoutReminder(for friend: String, date: Date, minutesBefore: Int = 60) async throws {
        let center = UNUserNotificationCenter.current()
        
        // Create unique identifier for this notification
        let identifier = "hangout-\(friend)-\(date.timeIntervalSince1970)"
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Hangout"
        content.body = "You have a hangout with \(friend) in \(minutesBefore) minutes"
        content.sound = .default
        
        // Create trigger (subtracting minutesBefore from the hangout date)
        let triggerDate = date.addingTimeInterval(-Double(minutesBefore * 60))
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        try await center.add(request)
    }
    
    func scheduleCatchUpReminder(for friend: String, frequency: CatchUpFrequency, lastContact: Date) async throws {
        guard catchUpNotificationsEnabled else { return }
        let center = UNUserNotificationCenter.current()
        
        // Cancel any existing catch-up reminders for this friend
        await cancelCatchUpReminder(for: friend)
        
        // Calculate next reminder date based on frequency and last contact
        let nextReminderDate = Calendar.current.date(byAdding: .day, value: frequency.days, to: lastContact) ?? Date()
        
        // Only schedule if the next reminder is in the future
        guard nextReminderDate > Date() else { return }
        
        // Create unique identifier for this notification
        let identifier = "catchup-\(friend)"
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Catch Up!"
        content.body = "It's been a while since you connected with \(friend). Why not reach out?"
        content.sound = .default
        
        // Set the notification to trigger at 10 AM on the target date
        var components = Calendar.current.dateComponents([.year, .month, .day], from: nextReminderDate)
        components.hour = 10
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        try await center.add(request)
    }
    
    func cancelCatchUpReminder(for friend: String) async {
        let center = UNUserNotificationCenter.current()
        let identifier = "catchup-\(friend)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelHangoutReminder(for friend: String, date: Date) async {
        let center = UNUserNotificationCenter.current()
        let identifier = "hangout-\(friend)-\(date.timeIntervalSince1970)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }
    
    func toggleCatchUpNotifications(_ enabled: Bool) {
        catchUpNotificationsEnabled = enabled
        if !enabled {
            Task {
                await cancelAllCatchUpNotifications()
            }
        }
    }
    
    private func cancelAllCatchUpNotifications() async {
        let center = UNUserNotificationCenter.current()
        let notifications = await center.pendingNotificationRequests()
        let catchUpIdentifiers = notifications
            .filter { $0.identifier.starts(with: "catchup-") }
            .map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: catchUpIdentifiers)
    }
    
    // MARK: - Testing Functions
    
    func sendTestNotification(for frequency: CatchUpFrequency, title: String = "🔔 Test Notification", customMessage: String? = nil) async throws {
        let center = UNUserNotificationCenter.current()
        
        // Check authorization status
        let settings = await center.notificationSettings()
        
        // Verify the authorization status
        guard (settings.authorizationStatus == .authorized) ||
              (settings.authorizationStatus == .provisional) else {
            throw NSError(
                domain: "NotificationsManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Notifications are not authorized. Please enable notifications in Settings."]
            )
        }
        
        // Create unique identifier for this test notification
        let identifier = "test-notification-\(UUID().uuidString)"
        
        // Create notification content based on allowed settings
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = customMessage ?? "This is a test notification for \(frequency.displayText) frequency"
        
        // Only add sound if it's enabled
        if settings.soundSetting == .enabled {
            content.sound = .default
        }
        
        // Only add badge if it's enabled
        if settings.badgeSetting == .enabled {
            content.badge = 1
        }
        
        // For immediate notifications, use a time interval trigger with 1 second delay
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            // Schedule notification
            try await center.add(request)
            print("Successfully scheduled test notification with ID: \(identifier)")
            print("🔔🔔 LOCAL NOTIFICATION SENT (No Firebase required!)")
            
            // Print detailed notification settings for debugging
            print("""
                Notification Settings:
                - Authorization Status: \(settings.authorizationStatus)
                - Alert Setting: \(settings.alertSetting)
                - Sound Setting: \(settings.soundSetting)
                - Badge Setting: \(settings.badgeSetting)
                - Notification Center Setting: \(settings.notificationCenterSetting)
                - Lock Screen Setting: \(settings.lockScreenSetting)
                - Announcement Setting: \(settings.announcementSetting)
                """)
        } catch {
            print("Failed to schedule test notification: \(error)")
            throw error
        }
    }
    
    // MARK: - Debug Helpers
    
    // Add this function to help debug what notifications are pending
    func listPendingNotifications() async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        
        if requests.isEmpty {
            print("No pending notifications")
        } else {
            print("📋 PENDING NOTIFICATIONS (\(requests.count)):")
            for (index, request) in requests.enumerated() {
                print("  \(index + 1). ID: \(request.identifier)")
                print("     Title: \(request.content.title)")
                print("     Body: \(request.content.body)")
                if let date = (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() {
                    print("     Trigger date: \(date)")
                } else if let interval = (request.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval {
                    print("     Trigger interval: \(interval) seconds")
                }
                print("")
            }
        }
    }
} 



