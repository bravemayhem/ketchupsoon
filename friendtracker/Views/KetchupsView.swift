import SwiftUI
import SwiftData

struct KetchupsView: View {
    @Query(sort: [SortDescriptor(\Hangout.date)]) private var hangouts: [Hangout]
    @Query(sort: [SortDescriptor(\Friend.lastSeen)]) private var friends: [Friend]
    @State private var hangoutToCheck: Hangout?
    @State private var showingCompletionPrompt = false
    @State private var selectedFriend: Friend?
    
    private var scheduledFriendIds: Set<UUID> {
        Set(upcomingHangouts.compactMap { $0.friend?.id })
    }
    
    private var threeWeeksFromNow: Date {
        Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date()
    }
    
    private func shouldIncludeInUpcomingCheckIns(_ friend: Friend) -> Bool {
        guard let nextConnect = friend.nextConnectDate else { return false }
        guard nextConnect <= threeWeeksFromNow else { return false }
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
            hangout.endDate <= Date() && 
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
                Text("You've got a lot to look forward to")
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, -15)
                    .padding(.bottom, 8)
                
                if !upcomingCheckIns.isEmpty {
                    Section(header: Text("Needs Scheduling")
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppColors.label)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(AppColors.systemBackground)) {
                        ForEach(upcomingCheckIns) { friend in
                            UnscheduledCheckInCard(
                                friend: friend,
                                onScheduleTapped: {
                                    selectedFriend = friend
                                },
                                onMessageTapped: {
                                    selectedFriend = friend
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                if !completedHangouts.isEmpty {
                    Section(header: Text("Past Hangouts")
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppColors.label)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)) {
                        ForEach(completedHangouts) { hangout in
                            HangoutCard(hangout: hangout)
                                .padding(.horizontal)
                        }
                    }
                }
                
                if !pastHangouts.isEmpty {
                    Section(header: Text("Did this ketchup happen?")
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppColors.label)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)) {
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
                    }
                }
                
                if upcomingHangouts.isEmpty && pastHangouts.isEmpty && completedHangouts.isEmpty && upcomingCheckIns.isEmpty {
                    ContentUnavailableView("No Ketchups", systemImage: "calendar.badge.plus")
                        .foregroundColor(AppColors.label)
                } else if !upcomingHangouts.isEmpty {
                    Section(header: Text("Scheduled Ketchups")
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppColors.label)
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
        .background(AppColors.systemBackground)
        .sheet(isPresented: $showingCompletionPrompt, onDismiss: {
            hangoutToCheck = nil
        }) {
            if let hangout = hangoutToCheck {
                HangoutCompletionView(hangout: hangout)
            }
        }
        .friendSheetPresenter(selectedFriend: $selectedFriend)
    }
}

struct UnscheduledCheckInCard: View {
    let friend: Friend
    let onScheduleTapped: () -> Void
    let onMessageTapped: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.spacingMedium) {
            HStack(spacing: AppTheme.spacingMedium) {
                ProfileImage(friend: friend)
                
                VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                    Text(friend.name)
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppColors.label)
                        .lineLimit(1)
                    
                    if let frequency = friend.catchUpFrequency {
                        Text("Due for \(frequency) catch-up")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                }
                
                Spacer()
            }
            
            HStack(spacing: AppTheme.spacingMedium) {
                if friend.phoneNumber != nil {
                    Button(action: onMessageTapped) {
                        Label("Message", systemImage: "message.fill")
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppColors.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.spacingSmall)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                                    .stroke(AppColors.accent, lineWidth: 1)
                            )
                    }
                }
                
                Button(action: onScheduleTapped) {
                    Label("Schedule", systemImage: "calendar.badge.plus")
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppColors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.spacingSmall)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                                .stroke(AppColors.accent, lineWidth: 1)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.spacingMedium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(AppColors.secondarySystemBackground)
                .shadow(
                    color: AppTheme.shadowSmall.color,
                    radius: AppTheme.shadowSmall.radius,
                    x: AppTheme.shadowSmall.x,
                    y: AppTheme.shadowSmall.y
                )
        )
    }
}

struct HangoutCard: View {
    let hangout: Hangout
    @State private var selectedFriend: Friend?
    
    var body: some View {
        VStack(spacing: AppTheme.spacingMedium) {
            if let friend = hangout.friend {
                Button(action: {
                    selectedFriend = friend
                }) {
                    HStack(spacing: AppTheme.spacingMedium) {
                        ProfileImage(friend: friend)
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                            Text(friend.name)
                                .font(AppTheme.headlineFont)
                                .foregroundColor(AppColors.label)
                            
                            if let date = hangout.date {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(AppColors.secondaryLabel)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.spacingMedium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(AppColors.secondarySystemBackground)
                .shadow(
                    color: AppTheme.shadowSmall.color,
                    radius: AppTheme.shadowSmall.radius,
                    x: AppTheme.shadowSmall.x,
                    y: AppTheme.shadowSmall.y
                )
        )
        .friendSheetPresenter(selectedFriend: $selectedFriend)
    }
}

#if DEBUG
struct KetchupsView_Previews: PreviewProvider {
    static var previews: some View {
        KetchupsView()
            .modelContainer(for: [Friend.self, Hangout.self], inMemory: true)
    }
}
#endif
