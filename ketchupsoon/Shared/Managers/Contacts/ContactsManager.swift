import Contacts
import ContactsUI
import OSLog

@MainActor
class ContactsManager: ObservableObject {
    static let shared = ContactsManager()
    
    @Published var authorizationStatus: CNAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var error: Error?
    
#if DEBUG
    var previewContacts: [CNContact]?
#endif
    
    private let store = CNContactStore()
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "ContactsManager")
    
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
        CNContactIdentifierKey as CNKeyDescriptor,
        CNContactBirthdayKey as CNKeyDescriptor,
        CNContactImageDataAvailableKey as CNKeyDescriptor,
        CNContactTypeKey as CNKeyDescriptor
    ]
    
    private let keysToFetch: [CNKeyDescriptor] = baseKeys
    
    private init() {
        print("📱 ContactsManager: Initialized")
        // Get current authorization status
        self.authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }
    
    func requestAccess() async -> Bool {
        print("📱 ContactsManager: Requesting access")
        self.isLoading = true
        defer { self.isLoading = false }
        
#if DEBUG
        if previewContacts != nil {
            print("📱 ContactsManager: Using preview contacts")
            return true
        }
#endif
        
        // If already authorized, return true
        if authorizationStatus == .authorized {
            return true
        }
        
        do {
            let granted = try await store.requestAccess(for: .contacts)
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
            }
            print("📱 ContactsManager: Access request result - granted: \(granted), status: \(self.authorizationStatus.rawValue)")
            return granted
        } catch {
            await MainActor.run {
                self.error = error
                self.logger.error("Error requesting contacts access: \(error.localizedDescription)")
            }
            print("📱 ContactsManager: Error requesting contacts access: \(error)")
            return false
        }
    }
    
    
    
    /// Extract specific profile information from a contact (name, birthday, phone number)
    func extractProfileInfo(from contact: CNContact) -> [String: Any] {
        var profileInfo: [String: Any] = [:]
        
        // Extract name using CNContactFormatter for better formatting
        let formattedName = CNContactFormatter.string(from: contact, style: .fullName)
        if let name = formattedName, !name.isEmpty {
            profileInfo["name"] = name
        } else {
            // Fallback to our manual name concatenation if formatter fails
            let firstName = contact.givenName
            let lastName = contact.familyName
            if !firstName.isEmpty || !lastName.isEmpty {
                let fullName = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
                profileInfo["name"] = fullName
            }
        }
        
        // Extract phone number - prioritizing mobile numbers
        if !contact.phoneNumbers.isEmpty {
            // First look for mobile numbers
            let mobileNumbers = contact.phoneNumbers.filter {
                $0.label == CNLabelPhoneNumberMobile ||
                $0.label == "_$!<Mobile>!$_" // Old style label
            }
            
            if let mobileNumber = mobileNumbers.first {
                profileInfo["phoneNumber"] = mobileNumber.value.stringValue
            } else {
                // If no mobile number, just use the first number
                profileInfo["phoneNumber"] = contact.phoneNumbers.first?.value.stringValue
            }
        }
        
        // Extract birthday
        if let birthdayComponents = contact.birthday {
            // Create a properly formatted string or use the components directly
            if let month = birthdayComponents.month, let day = birthdayComponents.day {
                let calendar = Calendar.current
                var components = DateComponents()
                components.day = day
                components.month = month
                
                // Use the year if available, otherwise use current year
                if let year = birthdayComponents.year {
                    components.year = year
                } else {
                    // For display purposes only - when year is not specified
                    components.year = calendar.component(.year, from: Date())
                }
                
                if let birthdayDate = calendar.date(from: components) {
                    profileInfo["birthday"] = birthdayDate
                    
                    // Also include components for cases where year might be missing
                    profileInfo["birthdayComponents"] = birthdayComponents
                }
            }
        }
        
        // Debugging info
        let nameForLog = profileInfo["name"] as? String ?? "Unknown Name"
        let keysFound = profileInfo.keys.joined(separator: ", ")
        logger.info("Extracted profile info for \(nameForLog): \(keysFound)")
        
        return profileInfo
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
    
