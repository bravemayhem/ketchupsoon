import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var notificationsManager = NotificationsManager.shared
    @AppStorage("defaultReminderTime") private var defaultReminderTime: Int = 60 // minutes
    @AppStorage("catchUpNotificationsEnabled") private var catchUpNotificationsEnabled = true
    @State private var customNotificationMessage: String = ""
    @State private var customNotificationTitle: String = "🔔 Test Notification"
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showingDebugInfo: Bool = false
    
    private let reminderTimeOptions = [15, 30, 60, 120, 240] // minutes
    
    var body: some View {
        Form {
            if notificationsManager.authorizationStatus == .authorized {
                notificationSettingsSection
                testNotificationSection
                clearNotificationsSection
            } else {
                permissionRequestSection
            }
            
            // Add debug section
            Section("Debug Information") {
                Button("Show Notification Status") {
                    Task {
                        // Force refresh the authorization status
                        await notificationsManager.refreshAuthorizationStatus()
                        
                        await MainActor.run {
                            showingDebugInfo = true
                        }
                        
                        // Log current status to console
                        let status = notificationsManager.authorizationStatus
                        let statusString: String
                        switch status {
                        case .notDetermined: statusString = "notDetermined"
                        case .denied: statusString = "denied"
                        case .authorized: statusString = "authorized"
                        case .provisional: statusString = "provisional"
                        case .ephemeral: statusString = "ephemeral"
                        @unknown default: statusString = "unknown (\(status.rawValue))"
                        }
                        print("🔔 Current notification status: \(statusString)")
                        
                        // Also print the FCM token
                        /* FCM token display temporarily commented out for testing
                        if let token = notificationsManager.fcmToken {
                            print("🔔 FCM Token: \(token)")
                        } else {
                            print("🔔 FCM Token: Not available")
                        }
                        */
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                
                Button("List Pending Notifications") {
                    Task {
                        await notificationsManager.listPendingNotifications()
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Notifications")
        .alert("Notification Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Notification Status", isPresented: $showingDebugInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            // Get status string outside of view builder
            let statusText = {
                let status = notificationsManager.authorizationStatus
                let statusString: String
                switch status {
                case .notDetermined: statusString = "Not Determined"
                case .denied: statusString = "Denied"
                case .authorized: statusString = "Authorized"
                case .provisional: statusString = "Provisional"
                case .ephemeral: statusString = "Ephemeral"
                @unknown default: statusString = "Unknown"
                }
                return "Current status: \(statusString)"
            }()
            
            Text(statusText)
        }
    }
    
    private var permissionRequestSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("Push Notifications", systemImage: "bell.badge")
                    .font(.headline)
                
                Divider()
                
                Text("NOTIFICATION SETTINGS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Enable push notifications to receive reminders about upcoming hangouts.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    requestNotificationPermission()
                }) {
                    Text("Enable Push Notifications")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
                
                switch notificationsManager.authorizationStatus {
                case .denied:
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                    .padding(.top, 4)
                default:
                    EmptyView()
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // Improved permission request function
    private func requestNotificationPermission() {
        print("🔔 Request button tapped, current status: \(notificationsManager.authorizationStatus.rawValue)")
        
        Task {
            do {
                switch notificationsManager.authorizationStatus {
                case .notDetermined:
                    // First time request
                    print("🔔 Requesting permissions for first time...")
                    try await notificationsManager.requestAuthorization()
                    print("🔔 Permission request completed, new status: \(notificationsManager.authorizationStatus.rawValue)")
                    
                case .denied:
                    // User previously denied, direct to settings
                    print("🔔 Status is denied, opening settings...")
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        await MainActor.run {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                default:
                    // Try requesting again (though it likely won't show a dialog)
                    print("🔔 Status is \(notificationsManager.authorizationStatus.rawValue), attempting request...")
                    try await notificationsManager.requestAuthorization()
                    print("🔔 Permission request completed, new status: \(notificationsManager.authorizationStatus.rawValue)")
                }
            } catch {
                print("🔔 Error requesting notification permission: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    private var notificationSettingsSection: some View {
        Section {
            catchUpSection
            hangoutSection
        } header: {
            Text("NOTIFICATION SETTINGS")
        } footer: {
            Text("Enable push notifications to receive reminders about upcoming hangouts.")
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