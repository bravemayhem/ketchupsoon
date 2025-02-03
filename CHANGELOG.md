# Changelog

## [Unreleased]

### 2024-01-24
#### Added
- **Google Calendar Invites Support**
  - Implemented proper Google Calendar event creation with attendee invites
  - Added calendar type selector (Apple/Google) in scheduler
  - Email recipients now receive proper calendar invites when using Google Calendar
  - Improved calendar integration UI with Google sign-in button

- **Calendar View Implementation**
  - Added comprehensive daily schedule view with hourly event blocks (8 AM - 8 PM)
  - Implemented list view for quick event scanning
  - Added visual distinction between Apple and Google calendar events
  - Implemented long-press gesture for quick scheduling
  - Added date navigation with picker and prev/next buttons
  - Added real-time calendar event synchronization
  - Implemented proper event positioning and overlap handling
  - Added support for all-day events display

#### Changed
- **Calendar Integration Simplification**
  - Removed calendar availability checking functionality
  - Simplified hangout scheduling by removing busy time validation
  - Removed suggested times feature for more straightforward scheduling
  - Streamlined duration selection interface
  - Enhanced direct event creation without availability constraints
  - Removed Share Details feature in favor of calendar invites

- **Hangout Creation Enhancement**
  - Renamed SchedulerView to CreateHangoutView for better clarity
  - Updated navigation title to "Create Hangout" from "Schedule Hangout"
  - Added automatic email population from friend's contact information
  - Improved user experience by pre-filling email when available

- **Hangout Confirmation Enhancement**
  - Replaced "Needs Confirmation" banner with a prominent Confirm button
  - Improved user interaction by making confirmation action more explicit
  - Removed automatic confirmation prompts for better user control
  - Streamlined the confirmation flow for past hangouts

#### Fixed
- **Bulk Contact Import Flow**
  - Fixed issue where friend details weren't updating during bulk contact import
  - Added proper view refresh when moving between contacts
  - Improved state management for contact onboarding flow
  - Enhanced user experience with smoother transitions between contacts
  - Fixed duplicate contact creation during bulk import:
    - Added duplicate checking to "Skip All" functionality
    - Improved duplicate detection by checking existing contact identifiers
    - Optimized performance by fetching existing friends once
    - Prevented duplicate entries across all import paths

### 2024-01-22
#### Added
- **Friend Creation Timestamp**
  - Added `createdAt` timestamp to track when friends are added to the system
  - Enhanced scheduling logic to use creation date for new friends
  - Improved accuracy of "Needs Scheduling" suggestions

#### Changed
- **Scheduling Window Adjustment**
  - Reduced scheduling reminder window from 3 weeks to 2 weeks
  - More focused and timely scheduling suggestions
  - Better user experience with shorter planning horizon

- **Message Sharing Enhancement**
  - Simplified hangout sharing message format
  - Removed calendar link for better user experience
  - Enhanced message readability with clear date, activity, and location formatting
  - Improved message sheet presentation with adjustable height

### 2024-03-25
#### Added
- **Contact Sync Improvements**
  - Added ability to sync edits made through native contact interface
  - Enhanced bi-directional synchronization between app and system contacts
  - Improved data consistency when contacts are modified externally

#### Changed
- **Manual Contact Editing Enhancement**
  - Enhanced manual contacts with inline name and phone number editing
  - Added text fields for direct editing of manually added friends
  - Maintained read-only fields for contacts imported from address book
  - Implemented real-time updates as users type
  - Preserved empty state handling with "Not set" placeholder

- **Contact Interface UX Enhancement**
  - Replaced "Done" button with gesture-based dismissal for contact sheet
  - Added visual grabber indicator for more intuitive interaction
  - Improved sheet presentation style with rounded corners
  - Enhanced native iOS feel with standard sheet interactions

- **Friend Details UI Consistency**
  - Standardized "Not set" placeholder styling across all unset fields
  - Applied consistent text color for empty values
  - Improved visual feedback for editable fields
  - Enhanced clarity of which fields can be updated

