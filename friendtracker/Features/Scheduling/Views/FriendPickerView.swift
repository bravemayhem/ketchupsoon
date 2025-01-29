import SwiftUI
import SwiftData

struct FriendPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFriend: Friend?
    @Query(sort: [SortDescriptor(\Friend.name)]) private var friends: [Friend]
    @State private var searchText = ""
    
    var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friends
        }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredFriends) { friend in
                    Button {
                        selectedFriend = friend
                        dismiss()
                    } label: {
                        HStack {
                            Text(friend.name)
                                .foregroundColor(AppColors.label)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.secondaryLabel)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search friends")
            .navigationTitle("Select Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FriendPickerView(selectedFriend: .constant(nil))
        .modelContainer(for: [Friend.self], inMemory: true)
} 