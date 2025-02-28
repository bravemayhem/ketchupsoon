import SwiftUI
import SwiftData

enum FriendDetail {
    enum PresentationStyle {
        case navigation
        case sheet(Binding<Bool>)
    }
    
    enum FriendError: Error {
        case duplicateName
        case duplicateContact
        
        var message: String {
            switch self {
            case .duplicateName:
                return "A friend with this name already exists"
            case .duplicateContact:
                return "This contact has already been added"
            }
        }
    }
    
    struct NewFriendInput {
        let name: String
        let identifier: String?
        let phoneNumber: String?
        let email: String?
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
        func createFriend(in modelContext: ModelContext) throws -> Friend
    }
    
    // MARK: - View Model Implementations
    @Observable class ViewModel: ExistingFriendViewModel {
        let friend: Friend
        var showingDatePicker = false
        var showingScheduler = false
        var showingMessageSheet = false
        var showingTagsManager = false
        var showingFrequencyPicker = false
        var showingContactSheet = false
        var lastSeenDate: Date {
            get { friend.lastSeen ?? Date() }
            set { friend.updateLastSeen(to: newValue) }
        }
        
        init(friend: Friend) {
            self.friend = friend
        }
        
        func updateLastSeenDate(to date: Date) {
            friend.updateLastSeen(to: date)
            // Update last seen date for all friends in shared hangouts
            let sharedHangouts = friend.hangouts.filter { !$0.isCompleted && $0.date <= Date() }
            for hangout in sharedHangouts {
                for friend in hangout.friends {
                    friend.updateLastSeen(to: date)
                }
            }
        }
        
        func markAsSeen() {
            updateLastSeenDate(to: Date())
        }
    }
    
    @Observable class OnboardingViewModel: NewFriendViewModel {
        // Contact data
        var friendName = ""
        var phoneNumber = ""
        var email = ""
        var selectedCity: String?
        var hasLastSeen = false
        var lastSeenDate = Date()
        var hasCatchUpFrequency = false
        var selectedFrequency: CatchUpFrequency = .monthly
        var wantToConnectSoon = false
        var selectedTags: Set<Tag> = []
        var birthday: Date? = nil
        var hasBirthday = false
        let input: NewFriendInput?
        
        // Sheet states
        var showingDatePicker = false
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
        
        private func checkForDuplicates(in modelContext: ModelContext) throws {
            // For manual entry, check for duplicate names
            if !isFromContacts && !friendName.isEmpty {
                let descriptors = [SortDescriptor(\Friend.name)]
                let predicate = #Predicate<Friend> { $0.name == friendName }
                let fetchDescriptor = FetchDescriptor<Friend>(predicate: predicate, sortBy: descriptors)
                
                do {
                    let duplicates = try modelContext.fetch(fetchDescriptor)
                    if !duplicates.isEmpty {
                        throw FriendError.duplicateName
                    }
                } catch let fetchError as FriendError {
                    throw fetchError
                } catch {
                    print("Error checking for duplicate names: \(error)")
                }
            }
            
            // For contacts import, check for duplicate contacts
            if let identifier = input?.identifier {
                let descriptors = [SortDescriptor(\Friend.name)]
                let predicate = #Predicate<Friend> { $0.contactIdentifier == identifier }
                let fetchDescriptor = FetchDescriptor<Friend>(predicate: predicate, sortBy: descriptors)
                
                do {
                    let duplicates = try modelContext.fetch(fetchDescriptor)
                    if !duplicates.isEmpty {
                        throw FriendError.duplicateContact
                    }
                } catch let fetchError as FriendError {
                    throw fetchError
                } catch {
                    print("Error checking for duplicate contacts: \(error)")
                }
            }
        }
        
        func createFriend(in modelContext: ModelContext) throws -> Friend {
            try checkForDuplicates(in: modelContext)
            
            let friend = Friend(
                name: displayName,
                lastSeen: hasLastSeen ? lastSeenDate : nil,
                location: selectedCity,
                contactIdentifier: input?.identifier,
                needsToConnectFlag: wantToConnectSoon,
                phoneNumber: isFromContacts ? input?.phoneNumber : (phoneNumber.isEmpty ? nil : phoneNumber),
                email: isFromContacts ? input?.email : (email.isEmpty ? nil : email),
                photoData: input?.imageData,
                catchUpFrequency: hasCatchUpFrequency ? selectedFrequency : nil,
                birthday: hasBirthday ? birthday : nil,
                calendarIntegrationEnabled: false,
                calendarVisibilityPreference: .none
            )
            friend.tags = Array(selectedTags)
            modelContext.insert(friend)
            return friend
        }
    }
}
