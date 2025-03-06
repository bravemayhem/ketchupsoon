import Foundation
import SwiftUI
import SwiftData

enum MilestoneType: String, Codable, CaseIterable {
    case birthday = "Birthday"
    case graduation = "Graduation" 
    case newJob = "New Job"
    case anniversary = "Anniversary"
    case other = "Celebration"
    
    var color: Color {
        switch self {
        case .birthday: return Color(hex: "FF6B6B")
        case .graduation: return Color(hex: "6B66FF") 
        case .newJob: return Color(hex: "00F5A0")
        case .anniversary: return Color(hex: "FF9F4A")
        case .other: return AppColors.accent
        }
    }
    
    var iconName: String {
        switch self {
        case .birthday: return "gift"
        case .graduation: return "graduationcap"
        case .newJob: return "briefcase"
        case .anniversary: return "heart.circle"
        case .other: return "party.popper"
        }
    }
}

// Explicitly use the SwiftData @Model attribute with fully qualified name
@SwiftData.Model
final class Milestone {
    var id: UUID
    var friendId: UUID?
    var friendName: String
    var type: MilestoneType
    var title: String
    var milestoneDescription: String?
    var date: Date
    var createdAt: Date
    var isArchived: Bool
    
    init(id: UUID = UUID(), 
         friendId: UUID? = nil,
         friendName: String, 
         type: MilestoneType, 
         title: String, 
         milestoneDescription: String? = nil, 
         date: Date, 
         createdAt: Date = Date(),
         isArchived: Bool = false) {
        self.id = id
        self.friendId = friendId
        self.friendName = friendName
        self.type = type
        self.title = title
        self.milestoneDescription = milestoneDescription
        self.date = date
        self.createdAt = createdAt
        self.isArchived = isArchived
    }
    
    var timeframe: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var isUpcoming: Bool {
        return date > Date()
    }
    
    var isRecent: Bool {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        return date <= Date() && date > oneMonthAgo
    }
}

// Extension to make MilestoneType work with SwiftData
extension MilestoneType: PersistableEnum {}

// Protocol to allow enum to be stored in SwiftData
protocol PersistableEnum: Codable {
    var rawValue: String { get }
} 