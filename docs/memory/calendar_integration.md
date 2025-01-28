# Calendar Integration

## Overview
The calendar integration feature allows users to view their existing calendar events and schedule new hangouts directly from a unified calendar view. It supports both Apple Calendar and Google Calendar integration, with smart default selection based on available calendar services.

## Key Components

### CalendarManager
- Handles calendar authorization and access
- Manages both Apple (EKEventStore) and Google Calendar integration
- Provides unified event fetching and creation
- Handles calendar synchronization and updates
- Smart default calendar selection:
  - Prefers Google Calendar when authorized (supports invites)
  - Falls back to Apple Calendar when Google is unavailable
  - Updates defaults automatically based on authorization changes

### CalendarIntegrationView
- Main view for calendar service management
- Handles calendar authorization flows
- Manages default calendar preferences
- Provides clear feedback about invite capabilities
- Automatic preference updates based on authorization status

### Calendar Preferences
- Default calendar selection based on authorization status
- Persisted using @AppStorage for app restarts
- User-configurable with clear UI feedback
- Automatic updates when calendar services connect/disconnect
- Clear indication of invite support limitations

### CalendarOverlayView
- Main view for calendar interaction
- Supports both daily and list view modes
- Handles date selection and navigation
- Manages event loading and display

### DailyScheduleView
- Provides hourly view of events
- Supports long-press gesture for scheduling
- Visual representation of event duration and timing
- Handles event overlap and positioning

## Implementation Details

### Event Handling
- Events are wrapped in a `CalendarEvent` struct that includes:
  - Unique ID combining source and event ID
  - Source indicator (Apple/Google)
  - Original event data

### Authorization Flow
1. Initial setup in CalendarManager initialization
2. Separate handling for Apple and Google calendars
3. Persistent authorization state
4. User-triggered re-authorization through settings
5. Automatic default calendar updates

### Scheduling Flow
1. Long-press on desired time slot
2. Friend picker appears
3. Select friend to schedule with
4. Pre-filled scheduler with selected time
5. Complete hangout details
6. Event created in selected calendar (with invites if Google)

## Technical Decisions

### Smart Default Selection
- Google Calendar preferred when available (supports invites)
- Apple Calendar as fallback option
- Automatic updates based on authorization changes
- User preferences preserved across app launches

### Why Two View Modes?
- Daily view: Better for time slot visualization and scheduling
- List view: Better for quick event scanning and details

### Event ID Generation
- Combined source + event ID to prevent duplicates
- Handles cases where event ID might be nil
- Ensures unique identification across calendar sources

### Authorization Handling
- Separate flags for Apple and Google
- Initialization check before operations
- Clear error states and user feedback
- Automatic default updates on auth changes

## Future Considerations

### Potential Improvements
1. Support for other calendar providers
2. Better handling of recurring events
3. Calendar availability checking
4. Support for multiple Google calendars
5. Enhanced invite customization options
6. Calendar color customization
7. Calendar-specific notification preferences

### Known Limitations
1. Apple Calendar doesn't support proper invites through the API
2. Limited to primary Google Calendar
3. No support for complex recurrence rules
4. Initial authorization may require app restart

## Testing Notes
- Test authorization flows thoroughly
- Verify event creation in both calendar types
- Check date boundary conditions
- Verify long-press behavior
- Test with various calendar configurations
- Verify default calendar selection behavior
- Test invite delivery with both calendar types 