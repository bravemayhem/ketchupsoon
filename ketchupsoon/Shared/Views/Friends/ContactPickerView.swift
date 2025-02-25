import SwiftUI
import Contacts
import SwiftData

struct ContactPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var existingFriends: [Friend]
    @StateObject private var contactsManager = ContactsManager.shared
    @State private var searchText = ""
    @State private var contacts: [CNContact] = []
    @State private var isLoading = true
    @State private var selectedContacts: Set<String> = []
    @State private var showingOnboarding = false
    @State private var onboardingContacts: [(name: String, identifier: String?, phoneNumber: String?, email: String?, imageData: Data?, city: String?)] = []
    @State private var currentOnboardingIndex = 0
    @State private var currentOnboardingView: FriendOnboardingView?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    contactsList
                }
            }
            .navigationTitle("Select Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if !selectedContacts.isEmpty {
                        Button("Next (\(selectedContacts.count))") {
                            startBulkOnboarding()
                        }
                        .tint(AppColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingOnboarding) {
                if !onboardingContacts.isEmpty {
                    NavigationView {
                        VStack(spacing: 0) {
                            // Progress bar
                            HStack(spacing: 16) {
                                Text("Friend \(currentOnboardingIndex + 1) of \(onboardingContacts.count)")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.secondaryLabel)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .frame(width: geometry.size.width, height: 4)
                                            .opacity(0.3)
                                            .foregroundColor(AppColors.secondarySystemBackground)
                                        
                                        Rectangle()
                                            .frame(width: geometry.size.width * CGFloat(currentOnboardingIndex + 1) / CGFloat(onboardingContacts.count), height: 4)
                                            .foregroundColor(AppColors.accent)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                }
                                .frame(height: 4)
                            }
                            .padding()
                            .background(AppColors.systemBackground)
                            
                            // Current friend onboarding
                            FriendOnboardingView(contact: onboardingContacts[currentOnboardingIndex]) { friend in
                                // Move to next friend regardless of whether this one was added or skipped
                                if currentOnboardingIndex < onboardingContacts.count - 1 {
                                    withAnimation {
                                        currentOnboardingIndex += 1
                                    }
                                } else {
                                    showingOnboarding = false
                                    dismiss()
                                }
                            }
                            .id(currentOnboardingIndex)
                        }
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Skip All") {
                                    importSelectedContacts()
                                    showingOnboarding = false
                                    dismiss()
                                }
                            }
                        }
                    }
                    .interactiveDismissDisabled()
                }
            }
        }
        .task {
            await loadContacts()
        }
    }
    
    private func moveToNextFriend() {
        if currentOnboardingIndex < onboardingContacts.count - 1 {
            withAnimation {
                currentOnboardingIndex += 1
            }
        } else {
            showingOnboarding = false
            dismiss()
        }
    }
    
    private func startBulkOnboarding() {
        onboardingContacts = contacts
            .filter { selectedContacts.contains($0.identifier) }
            .map { contact in
                (
                    name: "\(contact.givenName) \(contact.familyName)",
                    identifier: contact.identifier,
                    phoneNumber: contact.phoneNumbers.first?.value.stringValue,
                    email: contact.emailAddresses.first?.value as String?,
                    imageData: contact.thumbnailImageData,
                    city: contact.postalAddresses.first?.value.city
                )
            }
        currentOnboardingIndex = 0
        showingOnboarding = true
    }
    
    private var contactsList: some View {
        List(filteredContacts, id: \.identifier) { contact in
            let isSelected = selectedContacts.contains(contact.identifier)
            let isAlreadyImported = existingFriends.contains { $0.contactIdentifier == contact.identifier }
            
            Button {
                if !isAlreadyImported {
                    if selectedContacts.contains(contact.identifier) {
                        selectedContacts.remove(contact.identifier)
                    } else {
                        selectedContacts.insert(contact.identifier)
                    }
                }
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
                            .foregroundColor(isAlreadyImported ? AppColors.secondaryLabel : AppColors.label)
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
                    
                    Spacer()
                    
                    if isAlreadyImported {
                        Text("Imported")
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryLabel)
                    } else {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? AppColors.accent : AppColors.secondaryLabel)
                    }
                }
            }
            .disabled(isAlreadyImported)
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
        await MainActor.run {
            isLoading = true
        }
        let granted = await contactsManager.requestAccess()
        if granted {
            let fetchedContacts = await contactsManager.fetchContacts()
            await MainActor.run {
                contacts = fetchedContacts
            }
        }
        await MainActor.run {
            isLoading = false
        }
    }
    
    private func importSelectedContacts() {
        // First fetch all existing friends to check for duplicates
        let descriptor = FetchDescriptor<Friend>()
        guard let existingFriends = try? modelContext.fetch(descriptor) else { return }
        
        for contact in contacts where selectedContacts.contains(contact.identifier) {
            // Skip if this contact is already imported
            guard !existingFriends.contains(where: { $0.contactIdentifier == contact.identifier }) else { continue }
            
            let city = contact.postalAddresses.first?.value.city
            let friend = Friend(
                name: "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces),
                location: city,
                contactIdentifier: contact.identifier,
                phoneNumber: contact.phoneNumbers.first?.value.stringValue,
                email: contact.emailAddresses.first?.value as String?,
                photoData: contact.imageData
            )
            modelContext.insert(friend)
        }
        try? modelContext.save()
        dismiss()
    }
}

