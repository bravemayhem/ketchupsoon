import Foundation
import SwiftUI

// A model to represent a Meetup
struct Meetup: Identifiable {
    var id = UUID()
    var title: String
    var date: Date
    var location: String
    var activityType: ActivityType
    var participants: [String]
    var notes: String?
    var isAiGenerated: Bool = false
    
    enum ActivityType: Int, CaseIterable {
        case coffee = 0
        case food = 1
        case outdoors = 2
        case games = 3
        
        var emoji: String {
            switch self {
            case .coffee: return "☕️"
            case .food: return "🍽️"
            case .outdoors: return "🥾"
            case .games: return "🎮"
            }
        }
        
        var name: String {
            switch self {
            case .coffee: return "coffee"
            case .food: return "food"
            case .outdoors: return "outdoors"
            case .games: return "games"
            }
        }
        
        var gradient: LinearGradient {
            switch self {
            case .coffee:
                return AppColors.accentGradient1
            case .food:
                return AppColors.accentGradient2
            case .outdoors:
                return AppColors.accentGradient4
            case .games:
                return AppColors.accentGradient3
            }
        }
    }
    
    // Sample data for previews and testing
    static var samples: [Meetup] = [
        Meetup(
            title: "Coffee with Alex",
            date: Date().addingTimeInterval(86400), // Tomorrow
            location: "Blue Bottle Coffee",
            activityType: .coffee,
            participants: ["alex", "jordan"]
        ),
        Meetup(
            title: "Lunch with Sarah",
            date: Date().addingTimeInterval(172800), // Day after tomorrow
            location: "Zazie",
            activityType: .food,
            participants: ["sarah", "alex", "jordan"]
        ),
        Meetup(
            title: "Game night",
            date: Date().addingTimeInterval(345600), // 4 days from now
            location: "Alex's place",
            activityType: .games,
            participants: ["alex", "jordan", "sarah", "jamie"]
        ),
        Meetup(
            title: "Hiking trip",
            date: Date().addingTimeInterval(604800), // 1 week from now
            location: "Mount Tam",
            activityType: .outdoors,
            participants: ["sarah", "jordan"],
            notes: "Remember to bring water and snacks!"
        )
    ]
}

// Extension for date formatting
extension Meetup {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var relativeDateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d"
            return formatter.string(from: date)
        }
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    var dateTimeString: String {
        return "\(relativeDateString) • \(timeString)"
    }
} 