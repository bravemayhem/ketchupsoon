import SwiftUI
import EventKit

struct EventListItemView: View {
    let event: CalendarManager.CalendarEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(event.event.title)
                    .font(.headline)
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
            
            HStack {
                Text(formatTime(event.event.startDate))
                Text("-")
                Text(formatTime(event.event.endDate))
            }
            .font(.subheadline)
            .foregroundColor(.gray)
            
            if let location = event.event.location, !location.isEmpty {
                Text(location)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    EventListItemView(event: CalendarManager.CalendarEvent(
        event: EKEvent(eventStore: EKEventStore()),
        source: .apple
    ))
} 