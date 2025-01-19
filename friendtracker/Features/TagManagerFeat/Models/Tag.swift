//Model & Business Logic for Tags
//  Tag.swift
//  friendtracker
//
//  Created by Amineh Beltran on 1/13/25.
//

import Foundation
import SwiftData

@Model
final class Tag: Identifiable {
    // MARK: - Properties
    @Attribute(.unique) var id: UUID
    var name: String
    var isPredefined: Bool
    @Relationship(inverse: \Friend.tags) var friends: [Friend]
    
    // MARK: - Initialization
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
    enum TagError: LocalizedError {
        case duplicateTag
        case invalidName
        case saveFailed
        
        var errorDescription: String? {
            switch self {
            case .duplicateTag:
                return "A tag with this name already exists"
            case .invalidName:
                return "Tag name is invalid"
            case .saveFailed:
                return "Failed to save changes"
            }
        }
    }
    
    static func validateTagName(_ name: String) -> String? {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ? nil : normalized
    }
    
    static func findExisting(name: String, context: ModelContext) throws -> Tag? {
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.name == name
            }
        )
        return try context.fetch(descriptor).first
    }
    
    static func createTag(name: String, friend: Friend?, context: ModelContext) throws -> Tag {
        guard let normalizedName = validateTagName(name) else {
            throw TagError.invalidName
        }
        
        // Check for existing tag
        if let existingTag = try findExisting(name: normalizedName, context: context) {
            if let friend = friend, !friend.tags.contains(where: { $0.id == existingTag.id }) {
                friend.tags.append(existingTag)
                try context.save()
            }
            return existingTag
        }
        
        // Create new tag
        let tag = Tag(name: normalizedName)
        context.insert(tag)
        
        if let friend = friend {
            friend.tags.append(tag)
        }
        
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
