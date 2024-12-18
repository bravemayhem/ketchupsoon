import Foundation
import SwiftUI
import SwiftData
import Contacts

enum FriendLocation: String, Codable {
    case local = "Local"
    case remote = "Remote"
}

enum CatchUpFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Every 2 Weeks"
    case monthly = "Monthly"
    case quarterly = "Every 3 Months"
    case custom = "Custom"
    
    var days: Int {
        switch self {
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .custom: return 30 // Default for custom
        }
    }
}

#if DEBUG
class PerformanceLogger {
    static let shared = PerformanceLogger()
    private var startTimes: [String: CFAbsoluteTime] = [:]
    
    func start(_ operation: String) {
        startTimes[operation] = CFAbsoluteTimeGetCurrent()
    }
    
    func end(_ operation: String) {
        guard let startTime = startTimes[operation] else { return }
        let endTime = CFAbsoluteTimeGetCurrent()
        let timeElapsed = endTime - startTime
        print("⏱️ Performance: \(operation) took \(timeElapsed * 1000)ms")
        startTimes[operation] = nil
    }
}

func debugLog(_ message: String) {
    print("🔍 Debug: \(message)")
}
#endif

@Model
@preconcurrency
final class Friend {
    @Attribute(.unique) var id: UUID
    var name: String
    var lastSeen: Date
    var location: String
    var contactIdentifier: String?
    var phoneNumber: String?
    var photoData: Data?
    var needsToConnectFlag: Bool
    var catchUpFrequency: String?
    var customCatchUpDays: Int?
    var nextConnectDate: Date?  // Cache the next connect date
    @Relationship(deleteRule: .cascade) var hangouts: [Hangout]
    
    init(
        id: UUID = UUID(),
        name: String,
        lastSeen: Date = Date(),
        location: String = FriendLocation.local.rawValue,
        contactIdentifier: String? = nil,
        phoneNumber: String? = nil,
        photoData: Data? = nil,
        needsToConnectFlag: Bool = false,
        catchUpFrequency: String? = nil,
        customCatchUpDays: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.lastSeen = lastSeen
        self.location = location
        self.contactIdentifier = contactIdentifier
        self.phoneNumber = phoneNumber
        self.photoData = photoData
        self.needsToConnectFlag = needsToConnectFlag
        self.catchUpFrequency = catchUpFrequency
        self.customCatchUpDays = customCatchUpDays
        self.hangouts = []
        self.updateNextConnectDate()
    }
    
    private func updateNextConnectDate() {
        #if DEBUG
        PerformanceLogger.shared.start("updateNextConnectDate")
        debugLog("Updating next connect date for \(name)")
        #endif
        
        guard let frequencyString = catchUpFrequency,
              let frequency = CatchUpFrequency(rawValue: frequencyString) else {
            nextConnectDate = nil
            #if DEBUG
            debugLog("No frequency set for \(name)")
            PerformanceLogger.shared.end("updateNextConnectDate")
            #endif
            return
        }
        
        let daysToWait = customCatchUpDays ?? frequency.days
        
        // Get the target date (last seen + frequency days)
        let targetDate = Calendar.current.date(byAdding: .day, value: daysToWait, to: lastSeen) ?? Date()
        
        // Get date 3 weeks before target
        nextConnectDate = Calendar.current.date(byAdding: .day, value: -21, to: targetDate)
        
        #if DEBUG
        debugLog("Next connect date for \(name) set to \(nextConnectDate?.description ?? "nil")")
        PerformanceLogger.shared.end("updateNextConnectDate")
        #endif
    }
    
    var needsToConnect: Bool {
        if needsToConnectFlag {
            return true
        }
        
        guard let nextConnect = nextConnectDate else {
            return false
        }
        
        return Date() >= nextConnect
    }
    
    // Cache the formatted date string
    private var _lastSeenText: String?
    private var _lastSeenDate: Date?
    
    var lastSeenText: String {
        #if DEBUG
        PerformanceLogger.shared.start("lastSeenText")
        #endif
        
        if _lastSeenDate == lastSeen, let cached = _lastSeenText {
            #if DEBUG
            debugLog("Using cached lastSeenText for \(name)")
            PerformanceLogger.shared.end("lastSeenText")
            #endif
            return cached
        }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month, .weekOfYear, .day], from: lastSeen, to: now)
        
        let result: String
        if let years = components.year, years > 1 {
            result = "Please update last seen"
        } else if let months = components.month, months > 0 {
            result = "\(months) month\(months == 1 ? "" : "s") ago"
        } else if let weeks = components.weekOfYear, weeks > 0 {
            result = "\(weeks) week\(weeks == 1 ? "" : "s") ago"
        } else if let days = components.day, days > 0 {
            result = "\(days) day\(days == 1 ? "" : "s") ago"
        } else {
            result = "Today"
        }
        
        _lastSeenText = result
        _lastSeenDate = lastSeen
        
        #if DEBUG
        debugLog("Generated new lastSeenText for \(name): \(result)")
        PerformanceLogger.shared.end("lastSeenText")
        #endif
        
        return result
    }
    
    // Update the next connect date when relevant properties change
    func updateFrequency(_ newFrequency: String?) {
        #if DEBUG
        debugLog("Updating frequency for \(name) to \(newFrequency ?? "nil")")
        PerformanceLogger.shared.start("updateFrequency")
        #endif
        
        catchUpFrequency = newFrequency
        updateNextConnectDate()
        
        #if DEBUG
        PerformanceLogger.shared.end("updateFrequency")
        #endif
    }
    
    func updateCustomDays(_ days: Int?) {
        #if DEBUG
        debugLog("Updating custom days for \(name) to \(days?.description ?? "nil")")
        PerformanceLogger.shared.start("updateCustomDays")
        #endif
        
        customCatchUpDays = days
        updateNextConnectDate()
        
        #if DEBUG
        PerformanceLogger.shared.end("updateCustomDays")
        #endif
    }
    
    func updateLastSeen(_ date: Date) {
        #if DEBUG
        debugLog("Updating lastSeen for \(name) to \(date)")
        PerformanceLogger.shared.start("updateLastSeen")
        #endif
        
        lastSeen = date
        _lastSeenText = nil  // Invalidate cache
        _lastSeenDate = nil
        updateNextConnectDate()
        
        #if DEBUG
        PerformanceLogger.shared.end("updateLastSeen")
        #endif
    }
    
    var scheduledHangouts: [Hangout] {
        return hangouts
            .filter { $0.isScheduled && $0.date > Date() }
            .sorted { $0.date < $1.date }
    }
    
    var profileImage: Image? {
        guard let data = photoData,
              let uiImage = UIImage(data: data) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
    
    // Calendar Integration Properties
    var calendarIntegrationEnabled: Bool = false
    var calendarVisibilityPreference: CalendarVisibility = .busyTime
    var connectedCalendars: [ConnectedCalendar] = []
    
    enum CalendarVisibility: String, Codable {
        case none
        case busyTime
        case fullDetails
    }
    
    struct ConnectedCalendar: Codable, Identifiable {
        var id: String
        var type: CalendarType
        var name: String
        var isEnabled: Bool
    }
    
    enum CalendarType: String, Codable {
        case apple
        case google
    }
}