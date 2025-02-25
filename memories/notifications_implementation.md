# Notifications Implementation

## Overview
Implementation of local notifications system for ketchupsoon, supporting both hangout reminders and catch-up frequency notifications.

## Components

### NotificationsManager
- Singleton manager class for handling all notification-related functionality
- Manages notification authorization status
- Handles scheduling and canceling of notifications
- Supports both one-time hangout reminders and catch-up frequency notifications
- Persists notification preferences using @AppStorage

### Features
1. Hangout Reminders
   - Configurable reminder times (15min, 30min, 1hr, 2hrs, 4hrs)
   - Default reminder time persisted in settings
   - Unique identifiers for each hangout notification
   - Sound and alert support

2. Catch-up Frequency Notifications
   - Based on friend's preferred catch-up frequency
   - Scheduled relative to last contact date
   - Triggers at 10 AM on the target date
   - Can be globally enabled/disabled
   - Automatic rescheduling when frequency changes

3. Settings Integration
   - Dedicated notifications settings view
   - Visual feedback for authorization status
   - Toggle for catch-up reminders
   - Default reminder time selection
   - Clear all notifications option

## Technical Implementation

### Notification Types
1. Hangout Notifications
   - Identifier format: `hangout-{friendName}-{timestamp}`
   - Triggered relative to hangout start time
   - Non-repeating calendar-based triggers

2. Catch-up Notifications
   - Identifier format: `catchup-{friendName}`
   - Calculated based on CatchUpFrequency enum
   - Set for 10 AM on target date
   - Automatically rescheduled on updates

### Authorization Flow
1. Request permissions for .alert, .sound, .badge
2. Register for remote notifications if granted
3. Update and publish authorization status
4. Persist user preferences

### Best Practices
- Unique identifiers for each notification type
- Proper cancellation of existing notifications before rescheduling
- Error handling for authorization and scheduling
- MainActor usage for UI updates
- Proper state management and persistence
- Follows iOS Human Interface Guidelines for settings

## User Experience
- Clear visual feedback for notification status
- Easy access to system settings if denied
- Intuitive settings organization
- Consistent with iOS system settings style
- Clear explanatory text for each feature

## Future Considerations
- Remote notification support
- More granular notification preferences
- Custom notification sounds
- Rich notification content
- Notification grouping
- Interactive notification actions
- Background refresh handling
- Cross-device notification sync
- Analytics for notification engagement 