import SwiftUI
import EventKit
import GoogleSignIn

struct CalendarIntegrationView: View {
    @StateObject private var calendarManager = CalendarManager()
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultCalendarType") private var defaultCalendarType: Friend.CalendarType = .apple
    
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
                                // Set default to Apple Calendar if Google is not authorized
                                if !calendarManager.isGoogleAuthorized {
                                    defaultCalendarType = .apple
                                }
                            }
                        }
                        .foregroundColor(AppColors.accent)
                    }
                }
                
                HStack {
                    Label("Google Calendar", systemImage: "calendar.badge.plus")
                    Spacer()
                    if calendarManager.isGoogleAuthorized {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Button("Sign Out") {
                                Task {
                                    await calendarManager.signOutGoogle()
                                    // Set default to Apple Calendar if it's authorized
                                    if calendarManager.isAuthorized {
                                        defaultCalendarType = .apple
                                    }
                                }
                            }
                            .foregroundColor(AppColors.accent)
                        }
                    } else {
                        Button("Sign In") {
                            Task {
                                do {
                                    try await calendarManager.requestGoogleAccess()
                                    // Set default to Google Calendar when authorized
                                    if calendarManager.isGoogleAuthorized {
                                        defaultCalendarType = .google
                                    }
                                } catch {
                                    print("Failed to sign in to Google: \(error)")
                                }
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
            
            Section {
                Picker("Default Calendar", selection: $defaultCalendarType) {
                    Text("Apple Calendar").tag(Friend.CalendarType.apple)
                    Text("Google Calendar").tag(Friend.CalendarType.google)
                }
                .pickerStyle(.menu)
                .disabled(!calendarManager.isAuthorized && !calendarManager.isGoogleAuthorized)
            } header: {
                Text("Calendar Invite Preferences")
            } footer: {
                Text("Note: Calendar invites with attendee notifications are only supported when using Google Calendar. Apple Calendar will create local events only.")
                    .foregroundColor(.secondary)
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