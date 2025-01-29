import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var notificationsManager = NotificationsManager.shared
    @AppStorage("defaultReminderTime") private var defaultReminderTime: Int = 60 // minutes
    @AppStorage("catchUpNotificationsEnabled") private var catchUpNotificationsEnabled = true
    
    private let reminderTimeOptions = [15, 30, 60, 120, 240] // minutes
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Label("Push Notifications", systemImage: "bell.badge")
                    Spacer()
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
            } header: {
                Text("NOTIFICATION SETTINGS")
            } footer: {
                Text("Enable push notifications to receive reminders about upcoming hangouts.")
            }
            
            if notificationsManager.authorizationStatus == .authorized {
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
        }
        .navigationTitle("Notifications")
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            return "\(hours) hour\(hours > 1 ? "s" : "") before"
        }
        return "\(minutes) minutes before"
    }
} 