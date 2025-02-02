import SwiftUI
import SwiftData

struct FriendPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFriend: Friend?
    @Query(sort: [SortDescriptor(\Friend.name)]) private var friends: [Friend]
    @State private var searchText = ""
    let selectedTime: Date?
    
    var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friends
        }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredFriends) { friend in
                Button(action: {
                    selectedFriend = friend
                    dismiss()
                }) {
                    HStack {
                        Text(friend.name)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search friends")
            .navigationTitle("Select Friend for \(formatTime(selectedTime ?? Date()))")
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
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    FriendPickerView(selectedFriend: .constant(nil), selectedTime: Date())
        .modelContainer(for: [Friend.self], inMemory: true)
}