- **Phone Number Display in Friend Details**
  - Added phone number field to friend details view
  - Implemented consistent styling with other contact fields
  - Shows phone numbers from contacts in accent color with tap-to-edit
  - Displays manual entries in standard color scheme
  - Added "Not set" placeholder for missing phone numbers

### 2024-03-24
#### Added
- **Contact Integration for Imported Friends**
  - Enabled direct access to contact details from friend cards for imported contacts
  - Implemented visual distinction with accent color for imported contact fields
  - Established contacts as source of truth for imported friend information
  - Enhanced user experience by avoiding duplicate data entry
  - Streamlined access to contact details through native iOS contact interface

#### Changed
- **Friend Details UI Consistency**
  - Standardized "Not set" placeholder styling across all unset fields
  - Applied consistent text color for empty values
  - Improved visual feedback for editable fields
  - Enhanced clarity of which fields can be updated

- **Text Color Refinements**
  - Updated "Not set" text to use lighter color (tertiaryLabel) for better visual hierarchy
  - Standardized text colors across Last Seen and Catch Up Frequency fields
  - Improved consistency with City field interaction patterns
  - Enhanced visual feedback for field states

### 2024-03-23
#### Changed
- **Friend Details UI Consistency**
  - Standardized label styling across all fields in friend details
  - Updated field labels to use consistent black text
  - Added uniform "Not set" placeholder for empty fields
  - Unified text alignment patterns across all inputs
  - Improved visual hierarchy with standardized colors
  - Enhanced readability through consistent styling

### 2024-03-22
#### Changed
- **Friend Card UI Improvements**
  - Improved icon alignment in FriendListCard
  - Standardized spacing between icons and text
  - Enhanced visual consistency across all friend card elements
  - Fixed left alignment of text while maintaining centered icons

### 2024-03-21
#### Changed
- **City Search UI/UX Improvements**
  - Replaced sheet-based city picker with inline popup search
  - Implemented MapKit-based city autocompletion
  - Unified city search UI between new and existing friends
  - Improved search results filtering for cities and municipalities
  - Enhanced real-time city selection and updates
  - Removed unused city sheet code and modifiers
  - Better visual feedback during city search

- **Tag Management Refactor**
  - Unified tag selection UI between existing friends and onboarding
  - Modified FriendTagsSection to support both Friend objects and direct tag selection
  - Eliminated need for temporary Friend objects in onboarding flow
  - Simplified tag management by abstracting shared functionality
  - Improved code organization and reduced duplication
  - Updated initialization patterns in FriendTagsSection for better reusability

- **FriendDetail ViewModel Refactor**
  - Converted lastSeenDate from stored to computed property
  - Eliminated state duplication between ViewModel and Friend model
  - Established Friend model as single source of truth for last seen date
  - Simplified date updates through Friend.updateLastSeen method

#### Technical Details
- Refactored shared components for better code reuse
- Improved state management in tag selection flow
- Enhanced component initialization patterns
- Reduced code duplication across friend management features
- Streamlined city search with MapKit integration
- Better separation of concerns between UI and business logic

#### Impact
- More consistent UI/UX for tag management across the app
- Simplified onboarding flow
- Better maintainability through shared components
- Improved code organization
- Enhanced city search experience with real-time suggestions

- **Date Picker Sheet Fix & Component Refactoring**
  - Fixed date picker presentation issues in friend onboarding flow
  - Created reusable DatePickerView component
  - Improved sheet presentation handling by moving it to parent view
  - Maintained proper separation of concerns between components
  - Fixed presentation conflicts with navigation stack

#### Technical Details
- Moved sheet presentation responsibility to parent views
- Created dedicated DatePickerView component for reusability
- Improved state management with proper binding flow
- Fixed multiple presentation attempts issue
- Better component organization and responsibility separation

### Fixed
- Fixed tag selection visual feedback in the tag management sheet when adding new friends
- Improved tag selection state management to handle both existing and new friends properly

