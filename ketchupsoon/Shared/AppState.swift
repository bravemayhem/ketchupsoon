import SwiftUI
import Combine

// Tab identifiers
enum AppTab: String {
    case home
    case createMeetup
    case notifications
    case profile
}

class AppState: ObservableObject {
    // Selected tab
    @Published var selectedTab: AppTab = .home
    
    // Selected friends (from home view)
    @Published var selectedFriendIds: Set<String> = []
    
    // Selected friends as names (for CreateMeetupView)
    @Published var selectedFriendNames: [String] = []
    
    // Function to update selected friend IDs and corresponding names
    func updateSelectedFriends(ids: Set<String>, friendsData: [FriendItem]) {
        selectedFriendIds = ids
        
        // Convert IDs to names for CreateMeetupView
        selectedFriendNames = friendsData
            .filter { ids.contains($0.id) }
            .map { $0.name }
    }
    
    // Function to navigate to create meetup tab with selected friends
    func navigateToCreateMeetup() {
        selectedTab = .createMeetup
    }
} 