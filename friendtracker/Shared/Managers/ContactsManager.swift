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
} 