### Changed
- Refactored tag selection logic to use a dedicated `TagSelectionState` enum for better type safety and clarity
- Updated `TagsSection`, `TagsContentView`, and `TagsSelectionView` to use the new tag selection state management

### 2024-03-26
#### Added
- **Settings Interface**
  - Added settings gear icon to the left side of all navigation bars
  - Created new Settings view with profile, app settings, and data management sections
  - Implemented basic settings structure for future feature expansion
  - Added navigation links for Profile Settings, Notifications, and Calendar Integration
  - Included data management option for clearing app data

#### Changed
- **Calendar Integration Enhancement**
  - Integrated existing CalendarManager with new settings interface
  - Added visual status indicators for Apple and Google Calendar connections
  - Implemented connected calendars list showing all synced calendars
  - Improved calendar authorization flow for both Apple and Google calendars
  - Enhanced user feedback with clear connection states

#### Fixed
- **Google Calendar Authentication**
  - Fixed Google Calendar sign-in persistence issue
  - Added proper session restoration on app launch
  - Implemented sign-out functionality
  - Enhanced error handling for Google authentication
  - Added proper state management for Google Calendar connection

### 2024-03-27
#### Added
- **Dark Mode Support**
  - Added toggle in settings for light/dark mode preference
  - Enhanced app appearance with system-wide dark mode support
  - Improved visual consistency across all views in both modes

#### Changed
- **Tag Management UI Enhancement**
  - Updated tag management interface with consistent theme colors
  - Fixed tag section background visibility
  - Enhanced create tag sheet with proper color scheme
  - Improved visual hierarchy in both light and dark modes

- **Email Support**
  - Added email field to friend details for both new and existing friends
  - Implemented email import from contacts when adding friends from address book
  - Added editable email field for manually added friends
  - Enhanced contact sync to include email updates
  - Maintained consistent UI patterns for email display and editing

### 2025-01-24
#### Added
- **Page Subtitles**
  - Added descriptive subtitles to all main navigation pages:
    - Ketchups: "Your social calendar at your finger tips"
    - Wishlist: "Keep track of friends you want to see soon"
    - Friends: "Friends you've added to Ketchup Soon"
  - Enhanced UI with proper iOS-style subtitle formatting and alignment
  - Improved user understanding of page purposes through descriptive text

#### Changed
- **Navigation UI Enhancement**
  - Updated navigation stack to support subtitles below page titles
  - Maintained consistent left alignment with iOS design guidelines
  - Enhanced visual hierarchy between titles and subtitles

- **Sort Controls Enhancement**
  - Enhanced sort functionality with three-state toggle (none/ascending/descending)
  - Improved sort controls UI with consistent sizing and spacing
  - Added visual feedback with accent color for active sort state
  - Updated sort direction indicator with clear up/down arrows
  - Maintained left alignment for sort field selection

### Added
- Push notification support for hangouts and catch-up reminders
  - Configurable reminder times for upcoming hangouts
  - Catch-up frequency notifications based on friend preferences
  - Notification settings management in Settings
  - Visual feedback for notification authorization status
  - Ability to clear all pending notifications

## [1.0.0] - 2024-01-13

### Added
- Initial release
- Basic friend management functionality
- Tag system for categorizing friends
- Catch-up scheduling features
- Contact integration
- **Duplicate Friend Prevention**
  - Added validation to prevent adding duplicate friends
  - Checks for duplicate contact identifiers when importing from contacts
  - Performs case-insensitive name comparison to prevent duplicate names
  - Shows clear error messages when duplicates are detected
  - Improves data integrity by preventing duplicate entries

### Added
- Search functionality in Friends List
  - Real-time search by friend name
  - Case-insensitive search
- Sort functionality in Friends List
  - Sort by name (default)
  - Sort by last seen date
- Tag filtering in Friends List
  - Filter friends by multiple tags
  - Visual tag chips with remove option
  - Tag picker with Clear All option
