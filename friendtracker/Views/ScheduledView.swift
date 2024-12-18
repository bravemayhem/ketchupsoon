import SwiftUI
import SwiftData

struct ScheduledView: View {
    @EnvironmentObject private var theme: Theme
    @Query(
        sort: [SortDescriptor(\Hangout.date)]
    ) private var hangouts: [Hangout]
    @State private var hangoutToCheck: Hangout?
    @State private var showingCompletionPrompt = false
    
    var upcomingHangouts: [Hangout] {
        hangouts.filter { hangout in
            hangout.isScheduled && hangout.date > Date() && !(hangout.needsReschedule ?? false)
        }
    }
    
    var pastHangouts: [Hangout] {
        hangouts.filter { hangout in
            hangout.isScheduled && hangout.date <= Date()
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !pastHangouts.isEmpty {
                    Section(header: Text("Past Hangouts")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)) {
                        ForEach(pastHangouts) { hangout in
                            HangoutCard(hangout: hangout)
                                .padding(.horizontal)
                                .onAppear {
                                    // Show completion prompt when past hangout appears
                                    hangoutToCheck = hangout
                                    showingCompletionPrompt = true
                                }
                        }
                    }
                }
                
                if upcomingHangouts.isEmpty && pastHangouts.isEmpty {
                    ContentUnavailableView("No Scheduled Hangouts", systemImage: "calendar.badge.plus")
                        .foregroundColor(theme.primaryText)
                } else {
                    Section(header: Text("Upcoming Hangouts")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)) {
                        ForEach(upcomingHangouts) { hangout in
                            HangoutCard(hangout: hangout)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(theme.background)
        .sheet(isPresented: $showingCompletionPrompt, onDismiss: {
            hangoutToCheck = nil
        }) {
            if let hangout = hangoutToCheck {
                HangoutCompletionView(hangout: hangout)
            }
        }
    }
}

struct HangoutCard: View {
    @EnvironmentObject private var theme: Theme
    let hangout: Hangout
    
    var body: some View {
        VStack(spacing: 16) {
            if let friend = hangout.friend {
                HStack(spacing: 16) {
                    ProfileImage(friend: friend)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(friend.name)
                            .font(.title3)
                            .bold()
                            .foregroundColor(theme.primaryText)
                            .lineLimit(1)
                        
                        Text(hangout.activity)
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                            .lineLimit(1)
                        
                        HStack(spacing: 16) {
                            Label {
                                Text(hangout.date.formatted(.relative(presentation: .named)))
                                    .lineLimit(1)
                            } icon: {
                                Image(systemName: "calendar")
                            }
                            .font(.subheadline)
                            
                            Label {
                                Text(hangout.location)
                                    .lineLimit(1)
                            } icon: {
                                Image(systemName: "mappin.and.ellipse")
                            }
                            .font(.subheadline)
                        }
                        .foregroundColor(theme.secondaryText)
                    }
                    
                    Spacer()
                }
            }
            
            Button(action: {
                // Message action
            }) {
                Label("Message", systemImage: "message")
                    .font(.headline)
                    .foregroundColor(theme.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.primaryText, lineWidth: 1)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
}

#Preview {
    ScheduledView()
        .modelContainer(for: Friend.self)
        .environmentObject(Theme.shared)
}