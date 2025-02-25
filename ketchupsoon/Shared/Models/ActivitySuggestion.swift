import Foundation

struct ActivitySuggestion: Identifiable {
    let id = UUID()
    let title: String
    let category: ActivityCategory
    let duration: TimeInterval
    let weatherDependent: Bool
}

enum ActivityCategory {
    case general, dinner, outdoor
    
    var icon: String {
        switch self {
        case .general: return "star.fill"
        case .dinner: return "fork.knife"
        case .outdoor: return "sun.max.fill"
        }
    }
} 