import SwiftUI
import SwiftData
import MessageUI

struct FriendsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Friend.name)]) private var friends: [Friend]
    @State private var selectedFriend: Friend?
    @State private var showingAddFriend = false
    
    var body: some View {
        List {
            if friends.isEmpty {
                ContentUnavailableView("No Friends Added", systemImage: "person.2.badge.plus")
                    .foregroundColor(AppColors.label)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(friends) { friend in
                    FriendListCard(friend: friend)
                        .friendCardStyle()
                        .onTapGesture {
                            selectedFriend = friend
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                friend.needsToConnectFlag.toggle()
                            } label: {
                                Label(friend.needsToConnectFlag ? "Remove" : "Add", 
                                      systemImage: friend.needsToConnectFlag ? "star.slash.fill" : "star.fill")
                            }
                            .tint(friend.needsToConnectFlag ? .red : AppColors.success)
                        }
                }
            }
        }
        .friendListStyle()
        .friendSheetPresenter(selectedFriend: $selectedFriend)
        .navigationTitle("Friends")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddFriend = true
                } label: {
                    Image(systemName: "plus")
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .sheet(isPresented: $showingAddFriend) {
            NavigationStack {
                ContactPickerView()
            }
        }
    }
}

#Preview {
    NavigationStack {
        FriendsListView()
            .modelContainer(for: Friend.self)
    }
}
