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
    
    /// Find a contact that is likely to be the user's own contact card
    func findMyContactCard() async -> CNContact? {
        self.isLoading = true
        defer { self.isLoading = false }
        
        // Check if we have access
        guard authorizationStatus == .authorized else {
            logger.warning("Attempting to access contacts without permission")
            return nil
        }
        
        // Keys to fetch - use descriptors for required keys for better formatting
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactImageDataKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactImageDataAvailableKey as CNKeyDescriptor
        ]
        
        do {
            // Try to match using profile info - method is maintained for possible future use with friends
            if let userProfile = UserProfileManager.shared.currentUserProfile {
                
                // Try to match by email
                if let userEmail = userProfile.email, !userEmail.isEmpty {
                    let emailPredicate = CNContact.predicateForContacts(matchingEmailAddress: userEmail)
                    let emailMatches = try store.unifiedContacts(matching: emailPredicate, keysToFetch: keysToFetch)
                    
                    if let match = emailMatches.first {
                        logger.info("Found contact matching user email: \(userEmail)")
                        return match
                    }
                }
                
                // Try to match by phone number
                if let userPhone = userProfile.phoneNumber, !userPhone.isEmpty {
                    // Clean the phone number to just digits
                    let cleanPhone = userPhone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                    
                    // Get a non-isolated copy of our dependencies
                    let capturedStore = store
                    let capturedCleanPhone = cleanPhone
                    
                    // Perform the phone number search on a background thread
                    let matchingContacts = try await Task.detached(priority: .userInitiated) {
                        var results: [CNContact] = []
                        
                        // Create and configure the fetch request
                        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
                        
                        try capturedStore.enumerateContacts(with: fetchRequest) { contact, stop in
                            for phoneNumber in contact.phoneNumbers {
                                // Clean the contact's phone number to just digits for comparison
                                let contactPhone = phoneNumber.value.stringValue.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                                
                                // Check if the phone number contains or is contained by the user's phone
                                if contactPhone.contains(capturedCleanPhone) || capturedCleanPhone.contains(contactPhone) {
                                    results.append(contact)
                                    stop.pointee = true
                                    break
                                }
                            }
                        }
                        
                        return results
                    }.value
                    
                    if let match = matchingContacts.first {
                        logger.info("Found contact matching user phone: \(userPhone)")
                        return match
                    }
                }
            }
            
            // No matching contact found
            logger.info("No matching contact found for current user profile.")
            return nil
            
        } catch {
            await MainActor.run {
                self.error = error
                self.logger.error("Error finding contact: \(error.localizedDescription)")
            }
            return nil
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
                    
                    // Get birthday if available
                    if let birthdayComponents = contact.birthday {
                        // Create a date from the birthday components
                        // Note: We set year to current year if not provided to create a valid date
                        let calendar = Calendar.current
                        var components = birthdayComponents
                        if components.year == nil {
                            components.year = calendar.component(.year, from: Date())
                        }
                        friend.birthday = calendar.date(from: components)
                    }
                    
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