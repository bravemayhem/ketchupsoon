import Foundation

enum FriendLocation: String, CaseIterable {
    case local = "Local"
    case remote = "Remote"
    case international = "International"
    
    var description: String {
        return self.rawValue
    }
} 