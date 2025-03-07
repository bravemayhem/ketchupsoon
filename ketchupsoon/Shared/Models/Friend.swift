import Foundation
import SwiftUI
import SwiftData
import Contacts
import OSLog

@Model
final class Friend: Identifiable {
    private static let logger = Logger(subsystem: "com.ketchupsoon", category: "FriendModel")
    
    // Required properties
    @Attribute(.unique) var id: UUID
    var name: String
    var _needsToConnectFlag: Bool
    var needsToConnectFlag: Bool {
        get { _needsToConnectFlag }
        set {
            Self.logger.info("🔄 Changing needsToConnectFlag for \(self.name) from \(self._needsToConnectFlag) to \(newValue)")
            Self.logger.info("🔄 Change initiated from:")
            for (index, symbol) in Thread.callStackSymbols.enumerated() {
                Self.logger.info("   [\(index)] \(symbol)")
                // Stop after 5 frames to keep logs manageable
                if index >= 5 { break }
            }
            
            // Protection against automatic changes during contact sync.
            // The wishlist status is a user preference that should only be modified
            // through explicit user actions (like tapping the wishlist button).
            // This check prevents the flag from being modified during contact
            // information synchronization.
            let callStack = Thread.callStackSymbols.joined()
            if callStack.contains("ContactsManagerC15syncContactInfo") {
                Self.logger.warning("⚠️ Attempted to change needsToConnectFlag during contact sync - ignoring change")
                return // Don't allow the change during contact sync
            }
            
            if let contactId = self.contactIdentifier {
                Self.logger.info("ℹ️ Friend is linked to contact: \(contactId)")
            }
            _needsToConnectFlag = newValue
        }
    }
    var calendarIntegrationEnabled: Bool
    var calendarVisibilityPreference: CalendarVisibilityPreference
    var createdAt: Date
    
    // Optional properties
    var lastSeen: Date?
    var location: String?
    var contactIdentifier: String?
    var firebaseUserId: String? // Firebase user ID for linked Ketchupsoon users
    private var _phoneNumber: String?
    var phoneNumber: String? {
        get { _phoneNumber }
        set { _phoneNumber = newValue }
    }
    var email: String?  // Primary email
    var photoData: Data?
    var catchUpFrequency: CatchUpFrequency?
    var birthday: Date? // Birthday property
    
    /// Additional email addresses for manually added friends.
    /// For friends linked to system contacts (contactIdentifier != nil),
    /// this property is not used - instead, emails are managed through
    /// the Contacts framework.
    @Attribute(.transformable(by: EmailArrayValueTransformer.self))
    var additionalEmails: [String]
    
    // Relationships
    @Relationship(deleteRule: .cascade) var hangouts: [Hangout]
    @Relationship(deleteRule: .nullify) var tags: [Tag]
    @Relationship(deleteRule: .cascade) var milestones: [Milestone]
    
    // Cache properties
    @Transient private var _lastSeenTextCache: (Date, String)?
    @Transient private var _scheduledHangoutsCache: [Hangout]?
    @Transient private var _upcomingMilestonesCache: [Milestone]?
    
    /// Returns all email addresses for this friend.
    /// For contact-linked friends, this will trigger a contact sync.
    /// For manual friends, this returns the primary email and additional emails.
    var allEmails: [String] {
        // If this is a contact-linked friend, we don't use the local storage
        if contactIdentifier != nil {
            // Return an empty array if we can't access contacts
            // The UI layer should handle contact sync and updates
            return []
        }
        
        // For manual friends, combine primary and additional emails
        return [email].compactMap { $0 } + additionalEmails
    }
    
