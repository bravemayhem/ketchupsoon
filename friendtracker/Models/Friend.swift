import Foundation
import SwiftUI
import SwiftData
import Contacts

@Model
final class Friend {
    @Attribute(.unique) var id: UUID
    var name: String
    var lastSeen: Date?
    var location: String?
    var contactIdentifier: String?
    var needsToConnectFlag: Bool
    var phoneNumber: String?
    var photoData: Data?
    @Attribute(.externalStorage) var catchUpFrequency: CatchUpFrequency?
    var customCatchUpDays: Int?
    var calendarIntegrationEnabled: Bool
    @Attribute(.externalStorage) var calendarVisibilityPreference: CalendarVisibilityPreference
    @Relationship(deleteRule: .cascade) var hangouts: [Hangout]
    
    init(name: String,
         lastSeen: Date? = nil,
         location: String? = nil,
         contactIdentifier: String? = nil,
         needsToConnectFlag: Bool = false,
         phoneNumber: String? = nil,
         photoData: Data? = nil,
         catchUpFrequency: CatchUpFrequency? = .monthly) {
        self.id = UUID()
        self.name = name
        self.lastSeen = lastSeen
        self.location = location
        self.contactIdentifier = contactIdentifier
        self.phoneNumber = phoneNumber
        self.photoData = photoData
        self.catchUpFrequency = catchUpFrequency
        self.customCatchUpDays = nil
        self.needsToConnectFlag = needsToConnectFlag
        self.calendarIntegrationEnabled = false
        self.calendarVisibilityPreference = .none
        self.hangouts = []
    }
    
    var lastSeenText: String {
        guard let lastSeen = lastSeen else {
            return "Never"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastSeen, relativeTo: Date())
    }
    
    var scheduledHangouts: [Hangout] {
        return hangouts.filter { $0.isScheduled }
    }
    
    var nextConnectDate: Date? {
        guard let lastSeen = lastSeen else { return nil }
        let days = customCatchUpDays ?? (catchUpFrequency?.days ?? 30) // // provides a default value  
        return Calendar.current.date(byAdding: .day, value: days, to: lastSeen)
    }
    
    func updateLastSeen() {
        lastSeen = Date()
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
