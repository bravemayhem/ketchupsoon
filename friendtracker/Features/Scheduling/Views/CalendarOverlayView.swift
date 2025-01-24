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
    @State private var viewMode: ViewMode = .daily
    @State private var selectedFriend: Friend?
    @State private var showingScheduler = false
    @State private var selectedTime: Date?
    
    enum ViewMode {
        case daily
        case list
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !calendarManager.isAuthorized && !calendarManager.isGoogleAuthorized {
                    ContentUnavailableView(
                        "Calendar Access Required",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Please connect your calendars in Settings to view your schedule.")
                    )
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        // Date picker and view mode toggle
                        HStack {
                            Picker("View Mode", selection: $viewMode) {
                                Image(systemName: "clock").tag(ViewMode.daily)
                                Image(systemName: "list.bullet").tag(ViewMode.list)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 100)
                            
                            Spacer()
                            
                            Button(action: {
                                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.gray)
                            }
                            
                            DatePicker(
                                "",
                                selection: $selectedDate,
                                displayedComponents: [.date]
                            )
                            .labelsHidden()
                            
                            Button(action: {
                                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                            }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        
                        Divider()
                        
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
                            if viewMode == .daily {
                                DailyScheduleView(
                                    events: events,
                                    date: selectedDate,
                                    selectedFriend: $selectedFriend
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
                }
            }
            .navigationTitle("Calendar")
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
            .onChange(of: selectedFriend) { _, _ in
                if selectedFriend != nil {
                    selectedTime = selectedDate
                    showingScheduler = true
                }
            }
            .sheet(isPresented: $showingAuthPrompt) {
                NavigationStack {
                    CalendarIntegrationView()
                }
            }
            .sheet(isPresented: $showingScheduler, onDismiss: {
                selectedFriend = nil
                selectedTime = nil
            }) {
                if let friend = selectedFriend {
                    NavigationStack {
                        SchedulerView(friend: friend, initialDate: selectedTime)
                    }
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