import SwiftUI
import Contacts
import SwiftData

struct ContactPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var contactsManager = ContactsManager()
    @State private var selectedContacts: Set<String> = []
    @State private var showingSettingsAlert = false
    
    var body: some View {
        NavigationStack {
            VStack {
                switch contactsManager.authorizationStatus {
                case .notDetermined:
                    RequestAccessView(contactsManager: contactsManager)
                case .denied, .restricted:
                    DeniedAccessView()
                case .authorized, .limited:
                    ContactListView(
                        contacts: contactsManager.contacts,
                        selectedContacts: $selectedContacts
                    )
                @unknown default:
                    RequestAccessView(contactsManager: contactsManager)
                }
            }
            .navigationTitle("Import Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        importSelectedContacts()
                        dismiss()
                    }
                    .disabled(selectedContacts.isEmpty)
                }
            }
        }
        .onChange(of: contactsManager.isAuthorized) { _, isAuthorized in
            if isAuthorized {
                Task {
                    await contactsManager.fetchContacts()
                }
            }
        }
        .alert("Contacts Access Required", isPresented: $showingSettingsAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable contacts access in Settings to import your contacts.")
        }
    }
    
    private func importSelectedContacts() {
        contactsManager.contacts
            .filter { selectedContacts.contains($0.identifier) }
            .forEach { contact in
                addFriend(contact)
            }
    }
    
    private func addFriend(_ contact: CNContact) {
        let newFriend = Friend(
            name: "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces),
            phoneNumber: contact.phoneNumbers.first?.value.stringValue
        )
        modelContext.insert(newFriend)
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

struct DeniedAccessView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Access Denied")
                .font(.headline)
            
            Text("Please enable contacts access in Settings to import your contacts.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
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
            Text("\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces))
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
    }
} 
