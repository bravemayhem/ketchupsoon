import SwiftUI
import Contacts

struct ContactPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var contactsManager = ContactsManager()
    @State private var contacts: [CNContact] = []
    @State private var selectedContacts: Set<String> = []
    @Binding var friends: [Friend]
    
    var body: some View {
        NavigationView {
            VStack {
                if !contactsManager.isAuthorized {
                    RequestAccessView(contactsManager: contactsManager)
                } else {
                    ContactListView(
                        contacts: contacts,
                        selectedContacts: $selectedContacts
                    )
                }
            }
            .navigationTitle("Import Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        importSelectedContacts()
                        dismiss()
                    }
                    .disabled(selectedContacts.isEmpty)
                }
            }
        }
        .onAppear {
            if contactsManager.isAuthorized {
                contacts = contactsManager.fetchContacts()
            }
        }
    }
    
    private func importSelectedContacts() {
        let newFriends = contacts
            .filter { selectedContacts.contains($0.identifier) }
            .map { contact in
                Friend(
                    name: "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces),
                    frequency: "Monthly catch-up",
                    lastHangoutWeeks: 0
                )
            }
        friends.append(contentsOf: newFriends)
    }
}

struct RequestAccessView: View {
    let contactsManager: ContactsManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Contact Access Required")
                .font(.headline)
            
            Text("To import your contacts, please grant access to your contacts list.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Grant Access") {
                contactsManager.requestAccess()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct ContactListView: View {
    let contacts: [CNContact]
    @Binding var selectedContacts: Set<String>
    @State private var searchText = ""
    
    var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter {
            "\($0.givenName) \($0.familyName)".lowercased()
                .contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredContacts, id: \.identifier) { contact in
                ContactRow(
                    contact: contact,
                    isSelected: selectedContacts.contains(contact.identifier)
                )
                .onTapGesture {
                    if selectedContacts.contains(contact.identifier) {
                        selectedContacts.remove(contact.identifier)
                    } else {
                        selectedContacts.insert(contact.identifier)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search contacts")
    }
}

struct ContactRow: View {
    let contact: CNContact
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text("\(contact.givenName) \(contact.familyName)")
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
    }
} 