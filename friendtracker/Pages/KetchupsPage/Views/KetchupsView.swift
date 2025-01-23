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
    @State private var hangoutToCheck: Hangout?
    @State private var showingCompletionPrompt = false
    @State private var selectedFriend: Friend?
    @State private var showingScheduler = false
    @State private var showingMessageSheet = false
    
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
                if !upcomingHangouts.isEmpty {
                    Section {
                        ForEach(upcomingHangouts) { hangout in
                            HangoutCard(hangout: hangout)
                                .padding(.horizontal)
                        }
                    } header: {
                        Text("Upcoming")
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppColors.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(AppColors.systemBackground)
                    }
                }
                
                if !pastHangouts.isEmpty {
                    Section {
                        ForEach(pastHangouts) { hangout in
                            HangoutCard(hangout: hangout)
                                .padding(.horizontal)
                                .onAppear {
                                    if !hangout.isCompleted {
                                        hangoutToCheck = hangout
                                        showingCompletionPrompt = true
                                    }
                                }
                        }
                    } header: {
                        Text("Past Ketchups - Need Confirmation")
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppColors.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(AppColors.systemBackground)
                    }
                }
                
                if !completedHangouts.isEmpty {
                    Section {
                        ForEach(completedHangouts) { hangout in
                            HangoutCard(hangout: hangout)
                                .padding(.horizontal)
                        }
                    } header: {
                        Text("Completed")
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppColors.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(AppColors.systemBackground)
                    }
                }
                
                if !upcomingCheckIns.isEmpty {
                    Section {
                        ForEach(upcomingCheckIns) { friend in
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
                    } header: {
                        Text("Needs Scheduling")
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppColors.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(AppColors.systemBackground)
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
        .sheet(isPresented: $showingCompletionPrompt, onDismiss: {
            hangoutToCheck = nil
        }) {
            if let hangout = hangoutToCheck {
                HangoutCompletionView(hangout: hangout)
            }
        }
        .sheet(isPresented: $showingScheduler) {
            if let friend = selectedFriend {
                NavigationStack {
                    SchedulerView(initialFriend: friend)
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