- UI Improvements
  - Compact search and filter controls
  - Visual indicators for active filters
  - Improved empty states for search/filter results

### Added
- Calendar integration feature
  - Added daily and list view of calendar events
  - Support for both Apple Calendar and Google Calendar integration
  - Long-press gesture to schedule hangouts at specific times
  - Visual distinction between Apple and Google calendar events
  - Friend picker for quick scheduling
  - Real-time calendar event synchronization
  - Support for all-day events
  - Calendar authorization management
  - Event details including title, time, and location display

### Fixed
- Calendar initialization and authorization handling
- Duplicate event ID handling
- Event loading and display synchronization

### Changed
- Improved calendar navigation with date picker and view mode toggle
- Enhanced event visualization in daily view
- Streamlined scheduling workflow

#### Added
- **Hangout Rescheduling Enhancement**
  - Added ability to track original hangout when rescheduling
  - Improved rescheduling flow through calendar overlay
  - Added support for preserving hangout details (activity, location) when rescheduling

### Changed
- Refactored tag selection logic to use a dedicated `TagSelectionState` enum for better type safety and clarity
- Updated `TagsSection`, `TagsContentView`, and `TagsSelectionView` to use the new tag selection state management

### 2024-03-26
#### Added
- **Settings Interface**
  - Added settings gear icon to the left side of all navigation bars
  - Created new Settings view with profile, app settings, and data management sections
  - Implemented basic settings structure for future feature expansion
  - Added navigation links for Profile Settings, Notifications, and Calendar Integration
  - Included data management option for clearing app data

#### Changed
- **Calendar Integration Enhancement**
  - Integrated existing CalendarManager with new settings interface
  - Added visual status indicators for Apple and Google Calendar connections
  - Implemented connected calendars list showing all synced calendars
  - Improved calendar authorization flow for both Apple and Google calendars
  - Enhanced user feedback with clear connection states

#### Fixed
- **Google Calendar Authentication**
  - Fixed Google Calendar sign-in persistence issue
  - Added proper session restoration on app launch
  - Implemented sign-out functionality
  - Enhanced error handling for Google authentication
  - Added proper state management for Google Calendar connection

### 2024-03-27
#### Added
- **Dark Mode Support**
  - Added toggle in settings for light/dark mode preference
  - Enhanced app appearance with system-wide dark mode support
  - Improved visual consistency across all views in both modes

#### Changed
- **Tag Management UI Enhancement**
  - Updated tag management interface with consistent theme colors
  - Fixed tag section background visibility
  - Enhanced create tag sheet with proper color scheme
  - Improved visual hierarchy in both light and dark modes

- **Email Support**
  - Added email field to friend details for both new and existing friends
  - Implemented email import from contacts when adding friends from address book
  - Added editable email field for manually added friends
  - Enhanced contact sync to include email updates
  - Maintained consistent UI patterns for email display and editing

### 2025-01-24
#### Added
- **Page Subtitles**
  - Added descriptive subtitles to all main navigation pages:
    - Ketchups: "Your social calendar at your finger tips"
    - Wishlist: "Keep track of friends you want to see soon"
    - Friends: "Friends you've added to Ketchup Soon"
  - Enhanced UI with proper iOS-style subtitle formatting and alignment
  - Improved user understanding of page purposes through descriptive text

#### Changed
- **Navigation UI Enhancement**
  - Updated navigation stack to support subtitles below page titles
  - Maintained consistent left alignment with iOS design guidelines
  - Enhanced visual hierarchy between titles and subtitles

- **Sort Controls Enhancement**
  - Enhanced sort functionality with three-state toggle (none/ascending/descending)
  - Improved sort controls UI with consistent sizing and spacing
  - Added visual feedback with accent color for active sort state
  - Updated sort direction indicator with clear up/down arrows
  - Maintained left alignment for sort field selection

## [1.0.0] - 2024-01-25

