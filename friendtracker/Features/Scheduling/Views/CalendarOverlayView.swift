import SwiftUI
import EventKit
import GoogleAPIClientForREST_Calendar

struct CalendarOverlayView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var calendarManager = CalendarManager()
    @State private var selectedDate = Date()
    @State private var events: [CalendarManager.CalendarEvent] = []
    @State private var showingAuthPrompt = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                if !calendarManager.isAuthorized && !calendarManager.isGoogleAuthorized {
                    ContentUnavailableView(
                        "Calendar Access Required",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Please connect your calendars in Settings to view your schedule.")
                    )
                    .padding()
                } else {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if events.isEmpty {
                        ContentUnavailableView(
                            "No Events",
                            systemImage: "calendar",
                            description: Text("No events scheduled for this day")
                        )
                    } else {
                        List {
                            ForEach(events, id: \.event.eventIdentifier) { calendarEvent in
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(calendarEvent.event.title)
                                            .font(.headline)
                                        Spacer()
                                        Image(systemName: calendarEvent.source == .google ? "calendar.badge.plus" : "calendar")
                                            .foregroundColor(.gray)
                                    }
                                    
                                    if calendarEvent.event.isAllDay {
                                        Text("All Day")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    } else {
                                        HStack {
                                            Text(formatDate(calendarEvent.event.startDate))
                                            Text("-")
                                            Text(formatDate(calendarEvent.event.endDate))
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    }
                                    
                                    if let location = calendarEvent.event.location, !location.isEmpty {
                                        Text(location)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Calendar View")
            .navigationBarItems(
                leading: Button("Settings") {
                    showingAuthPrompt = true
                },
                trailing: Button("Done") {
                    dismiss()
                }
            )
            .onChange(of: selectedDate) { _, newDate in
                loadEvents(for: newDate)
            }
            .sheet(isPresented: $showingAuthPrompt) {
                NavigationStack {
                    CalendarIntegrationView()
                }
            }
            .onAppear {
                loadEvents(for: selectedDate)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func loadEvents(for date: Date) {
        guard calendarManager.isAuthorized || calendarManager.isGoogleAuthorized else { return }
        
        isLoading = true
        
        Task {
            let fetchedEvents = await calendarManager.fetchEventsForDate(date)
            
            await MainActor.run {
                self.events = fetchedEvents
                self.isLoading = false
            }
        }
    }
}

#Preview {
    CalendarOverlayView()
} 