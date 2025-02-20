import Contacts
import ContactsUI

@MainActor
class ContactsManager: ObservableObject {
    static let shared = ContactsManager()
    
    @Published var authorizationStatus: CNAuthorizationStatus = .notDetermined
    
    #if DEBUG
    var previewContacts: [CNContact]?
    #endif
    
    private let store = CNContactStore()
    
    // Public accessor for the store
    var contactStore: CNContactStore { store }
    
    // Centralized key descriptors
    static let baseKeys: [CNKeyDescriptor] = [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactImageDataKey as CNKeyDescriptor,
        CNContactThumbnailImageDataKey as CNKeyDescriptor,
        CNContactPostalAddressesKey as CNKeyDescriptor,
        CNContactIdentifierKey as CNKeyDescriptor
    ]
    
    private let keysToFetch: [CNKeyDescriptor] = baseKeys
    
    private init() {
        print("📱 ContactsManager: Initialized")
    }
    
    func requestAccess() async -> Bool {
        print("📱 ContactsManager: Requesting access")
        #if DEBUG
        if previewContacts != nil {
            print("📱 ContactsManager: Using preview contacts")
            return true
        }
        #endif
        
        do {
            let granted = try await store.requestAccess(for: .contacts)
            await MainActor.run {
                self.authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            }
            print("📱 ContactsManager: Access request result - granted: \(granted), status: \(self.authorizationStatus.rawValue)")
            return granted
        } catch {
            print("📱 ContactsManager: Error requesting contacts access: \(error)")
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
        print("📱 ContactsManager: Starting sync for friend: \(friend.name)")
        guard let contactIdentifier = friend.contactIdentifier else {
            print("📱 ContactsManager: No contact identifier for friend")
            return false
        }
        
        let capturedStore = await MainActor.run { self.store }
        let capturedKeysToFetch = await MainActor.run { self.keysToFetch }
        
        return await Task.detached(priority: .background) {
            do {
                print("📱 ContactsManager: Fetching contact for sync with identifier: \(contactIdentifier)")
                let predicate = CNContact.predicateForContacts(withIdentifiers: [contactIdentifier])
                let contacts = try capturedStore.unifiedContacts(matching: predicate, keysToFetch: capturedKeysToFetch)
                
                guard let contact = contacts.first else {
                    print("📱 ContactsManager: No contact found for sync")
                    return false
                }
                
                print("📱 ContactsManager: Found contact, updating friend information")
                // Update friend's information on the main thread
                await MainActor.run {
                    // Only update contact-sourced information
                    friend.name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                    // Get the first phone number if available
                    friend.phoneNumber = contact.phoneNumbers.first?.value.stringValue
                    
                    // Handle email addresses
                    let emailAddresses = contact.emailAddresses.map { $0.value as String }
                    if !emailAddresses.isEmpty {
                        friend.email = emailAddresses[0]
                        friend.additionalEmails = emailAddresses.count > 1 ? Array(emailAddresses.dropFirst()) : []
                    } else {
                        friend.additionalEmails = []
                    }
                    
                    friend.location = contact.postalAddresses.first?.value.city
                    friend.photoData = contact.thumbnailImageData
                    
                    // Do not modify user preferences during sync
                    // friend.needsToConnectFlag = false  // Removed
                    // friend.calendarIntegrationEnabled = false  // Removed
                    // friend.calendarVisibilityPreference = .none  // Removed
                    // friend.createdAt = Date()  // Removed
                }
                
                print("📱 ContactsManager: Successfully updated friend information")
                return true
            } catch {
                print("📱 ContactsManager: Error syncing contact info: \(error)")
                return false
            }
        }.value
    }
    
    // New method to get contact for viewing/editing
    func getContactViewController(for identifier: String) async throws -> CNContact {
        print("📱 ContactsManager: Getting contact for identifier: \(identifier)")
        let predicate = CNContact.predicateForContacts(withIdentifiers: [identifier])
        let keys = ContactsManager.baseKeys + [CNContactViewController.descriptorForRequiredKeys()]
        
        do {
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
            guard let contact = contacts.first else {
                print("📱 ContactsManager: No contact found for identifier: \(identifier)")
                throw ContactError.contactNotFound
            }
            print("📱 ContactsManager: Successfully retrieved contact: \(contact.givenName) \(contact.familyName)")
            return contact
        } catch {
            print("📱 ContactsManager: Error fetching contact: \(error)")
            throw error
        }
    }
    
    // New method to handle contact changes after editing
    func handleContactChange(for friend: Friend) async -> Bool {
        print("📱 ContactsManager: Handling contact change for friend: \(friend.name)")
        let result = await syncContactInfo(for: friend)
        print("📱 ContactsManager: Contact sync result: \(result)")
        return result
    }
    
    enum ContactError: Error {
        case contactNotFound
        case updateFailed(Error)
        case accessDenied
        
        var localizedDescription: String {
            switch self {
            case .contactNotFound:
                return "Contact not found in address book"
            case .updateFailed(let error):
                return "Failed to update contact: \(error.localizedDescription)"
            case .accessDenied:
                return "Access to contacts was denied"
            }
        }
    }
} 