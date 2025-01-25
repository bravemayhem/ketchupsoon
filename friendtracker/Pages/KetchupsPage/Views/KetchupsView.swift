/*

 KetchupsView is the view that serves as a central hub for managing social connections and meetups, combining calendar functionality with relationship management features.
 
- Upcoming hangouts
- Past hangouts
- Completed hangouts
- Upcoming check-ins that need scheduling

*/

import SwiftUI
import SwiftData

/// The main view for managing and displaying scheduled hangouts, past hangouts,
/// completed hangouts, and upcoming check-ins that need scheduling.
struct KetchupsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Hangout.date, order: .forward)]) private var hangouts: [Hangout]
    @Query(sort: [SortDescriptor(\Friend.lastSeen, order: .forward)]) private var friends: [Friend]
    @State private var selectedFriend: Friend?
    @State private var showingScheduler = false
    @State private var showingMessageSheet = false
    @State private var showingCalendarOverlay = false
    @State private var showingAllUpcoming = false
    @State private var showingAllPast = false
    @State private var showingAllCompleted = false
    
    private var scheduledFriendIds: Set<UUID> {
        Set(upcomingHangouts.compactMap { $0.friend?.id })
    }
    
    private var twoWeeksFromNow: Date {
        Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    }
    
    private func shouldIncludeInUpcomingCheckIns(_ friend: Friend) -> Bool {
        guard let nextConnect = friend.nextConnectDate else { return false }
        guard nextConnect <= twoWeeksFromNow else { return false }
        return !scheduledFriendIds.contains(friend.id)
    }
    
    var upcomingHangouts: [Hangout] {
        hangouts.filter { hangout in
            hangout.isScheduled && 
            hangout.date > Date() && 
            !hangout.needsReschedule
        }
    }
    
    var pastHangouts: [Hangout] {
        hangouts.filter { hangout in
            hangout.isScheduled && 
            hangout.date <= Date() && 
            !hangout.isCompleted
        }
    }
    
    var completedHangouts: [Hangout] {
        hangouts.filter { hangout in
            hangout.isScheduled && hangout.isCompleted
        }
    }
    
    var upcomingCheckIns: [Friend] {
        friends.filter(shouldIncludeInUpcomingCheckIns)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.spacingMedium, pinnedViews: [.sectionHeaders]) {
                // Calendar Button at the top
                Button(action: {
                    showingCalendarOverlay = true
                }) {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Calendar")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.accent.opacity(0.1))
                    .foregroundColor(AppColors.accent)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Upcoming Hangouts Section
                if !upcomingHangouts.isEmpty {
                    KetchupSectionView(
                        title: "Upcoming",
                        count: upcomingHangouts.count,
                        onSeeAllTapped: { showingAllUpcoming = true }
                    ) {
                        ForEach(upcomingHangouts.prefix(3)) { hangout in
                            HangoutCard(hangout: hangout)
                                .padding(.horizontal)
                        }
                    }
                }
                
                // Needs Scheduling Section
                if !upcomingCheckIns.isEmpty {
                    KetchupSectionView(
                        title: "Needs Scheduling",
                        count: upcomingCheckIns.count,
                        showSeeAll: false,
                        onSeeAllTapped: {}
                    ) {
                        ForEach(upcomingCheckIns.prefix(3)) { friend in
                            UnscheduledCheckInCard(
                                friend: friend,
                                onScheduleTapped: {
                                    selectedFriend = friend
                                    showingScheduler = true
                                },
                                onMessageTapped: {
                                    selectedFriend = friend
                                    showingMessageSheet = true
                                },
                                onCardTapped: {
                                    selectedFriend = friend
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Past Hangouts Section
                if !pastHangouts.isEmpty {
                    KetchupSectionView(
                        title: "Past Ketchups - Need Confirmation",
                        count: pastHangouts.count,
                        onSeeAllTapped: { showingAllPast = true }
                    ) {
                        ForEach(pastHangouts.prefix(3)) { hangout in
                            HangoutCard(hangout: hangout)
                                .padding(.horizontal)
                        }
                    }
                }
                
                // Completed Hangouts Section
                if !completedHangouts.isEmpty {
                    KetchupSectionView(
                        title: "Completed",
                        count: completedHangouts.count,
                        onSeeAllTapped: { showingAllCompleted = true }
                    ) {
                        ForEach(completedHangouts.prefix(3)) { hangout in
                            HangoutCard(hangout: hangout)
                                .padding(.horizontal)
                        }
                    }
                }
                
                if upcomingHangouts.isEmpty && pastHangouts.isEmpty && completedHangouts.isEmpty && upcomingCheckIns.isEmpty {
                    ContentUnavailableView("No Ketchups", systemImage: "calendar.badge.plus")
                        .foregroundColor(AppColors.label)
                }
            }
            .padding(.vertical)
        }
        .background(AppColors.systemBackground)
        .sheet(isPresented: $showingScheduler) {
            if let friend = selectedFriend {
                NavigationStack {
                    CreateHangoutView(friend: friend)
                }
            }
        }
        .sheet(isPresented: $showingMessageSheet) {
            if let friend = selectedFriend, let phoneNumber = friend.phoneNumber {
                NavigationStack {
                    MessageComposeView(recipient: phoneNumber)
                }
            }
        }
        .sheet(isPresented: $showingCalendarOverlay) {
            CalendarOverlayView()
        }
        .sheet(isPresented: $showingAllUpcoming) {
            HangoutListView(title: "Upcoming", hangouts: upcomingHangouts, maxItems: 10)
        }
        .sheet(isPresented: $showingAllPast) {
            HangoutListView(title: "Need Confirmation", hangouts: pastHangouts, maxItems: 10)
        }
        .sheet(isPresented: $showingAllCompleted) {
            HangoutListView(title: "Completed", hangouts: completedHangouts, maxItems: 10)
        }
        .onChange(of: selectedFriend) { _, newValue in
            if newValue == nil {
                showingScheduler = false
                showingMessageSheet = false
            }
        }
    }
}

#Preview {
    KetchupsView()
        .modelContainer(for: [Friend.self, Hangout.self], inMemory: true)
}
