import SwiftUI
import EventKit
import SwiftData

struct DailyScheduleView: View {
    let events: [CalendarEvent]
    let date: Date
    let viewMode: ViewMode
    @Binding var selectedEvent: CalendarEvent?
    @Binding var showingEventDetails: Bool
    let onTimeSelected: (Date) -> Void
    @State private var currentTime = Date()
    
    private let hourHeight: CGFloat = 60
    private let timeWidth: CGFloat = 60
    private let startHour = 7 // 7 AM
    private let endHour = 24 // 11 PM
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    enum ViewMode {
        case daily
        case list
    }
    
    var body: some View {
        ScrollView {
            if viewMode == .daily {
                HStack(alignment: .top, spacing: 0) {
                    // Time column
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(startHour..<endHour, id: \.self) { hour in
                            Text(formatHour(hour))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(height: hourHeight, alignment: .top)
                                .padding(.trailing, 8)
                        }
                    }
                    .frame(width: timeWidth)
                    
                    // Events column
                    ZStack(alignment: .top) {
                        // Grid lines with gesture areas
                        VStack(spacing: 0) {
                            ForEach(startHour..<endHour, id: \.self) { hour in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 1)
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, hourHeight - 1)
                                    .contentShape(Rectangle())
                                    .onLongPressGesture {
                                        let calendar = Calendar.current
                                        var components = calendar.dateComponents([.year, .month, .day], from: date)
                                        components.hour = hour
                                        components.minute = 0
                                        if let newDate = calendar.date(from: components) {
                                            onTimeSelected(newDate)
                                        }
                                    }
                            }
                        }
                        
                        // Current time indicator
                        if Calendar.current.isDate(date, inSameDayAs: Date()) {
                            CurrentTimeIndicator(currentTime: currentTime, startHour: startHour, hourHeight: hourHeight)
                        }
                        
                        // Events
                        ForEach(events) { calendarEvent in
                            if let eventPosition = calculateEventPosition(calendarEvent.event) {
                                EventView(event: calendarEvent)
                                    .frame(height: eventPosition.height)
                                    .padding(.top, eventPosition.offset)
                                    .onTapGesture {
                                        selectedEvent = calendarEvent
                                        showingEventDetails = true
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                if events.isEmpty {
                    ContentUnavailableView(
                        "No Events",
                        systemImage: "calendar",
                        description: Text("No events scheduled for this day")
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(events) { calendarEvent in
                            Button {
                                selectedEvent = calendarEvent
                                showingEventDetails = true
                            } label: {
                                EventListItemView(event: calendarEvent)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            
                            Divider()
                        }
                    }
                }
            }
        }
        .onReceive(timer) { time in
            currentTime = time
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let suffix = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : hour
        return "\(displayHour) \(suffix)"
    }
    
    private struct EventPosition {
        let offset: CGFloat
        let height: CGFloat
    }
    
    private func calculateEventPosition(_ event: EKEvent) -> EventPosition? {
        let calendar = Calendar.current
        guard let startHourFloat = calendar.dateComponents([.hour, .minute], from: event.startDate).hour.map({ Float($0) }) else { return nil }
        guard let endHourFloat = calendar.dateComponents([.hour, .minute], from: event.endDate).hour.map({ Float($0) }) else { return nil }
        
        let startMinutes = Float(calendar.component(.minute, from: event.startDate))
        let endMinutes = Float(calendar.component(.minute, from: event.endDate))
        
        let startPosition = startHourFloat + startMinutes / 60.0
        let endPosition = endHourFloat + endMinutes / 60.0
        
        let offset = (startPosition - Float(startHour)) * Float(hourHeight)
        let height = (endPosition - startPosition) * Float(hourHeight)
        
        return EventPosition(offset: CGFloat(offset), height: CGFloat(height))
    }
}

// Event Title View Component
private struct EventTitleView: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 8) {
            Text(event.event.title)
                .font(.caption)
                .bold()
                .lineLimit(1)
                .foregroundColor(AppColors.label)
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
    }
}

// Event Location View Component
private struct EventLocationView: View {
    let location: String?
    
    var body: some View {
        if let location = location {
            Text(location)
                .font(.caption2)
                .lineLimit(1)
                .foregroundColor(AppColors.secondaryLabel)
        }
    }
}

// Main Event View
struct EventView: View {
    let event: CalendarEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            EventTitleView(event: event)
            EventLocationView(location: event.event.location)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(backgroundView)
        .overlay(borderView)
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(event.source == .google ? Color.purple.opacity(0.2) : Color.blue.opacity(0.2))
    }
    
    private var borderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(event.source == .google ? Color.purple.opacity(0.3) : Color.blue.opacity(0.3))
    }
}

// Current Time Indicator Component
private struct CurrentTimeIndicator: View {
    let currentTime: Date
    let startHour: Int
    let hourHeight: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Circle()
                    .fill(Color.black)
                    .frame(width: 8, height: 8)
                
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 2)
            }
            .offset(y: calculateOffset())
        }
    }
    
    private func calculateOffset() -> CGFloat {
        let calendar = Calendar.current
        let hour = Float(calendar.component(.hour, from: currentTime))
        let minute = Float(calendar.component(.minute, from: currentTime))
        let currentPosition = hour + minute / 60.0
        return CGFloat(currentPosition - Float(startHour)) * hourHeight
    }
}

#Preview {
    DailyScheduleView(
        events: [],
        date: Date(),
        viewMode: .daily,
        selectedEvent: .constant(nil),
        showingEventDetails: .constant(false),
        onTimeSelected: { _ in }
    )
    .modelContainer(for: [Friend.self])
} 
