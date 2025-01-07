import Foundation

enum CatchUpFrequency: String, CaseIterable, Codable {
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    case custom = "Custom"
    
    var days: Int {
        switch self {
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .yearly: return 365
        case .custom: return 30 // Default value, actual value should be taken from Friend.customCatchUpDays
        }
    }
} 