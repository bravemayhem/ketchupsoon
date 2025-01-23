import Contacts

@MainActor
class ContactsManager: ObservableObject {
    static let shared = ContactsManager()
    
    @Published var authorizationStatus: CNAuthorizationStatus = .notDetermined
    
    #if DEBUG
    var previewContacts: [CNContact]?
    #endif
    
    private let store = CNContactStore()
    private let keysToFetch = [
        CNContactGivenNameKey,
        CNContactFamilyNameKey,
        CNContactPhoneNumbersKey,
        CNContactEmailAddressesKey,
        CNContactImageDataKey,
        CNContactThumbnailImageDataKey,
        CNContactPostalAddressesKey,
        CNContactIdentifierKey
    ] as [CNKeyDescriptor]
    
    private init() {}
    
    func requestAccess() async -> Bool {
        #if DEBUG
        if previewContacts != nil {
            return true
        }
        #endif
        
        do {
            let granted = try await store.requestAccess(for: .contacts)
            await MainActor.run {
                self.authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            }
            return granted
        } catch {
            print("Error requesting contacts access: \(error)")
            return false
        }
    }
    
    nonisolated func fetchContacts() async -> [CNContact] {
        #if DEBUG
        if let previewContacts = await MainActor.run(body: { self.previewContacts }) {
            return previewContacts
        }
        #endif
        
        // Initialize variables before capture
        let capturedStore = await MainActor.run { self.store }
        let capturedKeysToFetch = await MainActor.run { self.keysToFetch }
        
        return await Task.detached(priority: .background) {
            do {
                let request = CNContactFetchRequest(keysToFetch: capturedKeysToFetch)
                var contacts: [CNContact] = []
                try capturedStore.enumerateContacts(with: request) { contact, _ in
                    contacts.append(contact)
                }
                return contacts
            } catch {
                print("Error fetching contacts: \(error)")
                return []
            }
        }.value
    }
    
    // Function to sync a friend's information with their contact
    nonisolated func syncContactInfo(for friend: Friend) async -> Bool {
        guard let contactIdentifier = friend.contactIdentifier else { return false }
        
        let capturedStore = await MainActor.run { self.store }
        let capturedKeysToFetch = await MainActor.run { self.keysToFetch }
        
        return await Task.detached(priority: .background) {
            do {
                let predicate = CNContact.predicateForContacts(withIdentifiers: [contactIdentifier])
                let contacts = try capturedStore.unifiedContacts(matching: predicate, keysToFetch: capturedKeysToFetch)
                
                guard let contact = contacts.first else { return false }
                
                // Update friend's information on the main thread
                await MainActor.run {
                    friend.name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                    friend.phoneNumber = contact.phoneNumbers.first?.value.stringValue
                    friend.email = contact.emailAddresses.first?.value as String?
                    friend.location = contact.postalAddresses.first?.value.city
                    friend.photoData = contact.thumbnailImageData
                }
                
                return true
            } catch {
                print("Error syncing contact info: \(error)")
                return false
            }
        }.value
    }
} 