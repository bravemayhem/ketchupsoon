//
//  Tag.swift
//  friendtracker
//
//  Created by Amineh Beltran on 1/13/25.
//

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
        self.friends = []
    }
}

// MARK: - Predefined Tags
extension Tag {
    static let predefinedTags = [
        "local",
        "longdistance",
        "work",
        "family",
        "school",
        "neighbors"
    ]
    
    static func createPredefinedTag(_ name: String) -> Tag {
        Tag(name: name, isPredefined: true)
    }
}

// MARK: - Tag Management
extension Tag {
    static func createTag(name: String, friend: Friend, context: ModelContext) throws -> Tag {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Check for existing tag
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.name == normalizedName
            }
        )
        
        if let existingTag = try context.fetch(descriptor).first {
            if !friend.tags.contains(where: { $0.id == existingTag.id }) {
                friend.tags.append(existingTag)
                try context.save()
            }
            return existingTag
        }
        
        // Create new tag
        let tag = Tag(name: normalizedName)
        context.insert(tag)
        friend.tags.append(tag)
        try context.save()
        return tag
    }
    
    static func delete(_ tags: [Tag], context: ModelContext) throws {
        for tag in tags {
            // Remove tag from all friends
            for friend in tag.friends {
                friend.tags.removeAll(where: { $0.id == tag.id })
            }
            context.delete(tag)
        }
        try context.save()
    }
    
    static func toggleSelection(of tag: Tag, for friend: Friend, context: ModelContext) throws {
        if friend.tags.contains(where: { $0.id == tag.id }) {
            friend.tags.removeAll(where: { $0.id == tag.id })
        } else {
            friend.tags.append(tag)
        }
        try context.save()
    }
}


