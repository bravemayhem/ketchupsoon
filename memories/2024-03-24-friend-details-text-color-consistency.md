# Friend Details Text Color Consistency

## Context
The friend details section had inconsistent text colors for unset values ("Not set"). While the City field used a lighter color for its unset state, Last Seen and Catch Up Frequency used a different opacity, creating visual inconsistency.

## Changes Made
- Standardized "Not set" text color across all fields using `AppColors.tertiaryLabel`
- Set values now consistently use `AppColors.secondaryLabel`
- Improved visual hierarchy between unset and set states
- Enhanced user experience by making the interaction state more clear

## Files Modified
- `friendtracker/Features/FriendDetail/Components/Atomic/FriendDetailComponents.swift`

## Visual Impact
- More consistent appearance across all friend detail fields
- Clearer distinction between unset and set values
- Better visual feedback for interactive fields
- Improved overall polish of the interface 