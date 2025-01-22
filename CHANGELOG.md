# Changelog

## [Unreleased]

### 2024-03-25
#### Added
- **Contact Sync Improvements**
  - Added ability to sync edits made through native contact interface
  - Enhanced bi-directional synchronization between app and system contacts
  - Improved data consistency when contacts are modified externally

### 2024-03-24
#### Added
- **Contact Integration for Imported Friends**
  - Enabled direct access to contact details from friend cards for imported contacts
  - Implemented visual distinction with accent color for imported contact fields
  - Established contacts as source of truth for imported friend information
  - Enhanced user experience by avoiding duplicate data entry
  - Streamlined access to contact details through native iOS contact interface

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