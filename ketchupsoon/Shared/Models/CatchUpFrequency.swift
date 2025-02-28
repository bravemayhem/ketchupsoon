import Foundation

enum CatchUpFrequency: String, CaseIterable, Codable, Hashable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Every 2 weeks"
    case monthly = "Monthly"
    case bimonthly = "Every 2 months"
    case quarterly = "Every 3 months"
    case semiannually = "Every 6 months"
    case yearly = "Yearly"
    
    var days: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .bimonthly: return 60
        case .quarterly: return 90
        case .semiannually: return 180
        case .yearly: return 365
        }
    }
    
    var displayText: String {
        return self.rawValue
    }
} 