### Changed
- Updated KetchupsView to show a maximum of 3 items per section (Upcoming, Past, Completed)
- Added "See All" functionality to view up to 10 items in each section
- Created new reusable KetchupSectionView component for consistent section styling
- Added new HangoutListView for displaying full list of hangouts in a sheet

### 2024-01-28
#### Added
- **Smart Calendar Default Selection**
  - Implemented automatic default calendar selection based on authorization status
  - Google Calendar preferred when available (supports invites)
  - Apple Calendar used as fallback option
  - Automatic updates when calendar services connect/disconnect
  - Clear UI feedback about invite support limitations

- **Calendar Account Display**
  - Added email display for active calendar account
  - Shows Google account email when using Google Calendar
  - Shows Apple calendar email when using Apple Calendar
  - Updates automatically when switching calendar types
  - Consistent UI with envelope icon and secondary text color

#### Changed
- **Calendar Integration Settings**
  - Enhanced calendar integration view with clearer service status
  - Added dynamic default calendar preference management
  - Improved error handling for Google sign-in
  - Added clear messaging about calendar invite capabilities
  - Disabled preference selection when no calendars are authorized
  - Added visual feedback for active calendar account

### 2024-03-25
#### Added
- **Contact Sync Improvements**
  - Added ability to sync edits made through native contact interface
  - Enhanced bi-directional synchronization between app and system contacts
  - Improved data consistency when contacts are modified externally

#### Changed
- **Manual Contact Editing Enhancement**
  - Enhanced manual contacts with inline name and phone number editing
  - Added text fields for direct editing of manually added friends
  - Maintained read-only fields for contacts imported from address book
  - Implemented real-time updates as users type
  - Preserved empty state handling with "Not set" placeholder

- **Contact Interface UX Enhancement**
  - Replaced "Done" button with gesture-based dismissal for contact sheet
  - Added visual grabber indicator for more intuitive interaction
  - Improved sheet presentation style with rounded corners
  - Enhanced native iOS feel with standard sheet interactions

- **Friend Details UI Consistency**
  - Standardized "Not set" placeholder styling across all unset fields
  - Applied consistent text color for empty values
  - Improved visual feedback for editable fields
  - Enhanced clarity of which fields can be updated

- **Phone Number Display in Friend Details**
  - Added phone number field to friend details view
  - Implemented consistent styling with other contact fields
  - Shows phone numbers from contacts in accent color with tap-to-edit
  - Displays manual entries in standard color scheme
  - Added "Not set" placeholder for missing phone numbers

### 2024-03-24
#### Added
- **Contact Integration for Imported Friends**
  - Enabled direct access to contact details from friend cards for imported contacts
  - Implemented visual distinction with accent color for imported contact fields
  - Established contacts as source of truth for imported friend information
  - Enhanced user experience by avoiding duplicate data entry
  - Streamlined access to contact details through native iOS contact interface

#### Changed
- **Friend Details UI Consistency**
  - Standardized "Not set" placeholder styling across all unset fields
  - Applied consistent text color for empty values
  - Improved visual feedback for editable fields
  - Enhanced clarity of which fields can be updated

- **Text Color Refinements**
  - Updated "Not set" text to use lighter color (tertiaryLabel) for better visual hierarchy
  - Standardized text colors across Last Seen and Catch Up Frequency fields
  - Improved consistency with City field interaction patterns
  - Enhanced visual feedback for field states

### 2024-03-23
#### Changed
- **Friend Details UI Consistency**
  - Standardized label styling across all fields in friend details
  - Updated field labels to use consistent black text
  - Added uniform "Not set" placeholder for empty fields
  - Unified text alignment patterns across all inputs
  - Improved visual hierarchy with standardized colors
  - Enhanced readability through consistent styling

### 2024-03-22
#### Changed
- **Friend Card UI Improvements**
  - Improved icon alignment in FriendListCard
  - Standardized spacing between icons and text
  - Enhanced visual consistency across all friend card elements
  - Fixed left alignment of text while maintaining centered icons

