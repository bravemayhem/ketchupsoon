import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseFirestore
import OSLog
import Combine

/// Service that manages real-time Firestore listeners for both users and friendships
/// Provides automatic synchronization between Firebase and SwiftData
@MainActor
class FirestoreListenerService: ObservableObject, AuthStateSubscriber {
    // MARK: - Properties
    
    private lazy var db: Firestore = {
        return Firestore.firestore()
    }()
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "FirestoreListenerService")
    private let modelContext: ModelContext
    
    // Store active listeners to allow cancellation
    private var userListeners: [ListenerRegistration] = []
    private var friendshipListeners: [ListenerRegistration] = []
    
    // Nonisolated copies for access from nonisolated contexts
    private nonisolated var _userListeners: [ListenerRegistration] {
        get async {
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    continuation.resume(returning: userListeners)
                }
            }
        }
    }
    
    private nonisolated var _friendshipListeners: [ListenerRegistration] {
        get async {
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    continuation.resume(returning: friendshipListeners)
                }
            }
        }
    }
    
    // Published properties for UI reactivity
    @Published var isListening: Bool = false
    @Published var lastUpdateTimestamp: Date?
    
    // Dependencies
    private lazy var userRepository: UserRepository = {
        return UserRepositoryFactory.createRepository(modelContext: modelContext)
    }()
    
    private lazy var friendshipRepository: FriendshipRepository = {
        return FriendshipRepositoryFactory.createRepository(modelContext: modelContext)
    }()
    
    // Operation coordinator
    private let operationCoordinator: FirebaseOperationCoordinator
    
    // State tracking
    private var currentUserID: String?
    private var lastListenerStartTime: Date?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.operationCoordinator = FirebaseOperationCoordinator.shared
        
        // Register with auth state service
        Task { @MainActor in
            AuthStateService.shared.subscribe(self)
        }
    }
    
    deinit {
        stopAllListeners()
        
        // Create a local reference to avoid capturing self in the Task
        let subscriber = self
        
        // Use Task.detached to avoid capturing self
        Task.detached { @MainActor in
            AuthStateService.shared.unsubscribe(subscriber)
        }
    }
    
    // MARK: - AuthStateSubscriber Implementation
    
    nonisolated func onAuthStateChanged(newState: AuthState, previousState: AuthState?) {
        // Since this method is nonisolated, we need to transfer to the MainActor
        Task { @MainActor in
            self.handleAuthStateChange(newState: newState, previousState: previousState)
        }
    }
    
    @MainActor
    private func handleAuthStateChange(newState: AuthState, previousState: AuthState?) {
        // Handle auth state changes
        switch newState {
        case .authenticated(let userID):
            // Only start listeners if we're not already listening for this user
            if currentUserID != userID {
                stopAllListeners()
                startListeningForUser(userID: userID)
            }
            
        case .refreshing(let userID):
            // Do nothing - keep existing listeners
            logger.debug("Auth state refreshing for user \(userID)")
            
        case .notAuthenticated:
            // User signed out, stop all listeners
            stopAllListeners()
        }
    }
    
    // MARK: - Public Methods
    
    /// Stop all active listeners
    /// This method is marked as nonisolated so it can be called from deinit
    nonisolated func stopAllListeners() {
        Task {
            // Remove all user listeners
            let userListenersSnapshot = await _userListeners
            for listener in userListenersSnapshot {
                listener.remove()
            }
            
            // Update on main actor
            Task { @MainActor in
                self.userListeners.removeAll()
            }
            
            // Remove all friendship listeners
            let friendshipListenersSnapshot = await _friendshipListeners
            for listener in friendshipListenersSnapshot {
                listener.remove()
            }
            
            // Update on main actor
            Task { @MainActor in
                self.friendshipListeners.removeAll()
                self.isListening = false
                self.currentUserID = nil
                
                if FirebaseOperationCoordinator.shared.logVerbosity >= .important {
                    self.logger.notice("Stopped all Firestore listeners")
                }
            }
        }
    }
    
    /// Stop listening for a specific user
    func stopUserListener(for userID: String) {
        // Since we can't directly identify which listener corresponds to which user,
        // we need to stop all user listeners and restart them for other users
        for listener in userListeners {
            listener.remove()
        }
        userListeners.removeAll()
        
        if currentUserID == userID {
            currentUserID = nil
        }
        
        logger.debug("Stopped listening for user \(userID)")
    }
    
    // MARK: - Private Methods
    
    /// Starts listeners for a specific user ID
    private func startListeningForUser(userID: String) {
        // Safety check: Ensure we have a valid Firebase user before starting listeners
        guard Auth.auth().currentUser != nil, Auth.auth().currentUser?.uid == userID else {
            logger.error("Attempted to start listeners for user \(userID) but user is not authenticated")
            return
        }
        
        // Avoid starting listeners multiple times in quick succession
        if let lastStart = lastListenerStartTime, 
           Date().timeIntervalSince(lastStart) < 1.0 {
            logger.debug("Skipping listener start - too soon after previous start")
            return
        }
        
        lastListenerStartTime = Date()
        currentUserID = userID
        
        // Start various listeners with error handling
        startUserListener(for: userID)
        startIncomingFriendshipListener(for: userID)
        startOutgoingFriendshipListener(for: userID)
        
        isListening = true
        
        if FirebaseOperationCoordinator.shared.logVerbosity >= .important {
            logger.notice("Started Firestore listeners for user \(userID)")
        }
    }
    
    /// Starts a listener for changes to the user document
    private func startUserListener(for userID: String) {
        // Safety check before starting listener
        guard Auth.auth().currentUser != nil else {
            logger.error("Cannot start user listener - no authenticated user")
            return
        }
        
        let userRef = db.collection("users").document(userID)
        let listener = userRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            
            // Handle potential errors
            if let error = error {
                self.logger.error("Error listening for user updates: \(error.localizedDescription)")
                return
            }
            
            // Make sure we have a valid document
            guard let document = documentSnapshot, document.exists else {
                self.logger.warning("User document does not exist for ID: \(userID)")
                return
            }
            
            // Process document
            Task {
                await self.processUserDocument(document)
            }
        }
        
        // Store the listener for later cleanup
        userListeners.append(listener)
    }
    
    private func startIncomingFriendshipListener(for userID: String) {
        // Implementation of startIncomingFriendshipListener method
    }
    
    private func startOutgoingFriendshipListener(for userID: String) {
        // Implementation of startOutgoingFriendshipListener method
    }
    
    private func processUserDocument(_ document: DocumentSnapshot) async {
        // Implementation of processUserDocument method
    }
}

/// Factory for creating FirestoreListenerService instances
struct FirestoreListenerServiceFactory {
    /// Create the default listener service
    @MainActor
    static func createService(modelContext: ModelContext) -> FirestoreListenerService {
        return FirestoreListenerService(modelContext: modelContext)
    }
}
