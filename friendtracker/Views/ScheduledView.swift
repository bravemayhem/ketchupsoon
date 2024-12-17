import SwiftUI
import SwiftData

struct ScheduledView: View {
    @EnvironmentObject private var theme: Theme
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
                        .foregroundColor(theme.primaryText)
                } else {
                    ForEach(upcomingHangouts) { hangout in
                        HangoutCard(hangout: hangout)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(theme.background)
    }
}

struct HangoutCard: View {
    @EnvironmentObject private var theme: Theme
    let hangout: Hangout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(hangout.friend?.name ?? "")
                .font(.title2)
                .bold()
                .foregroundColor(theme.primaryText)
            
            Text(hangout.activity)
                .font(.title3)
                .foregroundColor(theme.secondaryText)
            
            HStack(spacing: 16) {
                Label {
                    Text(hangout.date.formatted(.relative(presentation: .named)))
                } icon: {
                    Image(systemName: "calendar")
                }
                .foregroundColor(theme.secondaryText)
                
                Label {
                    Text(hangout.location)
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                }
                .foregroundColor(theme.secondaryText)
            }
            
            HStack {
                Spacer()
                Button(action: {
                    // Message action
                }) {
                    Label("Message", systemImage: "message")
                        .font(.headline)
                        .foregroundColor(theme.primaryText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.primaryText, lineWidth: 1)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
                .shadow(color: Color.black.opacity(theme.shadowOpacity), radius: theme.shadowRadius, x: theme.shadowOffset.x, y: theme.shadowOffset.y)
        )
    }
}

#Preview {
    ScheduledView()
        .modelContainer(for: Friend.self)
        .environmentObject(Theme.shared)
}