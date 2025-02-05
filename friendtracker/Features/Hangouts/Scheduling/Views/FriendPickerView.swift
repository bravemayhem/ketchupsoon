import SwiftUI
import SwiftData

struct FriendPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFriends: [Friend]
    @Query(sort: [SortDescriptor(\Friend.name)]) private var friends: [Friend]
    @State private var searchText = ""
    let selectedTime: Date?
    
    var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friends
        }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var selectionTitle: String {
        let count = selectedFriends.count
        return count == 0 ? "Select Friends" : "\(count) Friend\(count > 1 ? "s" : "") Selected"
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !selectedFriends.isEmpty {
                    Section {
                        ForEach(selectedFriends) { friend in
                            FriendRow(friend: friend, isSelected: true)
                                .onTapGesture {
                                    selectedFriends.removeAll(where: { $0.id == friend.id })
                                }
                        }
                    } header: {
                        Text("Selected")
                    } footer: {
                        let missingEmails = selectedFriends.filter { $0.email?.isEmpty ?? true }.count
                        if missingEmails > 0 {
                            Text("\(missingEmails) friend\(missingEmails > 1 ? "s" : "") missing email address\(missingEmails > 1 ? "es" : "") - they won't receive calendar invites")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    ForEach(filteredFriends.filter { friend in
                        !selectedFriends.contains(where: { $0.id == friend.id })
                    }) { friend in
                        FriendRow(friend: friend, isSelected: false)
                            .onTapGesture {
                                selectedFriends.append(friend)
                            }
                    }
                } header: {
                    Text(selectedFriends.isEmpty ? "Friends" : "Add More")
                }
            }
            .searchable(text: $searchText, prompt: "Search friends")
            .navigationTitle(selectionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(selectedFriends.isEmpty)
                }
            }
        }
    }
}

private struct FriendRow: View {
    let friend: Friend
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(friend.name)
                if let email = friend.email, !email.isEmpty {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No email address")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    FriendPickerView(selectedFriends: .constant([]), selectedTime: Date())
        .modelContainer(for: [Friend.self], inMemory: true)
}
