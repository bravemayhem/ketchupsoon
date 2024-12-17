import SwiftUI
import SwiftData

struct ScheduledView: View {
    @Query(
        sort: [SortDescriptor(\Hangout.date)]
    ) private var hangouts: [Hangout]
    
    var upcomingHangouts: [Hangout] {
        hangouts.filter { hangout in
            hangout.isScheduled && hangout.date > Date()
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if upcomingHangouts.isEmpty {
                    ContentUnavailableView("No Scheduled Hangouts", systemImage: "calendar.badge.plus")
                } else {
                    ForEach(upcomingHangouts) { hangout in
                        HangoutCard(hangout: hangout)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct HangoutCard: View {
    let hangout: Hangout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Friend Name
            Text(hangout.friend?.name ?? "")
                .font(.title2)
                .bold()
            
            // Activity
            Text(hangout.activity)
                .font(.title3)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                // Date/Time
                Label {
                    Text(hangout.date.formatted(.relative(presentation: .named)))
                } icon: {
                    Image(systemName: "calendar")
                }
                .foregroundStyle(.secondary)
                
                // Location
                Label {
                    Text(hangout.location)
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                }
                .foregroundStyle(.secondary)
            }
            
            // Message Button
            HStack {
                Spacer()
                Button(action: {
                    // Message action
                }) {
                    Label("Message", systemImage: "message")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary, lineWidth: 1)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    ScheduledView()
        .modelContainer(for: Friend.self)
}