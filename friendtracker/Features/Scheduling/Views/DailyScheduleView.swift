import SwiftUI
import EventKit

struct DailyScheduleView: View {
    let events: [CalendarManager.CalendarEvent]
    let date: Date
    
    private let hourHeight: CGFloat = 60
    private let timeWidth: CGFloat = 60
    private let startHour = 8 // 8 AM
    private let endHour = 20 // 8 PM
    
    var body: some View {
        ScrollView {
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
                    // Grid lines
                    VStack(spacing: 0) {
                        ForEach(startHour..<endHour, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 1)
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, hourHeight - 1)
                        }
                    }
                    
                    // Events
                    ForEach(events, id: \.event.eventIdentifier) { calendarEvent in
                        if let eventPosition = calculateEventPosition(calendarEvent.event) {
                            EventView(event: calendarEvent)
                                .frame(height: eventPosition.height)
                                .padding(.top, eventPosition.offset)
                        }
                    }
                }
            }
            .padding(.horizontal)
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

struct EventView: View {
    let event: CalendarManager.CalendarEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.event.title)
                .font(.caption)
                .bold()
                .lineLimit(1)
            
            if let location = event.event.location {
                Text(location)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(event.source == .google ? Color.purple.opacity(0.2) : Color.blue.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(event.source == .google ? Color.purple.opacity(0.3) : Color.blue.opacity(0.3))
        )
    }
}

#Preview {
    DailyScheduleView(events: [], date: Date())
} 