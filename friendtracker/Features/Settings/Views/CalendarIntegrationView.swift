import SwiftUI
import EventKit
import GoogleSignIn

struct CalendarIntegrationView: View {
    @StateObject private var calendarManager = CalendarManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Label("Apple Calendar", systemImage: "calendar")
                    Spacer()
                    if calendarManager.isAuthorized {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button("Connect") {
                            Task {
                                await calendarManager.requestAccess()
                            }
                        }
                        .foregroundColor(AppColors.accent)
                    }
                }
                
                HStack {
                    Label("Google Calendar", systemImage: "calendar.badge.plus")
                    Spacer()
                    if calendarManager.isGoogleAuthorized {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button("Sign In") {
                            Task {
                                try? await calendarManager.requestGoogleAccess()
                            }
                        }
                        .foregroundColor(AppColors.accent)
                    }
                }
            } header: {
                Text("Calendar Services")
            } footer: {
                Text("Connect your calendars to automatically sync your hangouts.")
            }
            
            if !calendarManager.connectedCalendars.isEmpty {
                Section {
                    ForEach(calendarManager.connectedCalendars, id: \.id) { calendar in
                        HStack {
                            Label(calendar.name, systemImage: calendar.type == .apple ? "calendar" : "calendar.badge.plus")
                                .foregroundColor(AppColors.label)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                } header: {
                    Text("Connected Calendars")
                } footer: {
                    Text("These calendars will be used for scheduling hangouts.")
                }
            }
        }
        .navigationTitle("Calendar Integration")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CalendarIntegrationView()
    }
} 