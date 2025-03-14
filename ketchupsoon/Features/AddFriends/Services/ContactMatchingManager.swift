import Foundation
import Contacts
import Combine
import SwiftUI
import OSLog
import FirebaseAuth

/// Manager class that handles matching device contacts with KetchupSoon users
class ContactMatchingManager: ObservableObject {
    // MARK: - Properties
    
    /// Singleton instance for app-wide access
    static let shared = ContactMatchingManager()
    
    /// Firebase sync service for user queries
    private var firebaseSyncService: FirebaseSyncService?
    
    /// Published properties for UI binding
    @Published var matchedContacts: [MatchedContact] = []
    @Published var nonMatchedContacts: [CNContact] = []
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    @Published var hasLoadedContacts: Bool = false
    
    /// Logger for debugging
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "ContactMatchingManager")
    
    // MARK: - Initialization
    
    /// Primary initializer with service dependency
    init(firebaseSyncService: FirebaseSyncService? = nil) {
        self.firebaseSyncService = firebaseSyncService
    }
    
    /// Set the Firebase sync service
    func setFirebaseSyncService(_ service: FirebaseSyncService) {
        self.firebaseSyncService = service
    }
    
    // MARK: - Public Methods
    
    /// Load and match contacts from the device with KetchupSoon users
    func loadAndMatchContacts() async {
        if isLoading { return }
        
        // Ensure we have a Firebase service
        guard let firebaseSyncService = self.firebaseSyncService else {
            await MainActor.run {
                self.error = ContactMatchingError.serviceUnavailable
                self.logger.error("Attempted to match contacts without a Firebase service")
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // 1. Request access to contacts
            let accessGranted = await ContactsManager.shared.requestAccess()
            
            guard accessGranted else {
                throw ContactMatchingError.accessDenied
            }
            
            // 2. Fetch contacts from device
            let deviceContacts = await ContactsManager.shared.fetchContacts()
            
            // 3. Extract and normalize phone numbers
            var phoneNumbersMap: [String: CNContact] = [:]
            
            for contact in deviceContacts {
                for phoneNumber in contact.phoneNumbers {
                    let normalizedNumber = await firebaseSyncService.normalizePhoneNumber(phoneNumber.value.stringValue)
                    if !normalizedNumber.isEmpty {
                        phoneNumbersMap[normalizedNumber] = contact
                    }
                }
            }
            
            // 4. Check which phone numbers match KetchupSoon users
            let matchedUsers = try await firebaseSyncService.checkContactsOnApp(phoneNumbers: Array(phoneNumbersMap.keys))
            
            // Get current user for secondary filtering (as a safety measure)
            guard let currentUser = Auth.auth().currentUser else {
                logger.error("No current user found in Auth")
                throw ContactMatchingError.unknown
            }
            
            let currentUserId = currentUser.uid
            logger.info("⭐️ Current user ID: \(currentUserId)")
            
            // Debug all matched users before additional filtering
            logger.info("🔍 Firebase returned \(matchedUsers.count) matches (already filtered at server level)")
            for (phone, user) in matchedUsers {
                logger.info("Match from Firebase: Phone: \(phone), User ID: \(user.id), Name: \(user.name ?? "unknown")")
            }
            
            // 5. Apply secondary client-side filtering as a safety measure
            var matched: [MatchedContact] = []
            var nonMatched: [CNContact] = []
            
            let processedContactIds = Set<String>()
            
            // Secondary check to ensure current user is filtered out
            let filteredUsers = matchedUsers.filter { phoneNumber, user in
                let isCurrentUser = user.id == currentUserId
                
                if isCurrentUser {
                    logger.warning("⚠️ CURRENT USER FOUND IN MATCHES DESPITE SERVER FILTERING - ID: \(user.id), Phone: \(phoneNumber)")
                }
                
                return !isCurrentUser
            }
            
            if filteredUsers.count < matchedUsers.count {
                logger.warning("🚫 Had to filter \(matchedUsers.count - filteredUsers.count) additional matches client-side. Server filtering may not be working correctly.")
            } else {
                logger.info("✅ No additional filtering needed - server filtering working correctly")
            }
            
            // Add filtered users to the matched list
            for (phoneNumber, user) in filteredUsers {
                if let contact = phoneNumbersMap[phoneNumber] {
                    logger.info("➕ Adding contact: \(contact.givenName) \(contact.familyName) with ID: \(user.id)")
                    matched.append(MatchedContact(contact: contact, user: user))
                }
            }
            
            // 6. Identify non-matched contacts
            for contact in deviceContacts {
                let contactId = contact.identifier
                if !processedContactIds.contains(contactId) {
                    // Check if this contact was matched by any of its phone numbers
                    let wasMatched = matched.contains { $0.contact.identifier == contactId }
                    if !wasMatched {
                        nonMatched.append(contact)
                    }
                }
            }
            
            // Create local constants to safely capture for concurrency
            let finalMatched = matched
            let finalNonMatched = nonMatched
            
            // 7. Update UI
            await MainActor.run {
                self.matchedContacts = finalMatched
                self.nonMatchedContacts = finalNonMatched
                self.isLoading = false
                self.hasLoadedContacts = true
                
                logger.info("Found \(finalMatched.count) contacts on KetchupSoon out of \(deviceContacts.count) total contacts")
            }
            
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
                
                logger.error("Error matching contacts: \(error.localizedDescription)")
            }
        }
    }
    
    /// Clear all cached contact data
    func clearContactData() {
        matchedContacts = []
        nonMatchedContacts = []
        hasLoadedContacts = false
    }
}

// MARK: - Supporting Types

/// Represents a device contact that matches a KetchupSoon user
struct MatchedContact: Identifiable {
    let id: String
    let contact: CNContact
    let user: UserModel
    
    init(contact: CNContact, user: UserModel) {
        self.id = contact.identifier
        self.contact = contact
        self.user = user
    }
    
    var displayName: String {
        let firstName = contact.givenName
        let lastName = contact.familyName
        
        if firstName.isEmpty && lastName.isEmpty {
            return user.name ?? "Unknown"
        } else if firstName.isEmpty {
            return lastName
        } else if lastName.isEmpty {
            return firstName
        } else {
            return "\(firstName) \(lastName)"
        }
    }
    
    var initials: String {
        let firstName = contact.givenName
        let lastName = contact.familyName
        
        var initials = ""
        
        if !firstName.isEmpty, let firstInitial = firstName.first {
            initials.append(firstInitial)
        }
        
        if !lastName.isEmpty, let lastInitial = lastName.first {
            initials.append(lastInitial)
        }
        
        return initials.uppercased()
    }
}

/// Custom errors for contact matching
enum ContactMatchingError: Error {
    case accessDenied
    case networkError
    case unknown
    case serviceUnavailable
}

extension ContactMatchingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Contact access was denied. Please enable contact access in Settings."
        case .networkError:
            return "A network error occurred while checking for contacts."
        case .unknown:
            return "An unknown error occurred while matching contacts."
        case .serviceUnavailable:
            return "The Firebase service is not available."
        }
    }
} 