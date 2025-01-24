# Calendar Integration Simplification

## Context
The calendar integration system previously included functionality to check for availability and suggest times based on both users' calendars. However, this created unnecessary complexity since calendar events don't always represent true "busy" time - someone might have a reminder or flexible event that doesn't prevent them from meeting.

## Changes Made
1. Removed calendar availability checking functionality
   - Removed `busyTimeSlots` tracking
   - Removed `fetchFriendAvailability` and related methods
   - Simplified the scheduling flow

2. Streamlined scheduling interface
   - Removed suggested times feature
   - Simplified duration selection to use direct input
   - Made scheduling more straightforward without availability constraints

3. Enhanced direct event creation
   - Events are now created directly without checking for conflicts
   - Maintained email invitation functionality
   - Preserved calendar integration for event creation

## Technical Details
- Removed availability-related code from `CalendarManager`
- Simplified `SchedulerView` by removing availability checks
- Maintained core calendar event creation functionality
- Preserved Google and Apple calendar integration

## Impact
- Simpler, more straightforward scheduling process
- Reduced complexity in calendar integration
- Better user experience by letting users manage their own availability
- Maintained essential calendar functionality while removing unnecessary constraints

## Future Considerations
- May want to add optional availability indicators in the future
- Could consider adding calendar view to show existing events without blocking scheduling 