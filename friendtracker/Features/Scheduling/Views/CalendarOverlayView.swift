import SwiftUI
import EventKit
import GoogleAPIClientForREST_Calendar
import SwiftData

struct CalendarOverlayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var calendarManager = CalendarManager()
    @State private var selectedDate = Date()
    @State private var events: [CalendarManager.CalendarEvent] = []
    @State private var showingAuthPrompt = false
    @State private var isLoading = false
    @State private var viewMode: DailyScheduleView.ViewMode = .daily
    @State private var selectedFriend: Friend?
    @State private var showingScheduler = false
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
                        
                        if isLoading {
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
                Task {
                    await loadEvents(for: selectedDate)
                }
            }) {
                if let friend = selectedFriend {
                    NavigationStack {
                        CreateHangoutView(friend: friend, initialDate: selectedTime)
                    }
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
            selectedFriend: $selectedFriend,
            selectedEvent: $selectedEvent,
            showingEventDetails: $showingEventDetails
        )
    }
    
    private func loadEvents(for date: Date) async {
        await calendarManager.ensureInitialized()
        
        guard calendarManager.isAuthorized || calendarManager.isGoogleAuthorized else {
            return
        }
        
        await MainActor.run {
            isLoading = true
            events = []
        }
        
        let fetchedEvents = await calendarManager.fetchEventsForDate(date)
        
        await MainActor.run {
            self.events = fetchedEvents
            self.isLoading = false
        }
    }
}

#Preview {
    CalendarOverlayView()
} 
