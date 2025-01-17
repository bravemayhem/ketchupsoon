import Contacts
import SwiftUI

class ContactsManager: ObservableObject {
    static let shared = ContactsManager()
    
    @Published var authorizationStatus: CNAuthorizationStatus = .notDetermined
    
    func requestAccess() async -> Bool {
        return await withCheckedContinuation { continuation in
            CNContactStore().requestAccess(for: .contacts) { granted, error in
                if let error = error {
                    print("Error requesting contacts access: \(error)")
                }
                DispatchQueue.main.async {
                    self.authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
                }
                continuation.resume(returning: granted)
            }
        }
    }
    
    func fetchContacts() async -> [CNContact] {
        let store = CNContactStore()
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey,
            CNContactImageDataKey,
            CNContactThumbnailImageDataKey,
            CNContactPostalAddressesKey
        ] as [CNKeyDescriptor]
        
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        var contacts: [CNContact] = []
        
        do {
            try store.enumerateContacts(with: request) { contact, stop in
                contacts.append(contact)
            }
        } catch {
            print("Error fetching contacts: \(error)")
        }
        
        return contacts
    }
} 