### 2024-03-21
#### Changed
- **City Search UI/UX Improvements**
  - Replaced sheet-based city picker with inline popup search
  - Implemented MapKit-based city autocompletion
  - Unified city search UI between new and existing friends
  - Improved search results filtering for cities and municipalities
  - Enhanced real-time city selection and updates
  - Removed unused city sheet code and modifiers
  - Better visual feedback during city search

- **Tag Management Refactor**
  - Unified tag selection UI between existing friends and onboarding
  - Modified FriendTagsSection to support both Friend objects and direct tag selection
  - Eliminated need for temporary Friend objects in onboarding flow
  - Simplified tag management by abstracting shared functionality
  - Improved code organization and reduced duplication
  - Updated initialization patterns in FriendTagsSection for better reusability

- **FriendDetail ViewModel Refactor**
  - Converted lastSeenDate from stored to computed property
  - Eliminated state duplication between ViewModel and Friend model
  - Established Friend model as single source of truth for last seen date
  - Simplified date updates through Friend.updateLastSeen method

#### Technical Details
- Refactored shared components for better code reuse
- Improved state management in tag selection flow
- Enhanced component initialization patterns
- Reduced code duplication across friend management features
- Streamlined city search with MapKit integration
- Better separation of concerns between UI and business logic

#### Impact
- More consistent UI/UX for tag management across the app
- Simplified onboarding flow
- Better maintainability through shared components
- Improved code organization
- Enhanced city search experience with real-time suggestions

- **Date Picker Sheet Fix & Component Refactoring**
  - Fixed date picker presentation issues in friend onboarding flow
  - Created reusable DatePickerView component
  - Improved sheet presentation handling by moving it to parent view
  - Maintained proper separation of concerns between components
  - Fixed presentation conflicts with navigation stack

#### Technical Details
- Moved sheet presentation responsibility to parent views
- Created dedicated DatePickerView component for reusability
- Improved state management with proper binding flow
- Fixed multiple presentation attempts issue
- Better component organization and responsibility separation

### Fixed
- Fixed tag selection visual feedback in the tag management sheet when adding new friends
- Improved tag selection state management to handle both existing and new friends properly

### Changed
- Refactored tag selection logic to use a dedicated `TagSelectionState` enum for better type safety and clarity
- Updated `TagsSection`, `TagsContentView`, and `TagsSelectionView` to use the new tag selection state management

### 2024-03-26
#### Added
- **Settings Interface**
  - Added settings gear icon to the left side of all navigation bars
  - Created new Settings view with profile, app settings, and data management sections
  - Implemented basic settings structure for future feature expansion
  - Added navigation links for Profile Settings, Notifications, and Calendar Integration
  - Included data management option for clearing app data

#### Changed
- **Calendar Integration Enhancement**
  - Integrated existing CalendarManager with new settings interface
  - Added visual status indicators for Apple and Google Calendar connections
  - Implemented connected calendars list showing all synced calendars
  - Improved calendar authorization flow for both Apple and Google calendars
  - Enhanced user feedback with clear connection states

#### Fixed
- **Google Calendar Authentication**
  - Fixed Google Calendar sign-in persistence issue
  - Added proper session restoration on app launch
  - Implemented sign-out functionality
  - Enhanced error handling for Google authentication
  - Added proper state management for Google Calendar connection

### 2024-03-27
#### Added
- **Dark Mode Support**
  - Added toggle in settings for light/dark mode preference
  - Enhanced app appearance with system-wide dark mode support
  - Improved visual consistency across all views in both modes

#### Changed
- **Tag Management UI Enhancement**
  - Updated tag management interface with consistent theme colors
  - Fixed tag section background visibility
  - Enhanced create tag sheet with proper color scheme
  - Improved visual hierarchy in both light and dark modes

- **Email Support**
  - Added email field to friend details for both new and existing friends
  - Implemented email import from contacts when adding friends from address book
  - Added editable email field for manually added friends
  - Enhanced contact sync to include email updates
  - Maintained consistent UI patterns for email display and editing

