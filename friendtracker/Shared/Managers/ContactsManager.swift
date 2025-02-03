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
    
    // New method to update contact emails
    nonisolated func updateContactEmails(identifier: String, primaryEmail: String?, additionalEmails: [String]) async throws {
        let capturedStore = await MainActor.run { self.store }
        
        return try await Task.detached(priority: .userInitiated) {
            let predicate = CNContact.predicateForContacts(withIdentifiers: [identifier])
            let keysToFetch = [CNContactEmailAddressesKey] as [CNKeyDescriptor]
            
            let contacts = try capturedStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            guard let contact = contacts.first else {
                throw ContactError.contactNotFound
            }
            
            let mutableContact = contact.mutableCopy() as! CNMutableContact
            
            // Clear existing email addresses
            mutableContact.emailAddresses.removeAll()
            
            // Add primary email first if it exists
            if let primaryEmail = primaryEmail {
                let emailAddress = CNLabeledValue(label: CNLabelHome, value: primaryEmail as NSString)
                mutableContact.emailAddresses.append(emailAddress)
            }
            
            // Add additional emails
            for email in additionalEmails {
                let emailAddress = CNLabeledValue(label: CNLabelOther, value: email as NSString)
                mutableContact.emailAddresses.append(emailAddress)
            }
            
            // Save the changes
            let saveRequest = CNSaveRequest()
            saveRequest.update(mutableContact)
            
            do {
                try capturedStore.execute(saveRequest)
            } catch {
                print("Error updating contact: \(error)")
                throw ContactError.updateFailed(error)
            }
        }.value
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
                    
                    // Handle email addresses
                    let emailAddresses = contact.emailAddresses.map { $0.value as String }
                    if !emailAddresses.isEmpty {
                        // Set primary email
                        friend.email = emailAddresses[0]
                        // Set additional emails
                        if emailAddresses.count > 1 {
                            friend.additionalEmails = Array(emailAddresses.dropFirst())
                        } else {
                            friend.additionalEmails = []
                        }
                    }
                    
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
    
    enum ContactError: Error {
        case contactNotFound
        case updateFailed(Error)
        
        var localizedDescription: String {
            switch self {
            case .contactNotFound:
                return "Contact not found in address book"
            case .updateFailed(let error):
                return "Failed to update contact: \(error.localizedDescription)"
            }
        }
    }
} 