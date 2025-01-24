# Calendar Integration

## Overview
The calendar integration feature allows users to view their existing calendar events and schedule new hangouts directly from a unified calendar view. It supports both Apple Calendar and Google Calendar integration.

## Key Components

### CalendarManager
- Handles calendar authorization and access
- Manages both Apple (EKEventStore) and Google Calendar integration
- Provides unified event fetching and creation
- Handles calendar synchronization and updates

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

### Scheduling Flow
1. Long-press on desired time slot
2. Friend picker appears
3. Select friend to schedule with
4. Pre-filled scheduler with selected time
5. Complete hangout details
6. Event created in selected calendar

## Technical Decisions

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

## Future Considerations

### Potential Improvements
1. Week view option
2. Drag-and-drop event rescheduling
3. Calendar selection for event creation
4. Recurring event support
5. Better conflict detection
6. Calendar color customization

### Known Limitations
1. Initial authorization may require app restart
2. Limited to primary Google Calendar
3. No support for calendar groups
4. All-day events have limited interaction

## Testing Notes
- Test authorization flows thoroughly
- Verify event creation in both calendar types
- Check date boundary conditions
- Verify long-press behavior
- Test with various calendar configurations 