### 2025-01-24
#### Added
- **Page Subtitles**
  - Added descriptive subtitles to all main navigation pages:
    - Ketchups: "Your social calendar at your finger tips"
    - Wishlist: "Keep track of friends you want to see soon"
    - Friends: "Friends you've added to Ketchup Soon"
  - Enhanced UI with proper iOS-style subtitle formatting and alignment
  - Improved user understanding of page purposes through descriptive text

#### Changed
- **Navigation UI Enhancement**
  - Updated navigation stack to support subtitles below page titles
  - Maintained consistent left alignment with iOS design guidelines
  - Enhanced visual hierarchy between titles and subtitles

- **Sort Controls Enhancement**
  - Enhanced sort functionality with three-state toggle (none/ascending/descending)
  - Improved sort controls UI with consistent sizing and spacing
  - Added visual feedback with accent color for active sort state
  - Updated sort direction indicator with clear up/down arrows
  - Maintained left alignment for sort field selection

## [1.0.0] - 2025-01-29
### Changed
- Standardized logo placement across all calendar views (right-aligned)
- Fixed indentation issues in EventListItemView
- Updated EventDetailView to match consistent design pattern

### Fixed
- Resolved calendar event indentation in list view
- Fixed logo visibility and quality issues
- Corrected state cleanup in modal dismissal
- Standardized image asset usage across views

### Enhanced
- Improved visual consistency across calendar interfaces
- Better event detail presentation
- Optimized calendar view transitions
- Standardized padding and spacing in list views

### Technical
- Refactored DailyScheduleView for better performance
- Improved state management in EventDetailView
- Enhanced code organization with proper component separation
- Added comprehensive memory file for calendar system

### 2024-02-01
#### Added
- **Calendar Event Caching**
  - Implemented smart caching system for calendar events
  - Added proactive event loading on app launch and foreground
  - Added debug logging with emoji indicators for tracking cache behavior
  - Created comprehensive memory file documenting calendar optimization

#### Changed
- **Calendar Loading Experience**
  - Improved calendar view performance with cached events
  - Optimized loading states to reduce UI flicker
  - Enhanced event loading to maintain existing events while fetching
  - Modified CalendarManager to use singleton pattern for shared state

#### Fixed
- **Calendar Performance Issues**
  - Fixed repeated loading when switching dates
  - Fixed unnecessary refresh on calendar view open
  - Fixed loading indicator showing too frequently
  - Improved handling of calendar authorization states

### 2025-02-02
#### Changed
- **Multi-Friend Hangout Support**
  - Updated hangout creation flow to support multiple friends
  - Changed from single friend selection to group selection
  - Modified calendar event creation to handle multiple attendees
  - Enhanced email handling for group invites
  - Updated UI to show all participants in hangout cards
  - Improved calendar invite handling for multiple recipients

#### Added
- **Enhanced Email Management**
  - Added dropdown email selector for each friend
  - Implemented multiple email storage per friend using SwiftData transformable attributes
  - Added ability to select from primary and additional emails
  - Created UI for adding new emails that persist with contacts
  - Added email status indicators and warnings
  - Implemented swipe-to-delete for friend removal
  - Added manual attendee section for non-app users

#### Technical
- **Data Model Updates**
  - Modified Friend-Hangout relationship to support many-to-many
  - Implemented custom EmailArrayValueTransformer for SwiftData
  - Fixed email array serialization issue by preventing double transformation
  - Added proper email validation and storage
  - Enhanced model relationship cascade rules
  - Improved state management for email selection
  - Fixed SwiftData transformable registration timing
  - Simplified email array property accessors

#### Fixed
- Fixed email selection UI to use dropdown instead of long-press
- Resolved SwiftData transformable registration issues
- Fixed email array serialization by removing double transformation
- Fixed email state management conflicts
- Improved friend removal UX with swipe gestures
- Enhanced email validation and feedback
- Added loading states for email operations
