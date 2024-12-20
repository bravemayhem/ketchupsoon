import SwiftUI
import SwiftData

struct KetchupsView: View {
    @Query(
        sort: [SortDescriptor(\Hangout.date)]
    ) private var hangouts: [Hangout]
    @Query(sort: [SortDescriptor(\Friend.lastSeen)]) private var friends: [Friend]
    @State private var hangoutToCheck: Hangout?
    @State private var showingCompletionPrompt = false
    @State private var selectedFriend: Friend?
    @State private var showingScheduler = false
    
    var upcomingHangouts: [Hangout] {
        hangouts.filter { hangout in
            hangout.isScheduled && hangout.date > Date() && !(hangout.needsReschedule ?? false)
        }
    }
    
    var pastHangouts: [Hangout] {
        hangouts.filter { hangout in
            hangout.isScheduled && hangout.endDate <= Date() && !hangout.isCompleted
        }
    }
    
    var completedHangouts: [Hangout] {
        hangouts.filter { hangout in
            hangout.isScheduled && hangout.isCompleted
        }
    }
    
    var upcomingCheckIns: [Friend] {
        let scheduledFriendIds = Set(upcomingHangouts.compactMap { $0.friend?.id })
        return friends.filter { friend in
            // Has a frequency set
            guard let nextConnect = friend.nextConnectDate,
                  friend.catchUpFrequency != nil else { return false }
            
            // Due within next 3 weeks
            let threeWeeksFromNow = Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date()
            guard nextConnect <= threeWeeksFromNow else { return false }
            
            // Not already scheduled
            return !scheduledFriendIds.contains(friend.id)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.spacingMedium) {
                if !upcomingCheckIns.isEmpty {
                    Section(header: Text("Needs Scheduling")
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppColors.label)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)) {
                        ForEach(upcomingCheckIns) { friend in
                            UnscheduledCheckInCard(friend: friend) {
                                selectedFriend = friend
                                showingScheduler = true
                            }
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
        .sheet(isPresented: $showingScheduler) {
            if let friend = selectedFriend {
                NavigationStack {
                    SchedulerView(initialFriend: friend)
                }
            }
        }
    }
}

struct UnscheduledCheckInCard: View {
    let friend: Friend
    let onScheduleTapped: () -> Void
    
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
            
            Button(action: onScheduleTapped) {
                Label("Schedule Ketchup", systemImage: "calendar.badge.plus")
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
    @State private var showingMessageSheet = false
    @State private var showingFriendDetails = false
    
    var body: some View {
        VStack(spacing: AppTheme.spacingMedium) {
            if let friend = hangout.friend {
                Button(action: {
                    showingFriendDetails = true
                }) {
                    HStack(spacing: AppTheme.spacingMedium) {
                        ProfileImage(friend: friend)
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                            Text(friend.name)
                                .font(AppTheme.headlineFont)
                                .foregroundColor(AppColors.label)
                                .lineLimit(1)
                            
                            Text(hangout.activity)
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppColors.secondaryLabel)
                                .lineLimit(1)
                            
                            HStack(spacing: AppTheme.spacingMedium) {
                                Label {
                                    Text(hangout.date.formatted(.relative(presentation: .named)))
                                        .lineLimit(1)
                                } icon: {
                                    Image(systemName: "calendar")
                                }
                                .font(AppTheme.captionFont)
                                
                                Label {
                                    Text(hangout.location)
                                        .lineLimit(1)
                                } icon: {
                                    Image(systemName: "mappin.and.ellipse")
                                }
                                .font(AppTheme.captionFont)
                            }
                            .foregroundColor(AppColors.secondaryLabel)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                }
            }
            
            if let friend = hangout.friend, friend.phoneNumber != nil {
                Button(action: {
                    showingMessageSheet = true
                }) {
                    Label("Message", systemImage: "message")
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
        .sheet(isPresented: $showingMessageSheet) {
            if let friend = hangout.friend, let phoneNumber = friend.phoneNumber {
                MessageComposeView(recipient: phoneNumber)
            }
        }
        .sheet(isPresented: $showingFriendDetails) {
            if let friend = hangout.friend {
                NavigationStack {
                    FriendDetailView(
                        friend: friend,
                        presentationMode: .sheet($showingFriendDetails)
                    )
                }
            }
        }
    }
}

#Preview {
    KetchupsView()
        .modelContainer(for: [Friend.self, Hangout.self])
}