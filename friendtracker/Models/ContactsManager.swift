import Contacts
import SwiftUI

@MainActor
class ContactsManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationStatus: CNAuthorizationStatus = .notDetermined
    @Published private(set) var contacts: [CNContact] = []
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        isAuthorized = authorizationStatus == .authorized
        if isAuthorized {
            Task {
                await fetchContacts()
            }
        }
    }
    
    func requestAccess() {
        Task {
            let store = CNContactStore()
            do {
                let granted = try await store.requestAccess(for: .contacts)
                await MainActor.run {
                    self.isAuthorized = granted
                    self.checkAuthorizationStatus()
                }
            } catch {
                print("Error requesting contacts access: \(error)")
                await MainActor.run {
                    self.isAuthorized = false
                }
            }
        }
    }
    
    func fetchContacts() async {
        guard isAuthorized else { return }
        
        do {
            let fetchedContacts = try await withThrowingTaskGroup(of: [CNContact].self) { group in
                group.addTask(priority: .userInitiated) {
                    let store = CNContactStore()
                    let keys = [
                        CNContactGivenNameKey,
                        CNContactFamilyNameKey,
                        CNContactPhoneNumbersKey
                    ] as [CNKeyDescriptor]
                    let request = CNContactFetchRequest(keysToFetch: keys)
                    var contacts: [CNContact] = []
                    
                    try store.enumerateContacts(with: request) { contact, _ in
                        contacts.append(contact)
                    }
                    
                    return contacts.sorted {
                        let name1 = "\($0.givenName) \($0.familyName)"
                        let name2 = "\($1.givenName) \($1.familyName)"
                        return name1 < name2
                    }
                }
                
                var allContacts: [CNContact] = []
                for try await contacts in group {
                    allContacts.append(contentsOf: contacts)
                }
                return allContacts
            }
            
            self.contacts = fetchedContacts
        } catch {
            print("Error fetching contacts: \(error)")
            self.contacts = []
        }
    }
} 
