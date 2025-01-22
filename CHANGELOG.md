# Changelog

## [Unreleased]

### 2024-03-22
#### Added
- **Friend Details Enhancement**
  - Added frequency selection to Friend Details section
  - Integrated FrequencyPickerView for catch-up frequency management
  - Added visual indicator for current catch-up frequency
  - Improved friend management workflow with direct frequency updates

### 2024-03-21
#### Changed
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

#### Impact
- More consistent UI/UX for tag management across the app
- Simplified onboarding flow
- Better maintainability through shared components
- Improved code organization 