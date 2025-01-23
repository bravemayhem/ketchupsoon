# Changelog

## [Unreleased]

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