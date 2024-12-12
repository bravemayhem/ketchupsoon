import SwiftUI

struct FriendsListView: View {
    @State private var friends = SampleData.friends
    @State private var showingAddFriend = false
    
    var body: some View {
        NavigationView {
            FriendsContent(
                friends: friends,
                showingAddFriend: $showingAddFriend
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Friends")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Theme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.primary)
                            .padding(.trailing)
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
    
    var body: some View {
        VStack(spacing: 16) {
            Text("This Month")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.primaryText)
            
            HStack(spacing: 16) {
                StatCard(
                    value: "\(hangoutsThisMonth)",
                    label: "Hangouts"
                )
                
                StatCard(
                    value: "5/6",
                    label: "Hang Target"
                )
            }
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(value)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(Theme.primary)
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(NeoBrutalistBackground())
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