    var initials: String {
        name.components(separatedBy: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
    }
    
    init(id: UUID = UUID(),
         name: String,
         lastSeen: Date? = nil,
         location: String? = nil,
         contactIdentifier: String? = nil,
         needsToConnectFlag: Bool = false,
         phoneNumber: String? = nil,
         email: String? = nil,
         additionalEmails: [String] = [],
         photoData: Data? = nil,
         catchUpFrequency: CatchUpFrequency? = nil,
         birthday: Date? = nil,
         calendarIntegrationEnabled: Bool = false,
         calendarVisibilityPreference: CalendarVisibilityPreference = .none,
         firebaseUserId: String? = nil,
         createdAt: Date = Date()) {
        
        // Initialize required properties
        self.id = id
        self.name = name
        self._needsToConnectFlag = needsToConnectFlag
        self.calendarIntegrationEnabled = calendarIntegrationEnabled
        self.calendarVisibilityPreference = calendarVisibilityPreference
        self.createdAt = createdAt
        
        // Initialize optional properties
        self.lastSeen = lastSeen
        self.location = location
        self.contactIdentifier = contactIdentifier
        self._phoneNumber = phoneNumber
        self.email = email
        self.photoData = photoData
        self.catchUpFrequency = catchUpFrequency
        self.birthday = birthday
        self.firebaseUserId = firebaseUserId
        
        // Initialize arrays with empty defaults
        self.additionalEmails = additionalEmails
        self.hangouts = []
        self.tags = []
        self.milestones = []
        
        // Initialize caches
        self._lastSeenTextCache = nil
        self._scheduledHangoutsCache = nil
        self._upcomingMilestonesCache = nil
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
        guard let frequency = catchUpFrequency else { return nil }
        
        // Use lastSeen if available, otherwise use createdAt
        let baseDate = lastSeen ?? createdAt
        return Calendar.current.date(byAdding: .day, value: frequency.days, to: baseDate)
    }
    
    // Function to get the number of days until the next birthday
    var daysUntilNextBirthday: Int? {
        guard let birthday = birthday else { return nil }
        
        let calendar = Calendar.current
        
        // Get today's date with time components stripped
        let today = calendar.startOfDay(for: Date())
        
        // Get components for the birthday
        let birthdayComponents = calendar.dateComponents([.month, .day], from: birthday)
        
        // Create a date for this year's birthday
        var nextBirthdayComponents = DateComponents()
        nextBirthdayComponents.year = calendar.component(.year, from: today)
        nextBirthdayComponents.month = birthdayComponents.month
        nextBirthdayComponents.day = birthdayComponents.day
        
        guard let nextBirthday = calendar.date(from: nextBirthdayComponents) else { return nil }
        
        // If this year's birthday has passed, use next year's birthday
        let nextBirthdayDate = nextBirthday < today 
            ? calendar.date(byAdding: .year, value: 1, to: nextBirthday) ?? nextBirthday
            : nextBirthday
        
        // Calculate days between today and the next birthday
        let days = calendar.dateComponents([.day], from: today, to: nextBirthdayDate).day
        return days
    }
    
    // Helper to format birthday for display
    var formattedBirthday: String? {
        guard let birthday = birthday else { return nil }
        return DateFormatter.birthday.string(from: birthday)
    }
    
    func updateLastSeen(to date: Date? = nil) {
        lastSeen = date ?? Date()
        invalidateCaches()  // Reset caches since we're updating lastSeen
    }
    
    // MARK: - Milestone Management
    
    var upcomingMilestones: [Milestone] {
        if let cached = _upcomingMilestonesCache {
            return cached
        }
        let result = milestones.filter { $0.isUpcoming && !$0.isArchived }
        _upcomingMilestonesCache = result
        return result
    }
    
    var recentMilestones: [Milestone] {
        milestones.filter { $0.isRecent && !$0.isArchived }
    }
    
    func addMilestone(type: MilestoneType, title: String, description: String? = nil, date: Date) {
        let milestone = Milestone(
            friendId: self.id,
            friendName: self.name,
            type: type,
            title: title,
            milestoneDescription: description,
            date: date
        )
        milestones.append(milestone)
    }
    
    // Creates a birthday milestone if a birthday exists
    func createBirthdayMilestone() {
        guard let birthday = birthday else { return }
        
        // Calculate next birthday date
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let birthdayComponents = calendar.dateComponents([.month, .day], from: birthday)
        
        var nextBirthdayComponents = DateComponents()
        nextBirthdayComponents.year = calendar.component(.year, from: today)
        nextBirthdayComponents.month = birthdayComponents.month
        nextBirthdayComponents.day = birthdayComponents.day
        
        guard let nextBirthday = calendar.date(from: nextBirthdayComponents) else { return }
        
        // If the birthday has already occurred this year, set it for next year
        let nextBirthdayDate = nextBirthday < today 
            ? calendar.date(byAdding: .year, value: 1, to: nextBirthday)! 
            : nextBirthday
        
        // Create the milestone
        addMilestone(
            type: .birthday,
            title: "Birthday",
            description: "Celebrating \(name)'s birthday!",
            date: nextBirthdayDate
        )
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
        _upcomingMilestonesCache = nil
    }
}


