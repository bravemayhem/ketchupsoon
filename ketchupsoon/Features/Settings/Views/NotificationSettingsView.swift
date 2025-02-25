import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var notificationsManager = NotificationsManager.shared
    @AppStorage("defaultReminderTime") private var defaultReminderTime: Int = 60 // minutes
    @AppStorage("catchUpNotificationsEnabled") private var catchUpNotificationsEnabled = true
    @State private var customNotificationMessage: String = ""
    @State private var customNotificationTitle: String = "🔔 Test Notification"
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let reminderTimeOptions = [15, 30, 60, 120, 240] // minutes
    
    var body: some View {
        Form {
            authorizationSection
            
            if notificationsManager.authorizationStatus == .authorized {
                catchUpSection
                hangoutSection
                testNotificationSection
                clearNotificationsSection
            }
        }
        .navigationTitle("Notifications")
        .alert("Notification Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var authorizationSection: some View {
        Section {
            HStack {
                Label("Push Notifications", systemImage: "bell.badge")
                Spacer()
                authorizationStatusView
            }
        } header: {
            Text("NOTIFICATION SETTINGS")
        } footer: {
            Text("Enable push notifications to receive reminders about upcoming hangouts.")
        }
    }
    
    @ViewBuilder
    private var authorizationStatusView: some View {
        switch notificationsManager.authorizationStatus {
        case .authorized:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .denied:
            Button("Enable in Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .foregroundColor(AppColors.accent)
        case .notDetermined:
            Button("Enable") {
                Task {
                    try? await notificationsManager.requestAuthorization()
                }
            }
            .foregroundColor(AppColors.accent)
        default:
            EmptyView()
        }
    }
    
    private var catchUpSection: some View {
        Section {
            Toggle("Catch-up Reminders", isOn: $catchUpNotificationsEnabled)
                .onChange(of: catchUpNotificationsEnabled) { _, newValue in
                    notificationsManager.toggleCatchUpNotifications(newValue)
                }
        } header: {
            Text("CATCH-UP NOTIFICATIONS")
        } footer: {
            Text("Receive reminders when it's time to catch up with friends based on their preferred frequency.")
        }
    }
    
    private var hangoutSection: some View {
        Section {
            Picker("Default Reminder Time", selection: $defaultReminderTime) {
                ForEach(reminderTimeOptions, id: \.self) { minutes in
                    Text(formatMinutes(minutes)).tag(minutes)
                }
            }
        } header: {
            Text("HANGOUT REMINDERS")
        } footer: {
            Text("Choose how long before a hangout you'd like to receive a reminder notification.")
        }
    }
    
    private var testNotificationSection: some View {
        Section {
            TextField("Custom Title", text: $customNotificationTitle)
            TextField("Custom Message (Optional)", text: $customNotificationMessage)
            
            ForEach(CatchUpFrequency.allCases, id: \.self) { frequency in
                Button(action: {
                    Task {
                        do {
                            try await notificationsManager.sendTestNotification(
                                for: frequency,
                                title: customNotificationTitle,
                                customMessage: customNotificationMessage.isEmpty ? nil : customNotificationMessage
                            )
                            print("Test notification sent successfully for \(frequency.displayText)")
                        } catch {
                            await MainActor.run {
                                errorMessage = "Failed to send notification: \(error.localizedDescription)"
                                showingError = true
                            }
                            print("Failed to send test notification: \(error)")
                        }
                    }
                }) {
                    HStack {
                        Text("Test \(frequency.displayText) Notification")
                        Spacer()
                        Image(systemName: "bell.badge")
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
        } header: {
            Text("TEST NOTIFICATIONS")
        } footer: {
            Text("Send test notifications immediately to verify your notification settings. Customize the message if desired.")
        }
    }
    
    private var clearNotificationsSection: some View {
        Section {
            Button(role: .destructive) {
                Task {
                    await notificationsManager.cancelAllNotifications()
                }
            } label: {
                Label("Clear All Notifications", systemImage: "bell.slash")
            }
        }
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            return "\(hours) hour\(hours > 1 ? "s" : "") before"
        }
        return "\(minutes) minutes before"
    }
} 