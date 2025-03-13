import Foundation
import FirebaseAuth
import OSLog
import Combine

/// Represents different authentication states in the application
enum AuthState: Equatable {
    case notAuthenticated
    case authenticated(userID: String)
    case refreshing(userID: String)
    
    var userID: String? {
        switch self {
        case .notAuthenticated:
            return nil
        case .authenticated(let userID), .refreshing(let userID):
            return userID
        }
    }
    
    var isAuthenticated: Bool {
        switch self {
        case .notAuthenticated:
            return false
        case .authenticated, .refreshing:
            return true
        }
    }
}

/// Protocol for components that need to be notified of auth state changes
protocol AuthStateSubscriber: AnyObject {
    /// Called when the auth state changes
    func onAuthStateChanged(newState: AuthState, previousState: AuthState?)
}

/// Central service for managing and broadcasting authentication state
@MainActor
class AuthStateService: ObservableObject {
    // Singleton instance
    static let shared = AuthStateService()
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "AuthStateService")
    private var subscribers = NSHashTable<AnyObject>.weakObjects()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // State management
    @Published private(set) var currentState: AuthState = .notAuthenticated
    private var previousState: AuthState?
    
    // Debouncing
    private var lastStateChangeTime: Date?
    private let minimumTimeBetweenStateChanges: TimeInterval = 0.5 // 500ms
    
    // Operation queue
    private var pendingOperations = [() async -> Void]()
    private var isProcessingOperations = false
    
    // MARK: - Initialization
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Public Methods
    
    /// Register a component to receive auth state notifications
    func subscribe(_ subscriber: AuthStateSubscriber) {
        subscribers.add(subscriber)
        
        // Immediately notify new subscriber of current state
        subscriber.onAuthStateChanged(newState: currentState, previousState: nil)
        logger.debug("Subscribed new component to auth state changes")
    }
    
    /// Unregister a component from receiving auth state notifications
    func unsubscribe(_ subscriber: AuthStateSubscriber) {
        subscribers.remove(subscriber)
        logger.debug("Unsubscribed component from auth state changes")
    }
    
    /// Manually trigger a state refresh (e.g., after profile update)
    func refreshState() {
        if let userID = Auth.auth().currentUser?.uid {
            changeState(to: .refreshing(userID: userID))
            
            // Schedule a delayed change back to authenticated
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                if currentState.userID == userID {
                    changeState(to: .authenticated(userID: userID))
                }
            }
        }
    }
    
    /// Queue an operation to be executed after auth state is processed
    func queueOperation(_ operation: @escaping () async -> Void) {
        pendingOperations.append(operation)
        
        if !isProcessingOperations {
            Task {
                await processOperations()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAuthStateListener() {
        // Remove any existing listener
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
        
        // Set up a new listener
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let user = user {
                    // User is signed in
                    self.changeState(to: .authenticated(userID: user.uid))
                } else {
                    // User is signed out
                    self.changeState(to: .notAuthenticated)
                }
            }
        }
        
        logger.notice("Auth state listener set up")
    }
    
    private func changeState(to newState: AuthState) {
        // Check if we should debounce
        if let lastChange = lastStateChangeTime, 
           Date().timeIntervalSince(lastChange) < minimumTimeBetweenStateChanges,
           currentState.userID == newState.userID { // Only debounce if same user
            logger.debug("Debounced auth state change to \(String(describing: newState)) - too soon after last change")
            return
        }
        
        // Check if this is a no-op state change
        if currentState == newState {
            logger.debug("Ignored redundant auth state change - state already \(String(describing: newState))")
            return
        }
        
        // Update state
        previousState = currentState
        currentState = newState
        lastStateChangeTime = Date()
        
        // Log the state change
        if let userID = newState.userID {
            logger.notice("Auth state changed to \(String(describing: newState)) for user ID: \(userID)")
        } else {
            logger.notice("Auth state changed to not authenticated")
        }
        
        // Notify subscribers
        notifySubscribers()
        
        // Process any queued operations
        Task {
            await processOperations()
        }
    }
    
    private func notifySubscribers() {
        for case let subscriber as AuthStateSubscriber in subscribers.allObjects {
            subscriber.onAuthStateChanged(newState: currentState, previousState: previousState)
        }
    }
    
    private func processOperations() async {
        guard !isProcessingOperations else { return }
        
        isProcessingOperations = true
        
        while !pendingOperations.isEmpty {
            let operation = pendingOperations.removeFirst()
            await operation()
            
            // Add a small delay between operations
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        isProcessingOperations = false
    }
} 