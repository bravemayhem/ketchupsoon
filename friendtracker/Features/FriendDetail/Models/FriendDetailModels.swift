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
    
    // MARK: - View Model Protocols
    protocol FriendDetailViewModel {
        // Common properties
        var lastSeenDate: Date { get set }
        
        // Common sheet presentation states
        var showingCityPicker: Bool { get set }
        var showingTagsManager: Bool { get set }
        var showingDatePicker: Bool { get set }
        
        // Common functionality
        func updateLastSeenDate(to date: Date)
    }
    
    protocol ExistingFriendViewModel: FriendDetailViewModel {
        var friend: Friend { get }
        var showingScheduler: Bool { get set }
        var showingMessageSheet: Bool { get set }
        var showingFrequencyPicker: Bool { get set }
        func markAsSeen()
    }
    
    protocol NewFriendViewModel: FriendDetailViewModel {
        var friendName: String { get set }
        var phoneNumber: String { get set }
        var hasLastSeen: Bool { get set }
        var hasCatchUpFrequency: Bool { get set }
        var selectedFrequency: CatchUpFrequency { get set }
        var wantToConnectSoon: Bool { get set }
        var selectedTags: Set<Tag> { get set }
        var input: NewFriendInput? { get }
        var isFromContacts: Bool { get }
        func createFriend(in modelContext: ModelContext)
    }
    
    // MARK: - View Model Implementations
    @Observable class ViewModel: ExistingFriendViewModel {
        let friend: Friend
        var showingDatePicker = false
        var showingScheduler = false
        var showingMessageSheet = false
        var showingCityPicker = false
        var showingTagsManager = false
        var showingFrequencyPicker = false
        var lastSeenDate: Date {
            get { friend.lastSeen ?? Date() }
            set { friend.updateLastSeen(to: newValue) }
        }
        
        init(friend: Friend) {
            self.friend = friend
        }
        
        func updateLastSeenDate(to date: Date) {
            friend.updateLastSeen(to: date)
        }
        
        func markAsSeen() {
            friend.updateLastSeen()
        }
    }
    
    @Observable class OnboardingViewModel: NewFriendViewModel {
        // Contact data
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
        let input: NewFriendInput?
        
        // Sheet states
        var showingDatePicker = false
        var showingCityPicker = false
        var showingTagsManager = false
        
        var isFromContacts: Bool {
            input?.isFromContacts ?? false
        }
        
        var displayName: String {
            if isFromContacts {
                return input?.name ?? ""
            } else {
                return friendName
            }
        }
        
        init(input: NewFriendInput? = nil) {
            self.input = input
            if let phoneNumber = input?.phoneNumber {
                self.phoneNumber = phoneNumber
            }
        }

        func updateLastSeenDate(to date: Date) {
            lastSeenDate = date
        }
        
        func createFriend(in modelContext: ModelContext) {
            let friend = Friend(
                name: displayName,
                lastSeen: hasLastSeen ? lastSeenDate : nil,
                location: selectedCity,
                contactIdentifier: input?.identifier,
                needsToConnectFlag: wantToConnectSoon,
                phoneNumber: isFromContacts ? input?.phoneNumber : (phoneNumber.isEmpty ? nil : phoneNumber),
                photoData: input?.imageData,
                catchUpFrequency: hasCatchUpFrequency ? selectedFrequency : nil
            )
            friend.tags = Array(selectedTags)
            modelContext.insert(friend)
        }
        
        func updateSelectedCity(_ city: String?) {
            selectedCity = city
        }
    }
}
