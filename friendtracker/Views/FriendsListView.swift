import SwiftUI

struct FriendsListView: View {
    @State private var friends = SampleData.friends
    @State private var showingAddFriend = false
    
    var sortedFriends: [Friend] {
        friends.sorted { friend1, friend2 in
            // Sort overdue friends first
            if friend1.isOverdue != friend2.isOverdue {
                return friend1.isOverdue
            }
            // For friends with same overdue status, sort by weeks since last hangout
            return friend1.lastHangoutWeeks > friend2.lastHangoutWeeks
        }
    }
    
    var body: some View {
        NavigationView {
            FriendsContent(
                friends: sortedFriends,
                showingAddFriend: $showingAddFriend
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("bfriended")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundColor(Theme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.primary)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                ContactPickerView(friends: $friends)
            }
        }
    }
}

private struct FriendsContent: View {
    let friends: [Friend]
    @Binding var showingAddFriend: Bool
    @State private var searchText = ""
    @State private var selectedFilter = FriendFilter.all
    
    enum FriendFilter: Hashable {
        case all, innerCircle, local, longDistance
        
        var title: String {
            switch self {
            case .all: return "all friends"
            case .innerCircle: return "inner circle"
            case .local: return "local"
            case .longDistance: return "long distance"
            }
        }
    }
    
    private var filteredFriends: [Friend] {
        let filtered = friends.filter { friend in
            if searchText.isEmpty { return true }
            return friend.name.lowercased().contains(searchText.lowercased())
        }
        
        let filteredByCategory = switch selectedFilter {
        case .all: filtered
        case .innerCircle: filtered.filter { $0.isInnerCircle }
        case .local: filtered.filter { $0.isLocal }
        case .longDistance: filtered.filter { !$0.isLocal }
        }
        
        // Sort by overdue status first, then by lastHangoutWeeks
        return filteredByCategory.sorted { friend1, friend2 in
            if friend1.isOverdue != friend2.isOverdue {
                return friend1.isOverdue && !friend2.isOverdue
            }
            return friend1.lastHangoutWeeks > friend2.lastHangoutWeeks
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StatsHeader(
                    hangoutsThisMonth: 5,  // TODO: Calculate this
                    currentMood: 4         // TODO: Calculate this
                )
                
                SearchAndFilterView(
                    searchText: $searchText,
                    selectedFilter: $selectedFilter
                )
                
                FriendsList(friends: filteredFriends)
            }
            .padding()
        }
        .background(Theme.background)
    }
}

private struct SearchAndFilterView: View {
    @Binding var searchText: String
    @Binding var selectedFilter: FriendsContent.FriendFilter
    
    var body: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.secondaryText)
                TextField("search for friends", text: $searchText)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding()
            .background(NeoBrutalistBackground())
            
            // Filter Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([
                        FriendsContent.FriendFilter.all,
                        .innerCircle,
                        .local,
                        .longDistance
                    ], id: \.self) { filter in
                        FilterTab(
                            title: filter.title,
                            isSelected: filter == selectedFilter
                        )
                        .onTapGesture {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct FilterTab: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                NeoBrutalistBackground()
                    .opacity(isSelected ? 1 : 0.5)
            )
            .foregroundColor(isSelected ? Theme.primary : Theme.secondaryText)
    }
}

private struct StatsHeader: View {
    let hangoutsThisMonth: Int
    let currentMood: Int
    @State private var monthlyGoal: Int = 6
    @State private var hasReachedGoal = false
    @State private var showingCelebration = false
    
    private var currentMonthYear: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: Date())
    }
    
    private var progressText: String {
        if hangoutsThisMonth >= monthlyGoal {
            return "🎉"  // Just show the emoji when goal is met
        } else {
            let percentage = min(Int((Double(hangoutsThisMonth) / Double(monthlyGoal)) * 100), 100)
            return "\(percentage)%"
        }
    }
    
    private func checkGoalStatus() {
        let hasReachedGoalNow = hangoutsThisMonth >= monthlyGoal
        if hasReachedGoalNow && !hasReachedGoal {
            hasReachedGoal = true
            showingCelebration = true
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            // Hide celebration after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showingCelebration = false
                }
            }
        } else if !hasReachedGoalNow {
            hasReachedGoal = false
            showingCelebration = false
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // Month indicator and stats container
                VStack(spacing: 16) {
                    // Month indicator
                    Text(currentMonthYear)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.primaryText)
                    
                    // Stats row
                    HStack(spacing: 12) {
                        StatCard(
                            value: "\(hangoutsThisMonth)",
                            label: "Hangs"
                        )
                        
                        StatCard(
                            value: progressText,
                            label: "Progress",
                            isProgressCard: true,
                            isGoalMet: hangoutsThisMonth >= monthlyGoal
                        )
                        
                        StatCard(
                            value: "\(monthlyGoal)",
                            label: "Goal",
                            isGoal: true,
                            goalValue: $monthlyGoal
                        )
                    }
                }
                .padding(20)
            }
            .padding(.horizontal)
            
            // Celebration popup
            if showingCelebration {
                VStack {
                    Text("Goal met! 🎉")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.primary)
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        )
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingCelebration)
                .zIndex(1)
            }
        }
        .onAppear {
            checkGoalStatus()
        }
        .onChange(of: hangoutsThisMonth) { _, _ in
            checkGoalStatus()
        }
        .onChange(of: monthlyGoal) { _, _ in
            checkGoalStatus()
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    var isGoal: Bool = false
    var isProgressCard: Bool = false
    var isGoalMet: Bool = false
    var goalValue: Binding<Int>? = nil
    @State private var showingGoalAdjuster = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if isProgressCard && isGoalMet {
                    Text(value)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Theme.primary)
                        .frame(maxWidth: .infinity, alignment: .center) // Center the emoji
                        .frame(height: 34)
                } else {
                    Text(value)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Theme.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(height: 34)
                        .frame(maxWidth: isGoal ? nil : .infinity, alignment: .leading)
                }
                
                if isGoal {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        showingGoalAdjuster = true
                    }) {
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.secondaryText)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Theme.secondaryBackground)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.secondaryBackground)
        )
        .sheet(isPresented: $showingGoalAdjuster) {
            if let goalBinding = goalValue {
                GoalAdjusterSheet(goalValue: goalBinding)
            }
        }
    }
}

private struct GoalAdjusterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var goalValue: Int
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Monthly Hangout Goal")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.primaryText)
                
                // Stepper with value display
                HStack(spacing: 20) {
                    Button(action: { if goalValue > 1 { goalValue -= 1 } }) {
                        Image(systemName: "minus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Theme.primary)
                            .frame(width: 44, height: 44)
                            .background(Theme.secondaryBackground)
                            .clipShape(Circle())
                    }
                    
                    Text("\(goalValue)")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Theme.primaryText)
                        .frame(minWidth: 60)
                    
                    Button(action: { if goalValue < 31 { goalValue += 1 } }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Theme.primary)
                            .frame(width: 44, height: 44)
                            .background(Theme.secondaryBackground)
                            .clipShape(Circle())
                    }
                }
                .padding(.vertical, 20)
                
                Text("Set how many times you want to hang out with friends each month")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
            )
        }
    }
}

private struct FriendsList: View {
    let friends: [Friend]
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(friends) { friend in
                FriendCard(friend: friend)
            }
        }
    }
}

#Preview {
    FriendsListView()
}