struct ContactPickerPreviewContainer: View {
    enum PreviewState {
        case loading
        case empty
        case withContacts
    }
    
    let state: PreviewState
    
    var body: some View {
        let schema = Schema([Friend.self, Tag.self, Hangout.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        
        ContactPickerView()
            .modelContainer(container)
            .onAppear {
                if state == .withContacts {
                    #if DEBUG
                    ContactsManager.shared.previewContacts = Self.mockContacts
                    #endif
                }
            }
    }
}

#if DEBUG
extension ContactPickerPreviewContainer {
    static func createMockContact(
        givenName: String,
        familyName: String,
        phoneNumber: String,
        city: String
    ) -> CNContact {
        let contact = CNMutableContact()
        contact.givenName = givenName
        contact.familyName = familyName
        
        // Add phone number
        let phoneNumberValue = CNPhoneNumber(stringValue: phoneNumber)
        contact.phoneNumbers = [CNLabeledValue(label: CNLabelHome, value: phoneNumberValue)]
        
        // Add address
        let address = CNMutablePostalAddress()
        address.city = city
        contact.postalAddresses = [CNLabeledValue(label: CNLabelHome, value: address)]
        
        return contact.copy() as! CNContact
    }
    
    static var mockContacts: [CNContact] {
        [
            createMockContact(
                givenName: "Emma",
                familyName: "Thompson",
                phoneNumber: "(415) 555-0123",
                city: "San Francisco"
            ),
            createMockContact(
                givenName: "James",
                familyName: "Wilson",
                phoneNumber: "(555) 123-4567",
                city: "Oakland"
            ),
            createMockContact(
                givenName: "Sarah",
                familyName: "Chen",
                phoneNumber: "(650) 555-0199",
                city: "Mountain View"
            ),
            createMockContact(
                givenName: "Alex",
                familyName: "Rodriguez",
                phoneNumber: "(510) 555-0145",
                city: "Berkeley"
            )
        ]
    }
}

#Preview("Loading State") {
    ContactPickerPreviewContainer(state: .loading)
}

#Preview("Empty State") {
    ContactPickerPreviewContainer(state: .empty)
}

#Preview("With Contacts") {
    ContactsManager.shared.previewContacts = ContactPickerPreviewContainer.mockContacts
    return ContactPickerPreviewContainer(state: .withContacts)
}
#endif 
