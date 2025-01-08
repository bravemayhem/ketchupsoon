import Foundation

enum CatchUpFrequency: String, CaseIterable, Codable, Hashable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semiannually = "Every 6 months"
    case yearly = "Yearly"
    
    var days: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .semiannually: return 180
        case .yearly: return 365
        }
    }
    
    var displayText: String {
        return self.rawValue
    }
} 