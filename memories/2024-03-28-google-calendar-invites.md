# Google Calendar Invites Implementation

## Context
While the app supported basic calendar integration, it lacked proper support for sending calendar invites to participants. This was particularly noticeable when trying to schedule hangouts with multiple participants, as they wouldn't receive proper calendar invites.

## Implementation Details

### Calendar Type Selection
- Added `CalendarType` enum to distinguish between Apple and Google calendars
- Implemented calendar selector in the scheduler UI
- Calendar selection persists in `CalendarManager`

### Google Calendar Integration
- Enhanced Google Calendar event creation with proper attendee support
- Implemented `GTLRCalendar_Event` creation with:
  - Event details (title, location, time)
  - Attendee management
  - Email notifications via `sendUpdates` parameter
- Added proper error handling and response management

### User Experience
- Added Google sign-in button when Google Calendar is selected but not authorized
- Improved feedback during event creation
- Seamless transition between Apple and Google calendar creation

## Technical Decisions

### Why Two Calendar Systems?
1. Apple Calendar for basic local event creation
2. Google Calendar for proper invite functionality and better cross-platform support

### Event Creation Flow
1. User selects calendar type
2. Adds event details and participants
3. System creates event in selected calendar:
   - Google: Creates event with attendees and sends invites
   - Apple: Creates local event with participants in notes

### Authorization Handling
- Separate authorization flows for Apple and Google
- Persistent Google authentication
- Clear UI feedback for authorization status

## Future Considerations

### Potential Improvements
1. Support for other calendar providers
2. Better handling of recurring events
3. Calendar availability checking
4. Support for multiple Google calendars
5. Enhanced invite customization options

### Known Limitations
1. Apple Calendar doesn't support proper invites through the API
2. Limited to primary Google Calendar
3. No support for complex recurrence rules
4. Calendar provider must be selected manually

## Testing Notes
- Test with various email configurations
- Verify invite delivery
- Check authorization flows
- Test calendar sync behavior 