import Foundation
import OSLog

/// Defines the priority of a Firebase operation
enum OperationPriority: Int, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    static func < (lhs: OperationPriority, rhs: OperationPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Defines logging verbosity levels
enum LogVerbosity: Int, Comparable {
    case none = 0     // No logging
    case errors = 1   // Only errors
    case important = 2 // Important operations
    case verbose = 3  // All operations
    case debug = 4    // Debug-level with extra details
    
    static func < (lhs: LogVerbosity, rhs: LogVerbosity) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// A Firebase operation that can be executed and tracked
struct FirebaseOperation: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let key: String
    let priority: OperationPriority
    let minInterval: TimeInterval
    let operation: () async throws -> Void
    let errorHandler: ((Error) -> Void)?
    
    static func == (lhs: FirebaseOperation, rhs: FirebaseOperation) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Service that coordinates Firebase operations to prevent excessive API calls
@MainActor
class FirebaseOperationCoordinator: ObservableObject {
    // Singleton instance
    static let shared = FirebaseOperationCoordinator()
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "FirebaseOperations")
    
    // Operation state
    private var operations = [FirebaseOperation]()
    private var isProcessing = false
    
    // Debouncing
    private var lastOperationTimes = [String: Date]()
    
    // Configuration
    private(set) var logVerbosity: LogVerbosity = .important
    
    // Stats for monitoring
    @Published private(set) var totalOperationsProcessed = 0
    @Published private(set) var totalOperationsSkipped = 0
    @Published private(set) var lastOperationTime: Date?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Set the log verbosity level
    func setLogVerbosity(_ level: LogVerbosity) {
        logVerbosity = level
        logger.notice("Log verbosity set to \(String(describing: level))")
    }
    
    // MARK: - Operation Management
    
    /// Schedule a Firebase operation to be executed
    func scheduleOperation(
        name: String,
        key: String,
        priority: OperationPriority = .normal,
        minInterval: TimeInterval = 2.0,
        operation: @escaping () async throws -> Void,
        errorHandler: ((Error) -> Void)? = nil
    ) {
        let newOperation = FirebaseOperation(
            name: name,
            key: key,
            priority: priority,
            minInterval: minInterval,
            operation: operation,
            errorHandler: errorHandler
        )
        
        // Check if we should debounce this operation
        if shouldDebounce(operation: newOperation) {
            if logVerbosity >= .verbose {
                logger.debug("Debounced operation: \(name) (key: \(key))")
            }
            totalOperationsSkipped += 1
            return
        }
        
        // Add to queue and process
        operations.append(newOperation)
        
        // Sort by priority
        operations.sort { $0.priority > $1.priority }
        
        if !isProcessing {
            Task {
                await processOperations()
            }
        }
    }
    
    /// Cancel all pending operations matching the given key
    func cancelOperations(withKey key: String) {
        operations.removeAll { $0.key == key }
        if logVerbosity >= .verbose {
            logger.debug("Cancelled operations with key: \(key)")
        }
    }
    
    // MARK: - Private Methods
    
    private func shouldDebounce(operation: FirebaseOperation) -> Bool {
        // Get the last time this operation was performed
        if let lastTime = lastOperationTimes[operation.key] {
            let elapsed = Date().timeIntervalSince(lastTime)
            // If the elapsed time is less than the minimum interval, debounce
            return elapsed < operation.minInterval
        }
        return false
    }
    
    private func processOperations() async {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        while !operations.isEmpty {
            let operation = operations.removeFirst()
            
            do {
                // Log the operation
                if logVerbosity >= .verbose {
                    logger.debug("Executing operation: \(operation.name) (priority: \(operation.priority.rawValue))")
                }
                
                // Execute the operation
                try await operation.operation()
                
                // Update last operation time for debouncing
                lastOperationTimes[operation.key] = Date()
                lastOperationTime = Date()
                totalOperationsProcessed += 1
                
                if logVerbosity >= .important {
                    logger.notice("Completed operation: \(operation.name)")
                }
            } catch {
                if logVerbosity >= .errors {
                    logger.error("Failed operation: \(operation.name) - \(error.localizedDescription)")
                }
                
                // Call the error handler if provided
                operation.errorHandler?(error)
            }
            
            // Add a small delay between operations
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        isProcessing = false
    }
} 