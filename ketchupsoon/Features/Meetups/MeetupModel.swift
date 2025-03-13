import Foundation
import SwiftUI
import SwiftData
import FirebaseFirestore
import CoreData

// A model to represent a Meetup with SwiftData and Firebase compatibility
@Model
final class MeetupModel: Identifiable {
    @Attribute(.unique) var id: String
    var title: String
    var date: Date
    var location: String
    var activityType: Int
    @Attribute(.transformable(by: ArrayTransformer.self))
    var participants: [String]
    var notes: String?
    var isAiGenerated: Bool
    
    // Firebase sync fields
    var creatorID: String
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool = false
    
    init(
        id: String = UUID().uuidString,
        title: String,
        date: Date,
        location: String,
        activityType: Int,
        participants: [String],
        notes: String? = nil,
        isAiGenerated: Bool = false,
        creatorID: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.location = location
        self.activityType = activityType
        self.participants = participants
        self.notes = notes
        self.isAiGenerated = isAiGenerated
        self.creatorID = creatorID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
    }
    
    // Activity type as an extension to preserve the same usage pattern
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
    // Static samples for preview and testing
    static var samples: [MeetupModel] = [
        MeetupModel(
            title: "Coffee with Alex",
            date: Date().addingTimeInterval(86400), // Tomorrow            
            location: "Starbucks",
            activityType: ActivityType.coffee.rawValue,
            participants: ["alex", "jordan"],
            creatorID: "sample_user"
        ),
        MeetupModel(
            title: "Lunch with Sarah",
            date: Date().addingTimeInterval(172800), // Day after tomorrow
            location: "The Bistro",
            activityType: ActivityType.food.rawValue,
            participants: ["sarah", "alex", "jordan"],
            creatorID: "sample_user"
        ),
        MeetupModel(
            title: "Game night",
            date: Date().addingTimeInterval(345600), // 4 days from now
            location: "Jamie's house",
            activityType: ActivityType.games.rawValue,
            participants: ["alex", "jordan", "sarah", "jamie"],
            creatorID: "sample_user"
        ),
        MeetupModel(
            title: "Hiking trip",
            date: Date().addingTimeInterval(604800), // 1 week from now            
            location: "Mountains",
            activityType: ActivityType.outdoors.rawValue,
            participants: ["sarah", "jordan"],
            notes: "Remember to bring water and snacks!",
            creatorID: "sample_user"
        )
    ]
}

// Extension for Firestore conversion
extension MeetupModel {
    // Convert to Firestore data
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "date": Timestamp(date: date),
            "location": location,
            "activityType": activityType,
            "participants": participants,
            "notes": notes as Any,
            "isAiGenerated": isAiGenerated,
            "creatorID": creatorID,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "isDeleted": isDeleted
        ]
    }
    
    // Create from Firestore document
    static func fromFirestore(documentData: [String: Any], documentID: String) -> MeetupModel? {
        guard 
            let title = documentData["title"] as? String,
            let timestamp = documentData["date"] as? Timestamp,
            let location = documentData["location"] as? String,
            let activityType = documentData["activityType"] as? Int,
            let participants = documentData["participants"] as? [String],
            let creatorID = documentData["creatorID"] as? String,
            let createdTimestamp = documentData["createdAt"] as? Timestamp,
            let updatedTimestamp = documentData["updatedAt"] as? Timestamp,
            let isDeleted = documentData["isDeleted"] as? Bool
        else {
            return nil
        }
        
        let notes = documentData["notes"] as? String
        let isAiGenerated = documentData["isAiGenerated"] as? Bool ?? false
        
        return MeetupModel(
            id: documentData["id"] as? String ?? documentID,
            title: title,
            date: timestamp.dateValue(),
            location: location,
            activityType: activityType,
            participants: participants,
            notes: notes,
            isAiGenerated: isAiGenerated,
            creatorID: creatorID,
            createdAt: createdTimestamp.dateValue(),
            updatedAt: updatedTimestamp.dateValue(),
            isDeleted: isDeleted
        )
    }
    
    // Get activity type enum
    var activityTypeEnum: ActivityType {
        return ActivityType(rawValue: activityType) ?? .coffee
    }
}

// Extension for date formatting
extension MeetupModel {
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
