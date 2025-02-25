import SwiftUI
import EventKit

struct EventListItemView: View {
    let event: CalendarEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                if event.event.isAllDay {
                    Text("All Day")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text("\(event.event.startDate.formatted(date: .omitted, time: .shortened)) - \(event.event.endDate.formatted(date: .omitted, time: .shortened))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    EventListItemView(
        event: CalendarEvent(
            event: EKEvent(eventStore: EKEventStore()),
            source: .apple
        )
    )
} 