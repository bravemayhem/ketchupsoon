import SwiftUI

struct FriendsListView: View {
    @State private var friends = SampleData.friends
    @State private var showingContactPicker = false
    @State private var searchText = ""
    
    // Compute stats
    private var hangoutsThisMonth: Int {
        friends.filter { $0.lastHangoutWeeks <= 4 }.count
    }
    
    @State private var currentMood: Int = 4
    
    var sortedFriends: [Friend] {
        friends.sorted { friend1, friend2 in
            if friend1.isOverdue != friend2.isOverdue {
                return friend1.isOverdue
            }
            return friend1.lastHangoutWeeks > friend2.lastHangoutWeeks
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.secondaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Stats Dashboard
                        VStack(alignment: .leading, spacing: 16) {
                            Text("This Month")
                                .font(.system(size: 22, weight: .bold, design: .default))
                                .foregroundColor(Theme.primaryText)
                            
                            HStack(spacing: 16) {
                                // Hangouts stat
                                VStack(alignment: .leading) {
                                    Text("\(hangoutsThisMonth)")
                                        .font(.system(size: 34, weight: .bold))
                                        .foregroundColor(Theme.primary)
                                    Text("Hangouts")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Theme.secondaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Theme.cardBackground)
                                .cornerRadius(12)
                                
                                // Mood stat
                                VStack(alignment: .leading) {
                                    Text("\(currentMood)/5")
                                        .font(.system(size: 34, weight: .bold))
                                        .foregroundColor(Theme.secondary)
                                    Text("Relationship Score")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Theme.secondaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Theme.cardBackground)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Friends List
                        LazyVStack(spacing: 16) {
                            ForEach(sortedFriends) { friend in
                                FriendCard(friend: friend)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Friends")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(Theme.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingContactPicker = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView(friends: $friends)
            }
        }
    }
}

#Preview {
    FriendsListView()
}
