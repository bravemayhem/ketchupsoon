import SwiftUI
import EventKit
import SwiftData

struct EventDetailView: View {
    let event: CalendarManager.CalendarEvent
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingFriendPicker = false
    @State private var selectedFriend: Friend?
    @State private var showingScheduler = false
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(event.event.title)
                            .font(.headline)
                        Spacer(minLength: 0)
                        if event.isKetchupEvent {
                            Image("Logo")
                                .renderingMode(.original)
                                .interpolation(.high)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }
                    }
                    
                    if let location = event.event.location, !location.isEmpty {
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.gray)
                            Text(location)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.gray)
                        if event.event.isAllDay {
                            Text("All Day")
                        } else {
                            Text("\(event.event.startDate.formatted(date: .omitted, time: .shortened)) - \(event.event.endDate.formatted(date: .omitted, time: .shortened))")
                        }
                    }
                    
                    if !event.isKetchupEvent {
                        Button {
                            showingFriendPicker = true
                        } label: {
                            Label("Convert to Ketchup", systemImage: "arrow.triangle.2.circlepath")
                                .foregroundColor(AppColors.accent)
                        }
                    }
                }
            }
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingFriendPicker) {
            FriendPickerView(
                selectedFriend: $selectedFriend,
                selectedTime: event.event.startDate
            )
        }
        .onChange(of: selectedFriend) { _, _ in
            showingScheduler = selectedFriend != nil
        }
        .sheet(isPresented: $showingScheduler, onDismiss: {
            selectedFriend = nil
        }) {
            if let friend = selectedFriend {
                NavigationStack {
                    CreateHangoutView(
                        friend: friend,
                        initialDate: event.event.startDate,
                        initialLocation: event.event.location,
                        initialTitle: event.event.title
                    )
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EventDetailView(
            event: CalendarManager.CalendarEvent(
                event: EKEvent(eventStore: EKEventStore()),
                source: .apple
            ),
            modelContext: try! ModelContainer(for: Friend.self).mainContext
        )
    }
} 
