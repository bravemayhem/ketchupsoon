import Foundation
import SwiftUI
import SwiftData
import Contacts

@Model
final class Friend: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var lastSeen: Date?
    var location: String?
    var contactIdentifier: String?
    var needsToConnectFlag: Bool
    var phoneNumber: String?
    var photoData: Data?
    var catchUpFrequency: CatchUpFrequency?
    var calendarIntegrationEnabled: Bool
    @Attribute(.externalStorage) var calendarVisibilityPreference: CalendarVisibilityPreference
    @Relationship(deleteRule: .cascade) var hangouts: [Hangout]
    // Cache for frequently accessed computed properties
    @Transient private var _lastSeenTextCache: (Date, String)?
        // Lazy loading for hangouts
    @Transient private var _scheduledHangoutsCache: [Hangout]?

    
    init(name: String,
         lastSeen: Date? = nil,
         location: String? = nil,
         contactIdentifier: String? = nil,
         needsToConnectFlag: Bool = false,
         phoneNumber: String? = nil,
         photoData: Data? = nil,
         catchUpFrequency: CatchUpFrequency? = nil) {
        self.id = UUID()
        self.name = name
        self.lastSeen = lastSeen
        self.location = location
        self.contactIdentifier = contactIdentifier
        self.phoneNumber = phoneNumber
        self.photoData = photoData
        self.catchUpFrequency = catchUpFrequency
        self.needsToConnectFlag = needsToConnectFlag
        self.calendarIntegrationEnabled = false
        self.calendarVisibilityPreference = .none
        self.hangouts = []
        self._lastSeenTextCache = nil
        self._scheduledHangoutsCache = nil
    }
    
    var lastSeenText: String {
        if let cache = _lastSeenTextCache,
           let lastSeen = self.lastSeen,
           cache.0 == lastSeen {
            return cache.1
        }
        
        guard let lastSeen = lastSeen else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let result = formatter.localizedString(for: lastSeen, relativeTo: Date())
        _lastSeenTextCache = (lastSeen, result)
        return result
    }
    
    var scheduledHangouts: [Hangout] {
        if let cached = _scheduledHangoutsCache {
            return cached
        }
        let result = hangouts.filter { $0.isScheduled }
        _scheduledHangoutsCache = result
        return result
    }
    
    var nextConnectDate: Date? {
        guard let lastSeen = lastSeen else { return nil }
        let days = catchUpFrequency?.days ?? 30  // Default to monthly if no frequency set
        return Calendar.current.date(byAdding: .day, value: days, to: lastSeen)
    }
    
    func updateLastSeen(to date: Date? = nil) {
        lastSeen = date ?? Date()
        invalidateCaches()  // Reset caches since we're updating lastSeen
    }
}

// MARK: - Calendar Types
extension Friend {
    enum CalendarType: String, Codable {
        case apple
        case google
    }
    
    enum CalendarVisibilityPreference: String, Codable {
        case none
        case busyTime
        case full
    }
    
    struct ConnectedCalendar: Identifiable, Hashable, Codable {
        let id: String
        let type: CalendarType
        let name: String
        var isEnabled: Bool
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: ConnectedCalendar, rhs: ConnectedCalendar) -> Bool {
            lhs.id == rhs.id
        }
    }
}

// MARK: - Batch Operations
extension Friend {
    static func batchUpdate(_ friends: [Friend], with context: ModelContext) {
        // Use direct insert
        for friend in friends {
            context.insert(friend)
        }
        // Save changes if needed
        try? context.save()
    }
    
    static func batchDelete(_ friends: [Friend], with context: ModelContext) {
        // Use direct delete
        for friend in friends {
            context.delete(friend)
        }
        // Save changes if needed
        try? context.save()
    }
}

// MARK: - Performance Optimizations
extension Friend {
    // Reset caches when data changes
    func invalidateCaches() {
        _lastSeenTextCache = nil
        _scheduledHangoutsCache = nil
    }
}
