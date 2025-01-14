import Foundation
import SwiftData

@Model
final class Tag: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var isPredefined: Bool
    @Relationship(inverse: \Friend.tags) var friends: [Friend]
    
    init(name: String, isPredefined: Bool = false) {
        self.id = UUID()
        self.name = name.lowercased()
        self.isPredefined = isPredefined
        self.friends = []  // Initialize empty array
    }
}

// MARK: - Predefined Tags
extension Tag {
    static let predefinedTags = [
        "closefriends",
        "work",
        "family",
        "school",
        "neighbors"
    ]
    
    static func createPredefinedTag(_ name: String) -> Tag {
        Tag(name: name, isPredefined: true)
    }
}