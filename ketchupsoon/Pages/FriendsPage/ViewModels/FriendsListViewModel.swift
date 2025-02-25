import SwiftUI
import SwiftData

class FriendsListViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedTags: Set<Tag> = []
    @Published var sortOption: SortOption = .name
    @Published var sortDirection: SortDirection = .none
    @Published var showingTagPicker = false
    @Published var showingSortPicker = false
    
    enum SortDirection {
        case ascending
        case descending
        case none
        
        var systemImage: String {
            switch self {
            case .ascending:
                return "arrow.up"
            case .descending:
                return "arrow.down"
            case .none:
                return "arrow.up.arrow.down"
            }
        }
        
        mutating func toggle() {
            switch self {
            case .none:
                self = .ascending
            case .ascending:
                self = .descending
            case .descending:
                self = .none
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case lastSeen = "Last Seen"
        
        var descriptor: SortDescriptor<Friend> {
            switch self {
            case .name:
                return SortDescriptor(\Friend.name)
            case .lastSeen:
                return SortDescriptor(\Friend.lastSeen, order: .reverse)
            }
        }
    }
    
    func filteredFriends(_ allFriends: [Friend]) -> [Friend] {
        var result = allFriends
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Apply tag filter
        if !selectedTags.isEmpty {
            result = result.filter { friend in
                !selectedTags.isDisjoint(with: Set(friend.tags))
            }
        }
        
        // Apply sort based on direction and option
        if sortDirection != .none {
            switch sortOption {
            case .name:
                result.sort { friend1, friend2 in
                    sortDirection == .ascending ? 
                        friend1.name < friend2.name :
                        friend1.name > friend2.name
                }
            case .lastSeen:
                result.sort { friend1, friend2 in
                    guard let date1 = friend1.lastSeen else { return false }
                    guard let date2 = friend2.lastSeen else { return true }
                    return sortDirection == .ascending ? date1 < date2 : date1 > date2
                }
            }
        }
        
        return result
    }
} 