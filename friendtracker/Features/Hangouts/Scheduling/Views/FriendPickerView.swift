import SwiftUI
import SwiftData
import Contacts

// Represents either a Friend or a Contact
enum PersonItem: Identifiable {
    case friend(Friend)
    case contact(CNContact)
    
    var id: String {
        switch self {
        case .friend(let friend):
            return "friend-\(friend.id.uuidString)"
        case .contact(let contact):
            return "contact-\(contact.identifier)"
        }
    }
    
    var name: String {
        switch self {
        case .friend(let friend):
            return friend.name
        case .contact(let contact):
            return "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        }
    }
    
    var email: String? {
        switch self {
        case .friend(let friend):
            return friend.email
        case .contact(let contact):
            return contact.emailAddresses.first?.value as String?
        }
    }
    
    var isAlreadyFriend: Bool {
        if case .contact = self {
            return false
        }
        return true
    }
}

struct FriendPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedFriends: [Friend]
    @Query(sort: [SortDescriptor(\Friend.name)]) private var friends: [Friend]
    @State private var searchText = ""
    @State private var personItems: [PersonItem] = []
    @State private var isLoadingContacts = false
    let selectedTime: Date?
    
    var filteredItems: [PersonItem] {
        if searchText.isEmpty {
            return personItems
        }
        return personItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var selectionTitle: String {
        let count = selectedFriends.count
        return count == 0 ? "Select People" : "\(count) Person\(count > 1 ? "s" : "") Selected"
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !selectedFriends.isEmpty {
                    Section {
                        ForEach(selectedFriends) { friend in
                            PersonRow(item: .friend(friend), isSelected: true)
                                .onTapGesture {
                                    selectedFriends.removeAll(where: { $0.id == friend.id })
                                }
                        }
                    } header: {
                        Text("Selected")
                    } footer: {
                        let missingEmails = selectedFriends.filter { $0.email?.isEmpty ?? true }.count
                        if missingEmails > 0 {
                            Text("\(missingEmails) person\(missingEmails > 1 ? "s" : "") missing email address\(missingEmails > 1 ? "es" : "") - they won't receive calendar invites")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    if isLoadingContacts {
                        ProgressView("Loading contacts...")
                    } else {
                        ForEach(filteredItems) { item in
                            PersonRow(item: item, isSelected: isSelected(item))
                                .onTapGesture {
                                    handleSelection(item)
                                }
                        }
                    }
                } header: {
                    Text(selectedFriends.isEmpty ? "People" : "Add More")
                }
            }
            .searchable(text: $searchText, prompt: "Search people")
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
            .task {
                await loadContacts()
            }
        }
    }
    
    private func loadContacts() async {
        isLoadingContacts = true
        defer { isLoadingContacts = false }
        
        // Convert existing friends to PersonItems
        var items = friends.map { PersonItem.friend($0) }
        
        // Request contacts access and fetch contacts
        if await ContactsManager.shared.requestAccess() {
            let contacts = await ContactsManager.shared.fetchContacts()
            
            // Filter out contacts that are already friends
            let existingContactIds = Set(friends.compactMap { $0.contactIdentifier })
            let newContacts = contacts.filter { !existingContactIds.contains($0.identifier) }
            
            // Add filtered contacts to items
            items.append(contentsOf: newContacts.map { PersonItem.contact($0) })
        }
        
        // Sort all items by name
        items.sort { $0.name < $1.name }
        personItems = items
    }
    
    private func isSelected(_ item: PersonItem) -> Bool {
        switch item {
        case .friend(let friend):
            return selectedFriends.contains { $0.id == friend.id }
        case .contact:
            return false
        }
    }
    
    private func handleSelection(_ item: PersonItem) {
        switch item {
        case .friend(let friend):
            if isSelected(item) {
                selectedFriends.removeAll { $0.id == friend.id }
            } else {
                selectedFriends.append(friend)
            }
            
        case .contact(let contact):
            // Create a new friend from the contact
            let newFriend = Friend(
                name: "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces),
                contactIdentifier: contact.identifier,
                phoneNumber: contact.phoneNumbers.first?.value.stringValue,
                email: contact.emailAddresses.first?.value as String?,
                photoData: contact.imageData
            )
            
            modelContext.insert(newFriend)
            selectedFriends.append(newFriend)
            
            // Update the personItems list to show the new friend instead of the contact
            if let index = personItems.firstIndex(where: { 
                if case .contact(let c) = $0, c.identifier == contact.identifier {
                    return true
                }
                return false
            }) {
                personItems[index] = .friend(newFriend)
            }
        }
    }
}

private struct PersonRow: View {
    let item: PersonItem
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                if let email = item.email, !email.isEmpty {
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
            
            HStack {
                if !item.isAlreadyFriend {
                    Text("From Contacts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
                
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
}

#Preview {
    FriendPickerView(selectedFriends: .constant([]), selectedTime: Date())
        .modelContainer(for: [Friend.self], inMemory: true)
}
