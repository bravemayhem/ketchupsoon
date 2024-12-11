import Foundation

struct Friend: Identifiable {
    let id = UUID()
    let name: String
    let frequency: String
    let lastHangoutWeeks: Int
    let phoneNumber: String?
    var isOverdue: Bool {
        switch frequency {
        case "Weekly check-in":
            return lastHangoutWeeks > 1
        case "Monthly catch-up":
            return lastHangoutWeeks > 4
        case "Quarterly catch-up":
            return lastHangoutWeeks > 12
        default:
            return false
        }
    }
} 