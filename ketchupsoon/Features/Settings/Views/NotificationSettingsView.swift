import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var notificationsManager = NotificationsManager.shared
    @AppStorage("defaultReminderTime") private var defaultReminderTime: Int = 60 // minutes
    @AppStorage("catchUpNotificationsEnabled") private var catchUpNotificationsEnabled = true
    @AppStorage("birthdayNotificationsEnabled") private var birthdayNotificationsEnabled = true
    @AppStorage("birthdayReminderDays") private var birthdayReminderDays: Int = 0 // days (0 = day of)
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showingDebugInfo: Bool = false
    
    private let reminderTimeOptions = [15, 30, 60, 120, 240] // minutes
    
    var body: some View {
        Form {
            if notificationsManager.authorizationStatus == .authorized || notificationsManager.authorizationStatus == .provisional {
                // Catch-up reminders section
                Section {
                    Toggle("Catch-up Reminders", isOn: $catchUpNotificationsEnabled)
                        .onChange(of: catchUpNotificationsEnabled) { _, newValue in
                            notificationsManager.toggleCatchUpNotifications(newValue)
                        }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(AppColors.accent)
                        Text("CATCH-UP NOTIFICATIONS")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                } footer: {
                    Text("Receive reminders when it's time to catch up with friends based on their preferred frequency.")
                }
                
                // Hangout reminders section
                Section {
                    Picker("Default Reminder Time", selection: $defaultReminderTime) {
                        ForEach(reminderTimeOptions, id: \.self) { minutes in
                            Text(formatMinutes(minutes)).tag(minutes)
                        }
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(AppColors.accent)
                        Text("HANGOUT REMINDERS")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                } footer: {
                    Text("Choose how long before a hangout you'd like to receive a reminder notification.")
                }
                
                // Birthday reminders section
                Section {
                    Toggle("Birthday Reminders", isOn: $birthdayNotificationsEnabled)
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: "gift")
                            .foregroundColor(AppColors.accent)
                        Text("BIRTHDAY REMINDERS")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                } footer: {
                    Text("Get notified on your friends' birthdays so you can wish them a happy birthday.")
                }
                
                // Clear notifications section
                Section {
                    Button(role: .destructive) {
                        Task {
                            await notificationsManager.cancelAllNotifications()
                        }
                    } label: {
                        Label("Clear All Notifications", systemImage: "bell.slash")
                    }
                }
            } else {
                permissionRequestSection
            }
            
            // Debug section (only visible during development)
            #if DEBUG
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
            #endif
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
                case .provisional: 
                    return "Current status: Provisional\n\nProvisional status means notifications are enabled but delivered quietly. This is why the button appears not to work - notifications are actually already enabled, but in provisional mode."
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
                
                Text("Enable push notifications to receive reminders about upcoming hangouts.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                
                Button(action: {
                    requestNotificationPermission()
                }) {
                    Text(notificationsManager.authorizationStatus == .provisional ? "Notifications Already Enabled" : "Enable Push Notifications")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
                .disabled(notificationsManager.authorizationStatus == .provisional)
                
                switch notificationsManager.authorizationStatus {
                case .denied:
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                    .padding(.top, 4)
                case .provisional:
                    Text("Notifications are enabled in provisional mode. You can upgrade to full notification permissions in device settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            return "\(hours) hour\(hours > 1 ? "s" : "") before"
        }
        return "\(minutes) minutes before"
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
