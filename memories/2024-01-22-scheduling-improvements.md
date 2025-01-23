# Scheduling Logic Improvements

## Context
The app's scheduling system needed refinement in two areas:
1. How new friends were handled in the scheduling system
2. The time window for scheduling reminders

## Changes Made

### Friend Creation Timestamp
- Added a `createdAt` timestamp to the `Friend` model
- This timestamp is automatically set when a new friend is created
- For new friends with a frequency set but no last seen date, scheduling is now based on their creation date
- This provides a more accurate starting point for scheduling reminders

### Scheduling Window Adjustment
- Reduced the scheduling reminder window from 3 weeks to 2 weeks
- Changed `threeWeeksFromNow` to `twoWeeksFromNow` in `KetchupsView`
- Adjusted the time value from 21 days to 14 days

## Reasoning

### Why Track Creation Date?
1. **More Accurate Scheduling**: Previously, new friends without a last seen date would immediately show up in "Needs Scheduling". Now, their scheduling is based on when they were added.
2. **Better User Experience**: Users can set a catch-up frequency for new friends without needing to set a last seen date.
3. **Future-Proofing**: Having creation timestamps opens possibilities for future features (e.g., friend statistics, relationship duration tracking).

### Why 2 Weeks Instead of 3?
1. **More Actionable**: Two weeks provides a more immediate and actionable timeframe for scheduling.
2. **Reduced Cognitive Load**: Users see fewer friends in the "Needs Scheduling" section at once.
3. **Better Planning**: Most people plan social events within a 1-2 week window.

## Technical Implementation
```swift
// Friend.swift
var createdAt: Date  // Non-optional, set at creation

// KetchupsView.swift
private var twoWeeksFromNow: Date {
    Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
}
```

## Migration Note
Since the app hasn't launched yet, we implemented this as a breaking change requiring database clearing rather than a migration path. For future changes post-launch, we'll need to implement proper migrations. 