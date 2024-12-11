import Contacts
import SwiftUI

class ContactsManager: ObservableObject {
    @Published var isAuthorized = false
    
    func requestAccess() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }
    
    func fetchContacts() -> [CNContact] {
        let store = CNContactStore()
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey
        ] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var contacts = [CNContact]()
        
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