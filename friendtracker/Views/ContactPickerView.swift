import SwiftUI
import Contacts
import SwiftData

struct ContactPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var contactsManager = ContactsManager.shared
    @State private var searchText = ""
    @State private var contacts: [CNContact] = []
    @State private var isLoading = true
    @State private var selectedContact: (name: String, identifier: String?, phoneNumber: String?)?
    @State private var showingOnboarding = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    contactsList
                }
            }
            .navigationTitle("Select Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingOnboarding) {
                if let contact = selectedContact {
                    FriendOnboardingView(contact: contact)
                }
            }
        }
        .task {
            await loadContacts()
        }
    }
    
    private var contactsList: some View {
        List(filteredContacts, id: \.identifier) { contact in
            Button {
                selectedContact = (
                    name: "\(contact.givenName) \(contact.familyName)",
                    identifier: contact.identifier,
                    phoneNumber: contact.phoneNumbers.first?.value.stringValue
                )
                showingOnboarding = true
            } label: {
                HStack {
                    if let imageData = contact.thumbnailImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("\(contact.givenName) \(contact.familyName)")
                            .foregroundColor(.primary)
                        if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                            Text(phoneNumber)
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search contacts")
    }
    
    private var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter {
            let fullName = "\($0.givenName) \($0.familyName)".lowercased()
            return fullName.contains(searchText.lowercased())
        }
    }
    
    private func loadContacts() async {
        isLoading = true
        let granted = await contactsManager.requestAccess()
        if granted {
            contacts = await contactsManager.fetchContacts()
        }
        isLoading = false
    }
} 
