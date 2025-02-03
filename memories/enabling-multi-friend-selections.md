# Enabling Multi-Friend Selections
Date: February 2, 2025
Status: ✅ Completed

## Context
Previously, the app only supported creating hangouts with a single friend. We're updating the flow to support multiple friend selection, making it easier to plan group hangouts and send calendar invites to multiple participants.

## Changes Made

### Flow Changes
- **Old Flow**:
  1. Tap calendar icon on ketchup page
  2. Select a single friend for that time slot
  3. Adjust details in Create Hangout view

- **New Flow**:
  1. Tap calendar icon on ketchup page
  2. Goes directly to Create Hangout view with empty friend field
  3. Tap + button to select multiple friends
  4. Friends with emails automatically receive calendar invites
  5. Friends without emails are prompted to add them (optional)

### Model Updates
1. **Friend Model**:
   - Added support for multiple email addresses using SwiftData transformable attribute
   - Created custom `EmailArrayValueTransformer` for proper data persistence
   - Fixed serialization issue with email array transformer
   - Added primary email and additional emails support
   - Implemented proper email validation and storage
   - Simplified email array handling to prevent double transformation

2. **Hangout Model**:
   - Changed from single friend to array of friends
   - Updated relationship with Friend model
   - Modified calendar event creation to include all attendees
   - Added support for multiple email recipients

### View Updates
1. **CreateHangoutView**:
   - Added multi-friend selection with swipe-to-delete
   - Implemented email dropdown menu for each friend
   - Added ability to:
     - Select primary email
     - Select from additional emails
     - Add new emails that get saved to the contact
   - Added manual attendee section for non-app users
   - Shows email status for each friend
   - Added warning for friends without emails

2. **Email Management**:
   - Created dropdown menu UI for email selection
   - Supports viewing and selecting from multiple emails
   - Allows adding new emails that persist with the contact
   - Shows clear visual feedback for selected emails
   - Maintains proper state management for temporary and selected emails

### Calendar Integration
- Creates single calendar event for group hangouts
- Includes all friends as attendees
- Properly formats event title and description
- Handles both Apple and Google calendar invites
- Supports manual attendees outside the app

## Technical Details

### Email Storage Implementation
```swift
@Model
final class Friend: Identifiable {
    var email: String?  // Primary email
    @Attribute(.transformable(by: EmailArrayValueTransformer.self))
    private var _additionalEmails: [String]?
    
    var additionalEmails: [String] {
        get { _additionalEmails ?? [] }
        set { _additionalEmails = newValue }
    }
}
```

### Email Selection Management
```swift
class CreateHangoutViewModel: ObservableObject {
    @Published private var selectedEmailAddresses: [Friend.ID: String] = [:]
    @Published private var customEmailAddresses: [Friend.ID: String] = [:]
    
    var emailRecipients: [String] {
        let friendEmails = selectedFriends.compactMap { friend -> String? in
            if let customEmail = customEmailAddresses[friend.id] {
                return customEmail
            }
            if let selectedEmail = selectedEmailAddresses[friend.id] {
                return selectedEmail
            }
            return friend.email
        }
        let manualEmails = manualAttendees.map(\.email)
        return friendEmails + manualEmails
    }
}
```

## Learnings
1. **SwiftData Transformables**:
   - Need to register transformers before ModelContainer initialization
   - Custom transformers must be properly registered with unique names
   - Transformable attributes require explicit type information
   - Avoid double transformation of data to prevent serialization issues
   - Let the transformer handle the actual Data conversion

2. **Email Management**:
   - Separate storage for temporary, selected, and custom emails provides better state management
   - Using dictionaries with Friend.ID as key prevents state conflicts
   - Clear separation between view state and persistent storage improves reliability
   - Simplified property accessors reduce complexity and potential errors

3. **UI/UX Considerations**:
   - Dropdown menus provide better UX than long-press for email selection
   - Visual feedback (checkmarks, icons) helps users understand current state
   - Swipe-to-delete is more intuitive than minus buttons for friend removal
   - Loading states and error handling improve user experience

## Impact
- More flexible hangout creation
- Better support for group activities
- Improved calendar integration
- Enhanced email handling
- More intuitive user flow
- Better data persistence
- Fixed serialization issues

## Future Considerations
1. Email validation improvements
2. Batch email updates
3. Default email preferences
4. Email sync with contacts
5. Email verification system
6. Performance optimization for large contact lists

## Known Issues
1. ✅ Fixed: Circular reference in Friend-Hangout relationship
2. ✅ Fixed: Email array serialization issue
3. 🔄 Need to update all views using FriendPickerView
4. 📝 Need to update documentation and tests

## Next Steps
1. [ ] Update EventDetailView for multi-friend support
2. [ ] Add email validation and prompts
3. [ ] Enhance UI feedback for email status
4. [ ] Update tests for new multi-friend functionality
5. [ ] Add migration for existing hangouts
6. [ ] Update documentation

## Technical Details

### Relationship Changes
```swift
// In Friend.swift
@Relationship(.cascade) var hangouts: [Hangout]

// In Hangout.swift
@Relationship(.cascade) var friends: [Friend]
```

### Calendar Event Creation
```swift
func createHangoutEvent(
    activity: String,
    location: String,
    date: Date,
    duration: TimeInterval,
    emailRecipients: [String],
    attendeeNames: [String]
) async throws -> String
```

## Notes
- Maintaining backward compatibility with existing hangouts
- Need to consider performance with large groups
- Consider adding group templates for frequent combinations 

## Change Log (2/2/25)

- Updated Friend model's _additionalEmails property from an optional [String] to an optional Data to meet SwiftData requirements.
- Modified the computed property additionalEmails to perform JSON encoding/decoding using JSONEncoder/JSONDecoder, ensuring correct serialization.
- Simplified EmailArrayValueTransformer to pass through Data without performing additional JSON conversion, delegating transformation responsibilities to the model.
- Resolved the serialization issue that caused a type mismatch (expected NSData but received Swift array), improving data persistence for multiple friend emails. 