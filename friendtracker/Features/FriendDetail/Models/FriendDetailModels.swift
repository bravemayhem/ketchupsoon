import SwiftUI
import SwiftData

enum FriendDetail {
    enum PresentationStyle {
        case navigation
        case sheet(Binding<Bool>)
    }
    
    struct NewFriendInput {
        let name: String
        let identifier: String?
        let phoneNumber: String?
        let imageData: Data?
        let city: String?
        
        var isFromContacts: Bool {
            !name.isEmpty
        }
    }
    
    @Observable
    class OnboardingViewModel {
        // Input data
        var friendName = ""
        var phoneNumber = ""
        var citySearchText = ""
        var selectedCity: String?
        var hasLastSeen = false
        var lastSeenDate = Date()
        var hasCatchUpFrequency = false
        var selectedFrequency: CatchUpFrequency = .monthly
        var wantToConnectSoon = false
        var selectedTags: Set<Tag> = []
        
        // Contact data if from contacts
        let input: NewFriendInput?
        
        init(input: NewFriendInput? = nil) {
            self.input = input
            if let input = input {
                self.citySearchText = input.city ?? ""
                self.selectedCity = input.city
            }
        }
        
        var isFromContacts: Bool {
            input?.isFromContacts ?? false
        }
        
        func toggleTag(_ tag: Tag) {
            if selectedTags.contains(tag) {
                selectedTags.remove(tag)
            } else {
                selectedTags.insert(tag)
            }
        }
        
        func addFriend(to modelContext: ModelContext) {
            let friend = Friend(
                name: isFromContacts ? input!.name : friendName,
                lastSeen: hasLastSeen ? lastSeenDate : nil,
                location: selectedCity,
                contactIdentifier: input?.identifier,
                needsToConnectFlag: wantToConnectSoon,
                phoneNumber: isFromContacts ? input?.phoneNumber : (phoneNumber.isEmpty ? nil : phoneNumber),
                photoData: input?.imageData,
                catchUpFrequency: hasCatchUpFrequency ? selectedFrequency : nil
            )
            
            // Add selected tags
            friend.tags = Array(selectedTags)
            
            modelContext.insert(friend)
        }
    }
    
    @Observable
    class ViewModel {
        let friend: Friend
        var showingDatePicker = false
        var showingScheduler = false
        var showingMessageSheet = false
        var showingCityPicker = false
        var showingTagsManager = false
        var lastSeenDate = Date()
        var citySearchText = ""
        var selectedCity: String?
        
        init(friend: Friend) {
            self.friend = friend
            self.citySearchText = friend.location ?? ""
            self.selectedCity = friend.location
        }
        
        func markAsSeen() {
            friend.updateLastSeen()
        }
        
        func updateLastSeenDate(to date: Date) {
            friend.updateLastSeen(to: date)
        }
        
        func updateCity() {
            friend.location = selectedCity
        }
    }
} 