import UserNotifications
import SwiftUI

@MainActor
class NotificationsManager: ObservableObject {
    static let shared = NotificationsManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @AppStorage("catchUpNotificationsEnabled") private var catchUpNotificationsEnabled = true
    
    private init() {
        Task {
            await updateAuthorizationStatus()
        }
    }
    
    private func updateAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        self.authorizationStatus = await center.notificationSettings().authorizationStatus
    }
    
    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        do {
            let granted = try await center.requestAuthorization(options: options)
            await updateAuthorizationStatus()
            
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } catch {
            print("Error requesting notification authorization: \(error)")
            throw error
        }
    }
    
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
} 