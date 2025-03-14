import Firebase
import FirebaseFirestore
import Contacts
import FirebaseAuth
import OSLog

// MARK: - Firebase Sync Service - Contacts Extension
extension FirebaseSyncService {
    
    /// Check which phone numbers from the provided list match KetchupSoon users
    /// - Parameter phoneNumbers: Array of normalized phone numbers to check
    /// - Returns: Dictionary mapping phone numbers to UserModel for matches
    func checkContactsOnApp(phoneNumbers: [String]) async throws -> [String: UserModel] {
        guard !phoneNumbers.isEmpty else { return [:] }
        
        // Get current user ID for filtering at the query level
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            Logger(subsystem: "com.ketchupsoon", category: "FirebaseSyncService").error("No current user found in Auth when checking contacts")
            throw NSError(domain: "FirebaseSyncService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        Logger(subsystem: "com.ketchupsoon", category: "FirebaseSyncService").info("Filtering contacts query with current user ID: \(currentUserId)")
        
        // Create batches of phone numbers to avoid hitting query limits
        // Firestore has a limit of 10 items for 'in' array queries
        let batchSize = 10
        let batches = stride(from: 0, to: phoneNumbers.count, by: batchSize).map {
            Array(phoneNumbers[$0..<min($0 + batchSize, phoneNumbers.count)])
        }
        
        var matchedUsers: [String: UserModel] = [:]
        
        // Process each batch
        for batch in batches {
            let db = Firestore.firestore()
            
            // Add a filter to exclude the current user in the query itself
            let query = db.collection("users")
                .whereField("phoneNumber", in: batch)
                .whereField("id", isNotEqualTo: currentUserId)  // Server-side filtering
            
            let snapshot = try await query.getDocuments()
            
            Logger(subsystem: "com.ketchupsoon", category: "FirebaseSyncService").info("Batch query found \(snapshot.documents.count) matches (excluding current user)")
            
            for document in snapshot.documents {
                let userData = document.data()
                
                // Ensure we have a phone number to use as key
                guard let phoneNumber = userData["phoneNumber"] as? String else {
                    continue
                }
                
                // Create user model from document
                if let user = try? document.data(as: UserModel.self) {
                    matchedUsers[phoneNumber] = user
                }
            }
        }
        
        return matchedUsers
    }
    
    /// Helper method to normalize phone numbers for consistent matching
    /// Removes non-numeric characters and ensures proper formatting
    func normalizePhoneNumber(_ phoneNumber: String) -> String {
        // Strip all non-numeric characters
        let numericOnly = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Simple normalization - in a production app, you might want more sophisticated
        // handling of country codes, etc.
        return numericOnly
    }
} 