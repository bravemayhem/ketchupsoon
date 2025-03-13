import Foundation
import OSLog

/// Central service for managing logging configuration
@MainActor
class LoggingService {
    // Singleton instance
    static let shared = LoggingService()
    
    // MARK: - Properties
    
    // Global logger
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "LoggingService")
    
    // Default log levels by category
    private var logLevelsByCategory: [String: LogVerbosity] = [
        "default": .important,
        "FirebaseUserRepository": .important,
        "FirestoreListenerService": .important,
        "FirebaseSyncService": .important,
        "FirebaseOperations": .important,
        "AuthStateService": .important
    ]
    
    // MARK: - Initialization
    
    private init() {
        // Set initial log levels
        #if DEBUG
        // In debug builds, set more verbose logging by default
        setGlobalLogLevel(.verbose)
        #else
        // In release builds, be more conservative
        setGlobalLogLevel(.important)
        #endif
        
        logger.notice("LoggingService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Set the log level for a specific category
    func setLogLevel(_ level: LogVerbosity, forCategory category: String) {
        logLevelsByCategory[category] = level
        logger.notice("Set log level for '\(category)' to \(String(describing: level))")
    }
    
    /// Set the global log level for all categories
    func setGlobalLogLevel(_ level: LogVerbosity) {
        // Set for known categories
        for category in logLevelsByCategory.keys {
            logLevelsByCategory[category] = level
        }
        
        // Update operation coordinator
        FirebaseOperationCoordinator.shared.setLogVerbosity(level)
        
        logger.notice("Set global log level to \(String(describing: level))")
    }
    
    /// Get the log level for a specific category
    func logLevel(forCategory category: String) -> LogVerbosity {
        return logLevelsByCategory[category] ?? logLevelsByCategory["default"] ?? .important
    }
    
    /// Enable debug level logging for all categories
    func enableDebugLogging() {
        setGlobalLogLevel(.debug)
    }
    
    /// Disable all logging except errors
    func disableVerboseLogging() {
        setGlobalLogLevel(.errors)
    }
} 