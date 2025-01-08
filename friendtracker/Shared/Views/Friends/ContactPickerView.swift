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
    @State private var selectedContact: (name: String, identifier: String?, phoneNumber: String?, imageData: Data?, city: String?)?
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
                let city = contact.postalAddresses.first?.value.city
                selectedContact = (
                    name: "\(contact.givenName) \(contact.familyName)",
                    identifier: contact.identifier,
                    phoneNumber: contact.phoneNumbers.first?.value.stringValue,
                    imageData: contact.thumbnailImageData,
                    city: city
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
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("\(contact.givenName) \(contact.familyName)")
                            .foregroundColor(AppColors.label)
                        if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                            Text(phoneNumber)
                                .foregroundColor(AppColors.secondaryLabel)
                                .font(.subheadline)
                        }
                        if let city = contact.postalAddresses.first?.value.city {
                            Text(city)
                                .foregroundColor(AppColors.secondaryLabel)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .listRowBackground(AppColors.secondarySystemBackground)
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.systemBackground)
        .searchable(text: $searchText, prompt: Text("Search contacts"))
        .tint(AppColors.accent)
    }
    
    private var filteredContacts: [CNContact] {
        let sortedContacts = contacts.sorted { contact1, contact2 in
            let name1 = "\(contact1.givenName) \(contact1.familyName)".lowercased()
            let name2 = "\(contact2.givenName) \(contact2.familyName)".lowercased()
            return name1 < name2
        }
        
        if searchText.isEmpty {
            return sortedContacts
        }
        return sortedContacts.filter {
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
