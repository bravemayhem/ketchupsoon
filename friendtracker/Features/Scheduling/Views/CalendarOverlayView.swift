import SwiftUI
import EventKit
import GoogleAPIClientForREST_Calendar
import SwiftData

struct CalendarOverlayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var calendarManager = CalendarManager.shared
    @State private var selectedDate = Date()
    @State private var events: [CalendarManager.CalendarEvent] = []
    @State private var showingAuthPrompt = false
    @State private var isLoading = false
    @State private var viewMode: DailyScheduleView.ViewMode = .daily
    @State private var showingCreateHangout = false
    @State private var selectedTime: Date?
    @State private var selectedEvent: CalendarManager.CalendarEvent?
    @State private var showingEventDetails = false
    
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
                        calendarHeader
                        
                        Divider()
                        
                        if isLoading && events.isEmpty {
                            ProgressView()
                                .padding()
                        } else {
                            calendarContent
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
                Task {
                    await loadEvents(for: newDate)
                }
            }
            .sheet(isPresented: $showingAuthPrompt) {
                NavigationStack {
                    CalendarIntegrationView()
                }
            }
            .sheet(isPresented: $showingCreateHangout, onDismiss: {
                selectedTime = nil
                Task {
                    await loadEvents(for: selectedDate)
                }
            }) {
                NavigationStack {
                    CreateHangoutView(initialDate: selectedTime)
                }
            }
            .sheet(isPresented: $showingEventDetails) {
                if let event = selectedEvent {
                    NavigationStack {
                        EventDetailView(event: event, modelContext: modelContext)
                    }
                }
            }
        }
        .task {
            let calendar = Calendar.current
            let dateKey = calendar.startOfDay(for: selectedDate).ISO8601Format()
            if let cached = calendarManager.eventCache[dateKey] {
                self.events = cached.events
            }
            await loadEvents(for: selectedDate)
        }
    }
    
    private var calendarHeader: some View {
        HStack {
            Picker("View Mode", selection: $viewMode) {
                Image(systemName: "clock").tag(DailyScheduleView.ViewMode.daily)
                Image(systemName: "list.bullet").tag(DailyScheduleView.ViewMode.list)
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
    }
    
    private var calendarContent: some View {
        DailyScheduleView(
            events: events,
            date: selectedDate,
            viewMode: viewMode,
            selectedEvent: $selectedEvent,
            showingEventDetails: $showingEventDetails,
            onTimeSelected: { time in
                selectedTime = time
                showingCreateHangout = true
            }
        )
    }
    
    private func loadEvents(for date: Date) async {
        guard calendarManager.isAuthorized || calendarManager.isGoogleAuthorized else {
            return
        }
        
        if events.isEmpty {
            await MainActor.run {
                isLoading = true
            }
        }
        
        let fetchedEvents = await calendarManager.getEventsForDate(date)
        
        await MainActor.run {
            self.events = fetchedEvents
            self.isLoading = false
        }
    }
}

#Preview {
    CalendarOverlayView()
        .modelContainer(for: [Friend.self, Hangout.self])
} 
