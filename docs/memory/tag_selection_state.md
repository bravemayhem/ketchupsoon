# Tag Selection State Management

## Overview
This document describes the implementation of tag selection state management in the FriendTracker app, specifically how we handle tag selection for both existing friends and new friends during onboarding.

## Problem
Initially, the tag selection UI didn't provide proper visual feedback when selecting tags for new friends during onboarding. This was because the tag selection logic was primarily built around existing friends and their tag relationships, but needed to handle a temporary selection state for new friends before they're created.

## Solution
We implemented a type-safe approach using an enum to represent the two distinct tag selection scenarios:

```swift
enum TagSelectionState {
    case existingFriend(Friend)
    case newFriend(selectedTags: Set<Tag.ID>)
    
    func isSelected(_ tag: Tag) -> Bool {
        switch self {
        case .existingFriend(let friend):
            return friend.tags.contains(where: { $0.id == tag.id })
        case .newFriend(let selectedTags):
            return selectedTags.contains(tag.id)
        }
    }
}
```

### Key Components

1. **TagsSection**
   - Takes a `TagSelectionState` to determine tag selection
   - Uses the state's `isSelected` method to show proper visual feedback
   - Handles both edit mode and normal mode tag interactions

2. **TagsContentView**
   - Manages the overall tag management UI
   - Computes the friend reference from selection state when needed
   - Handles the add tag sheet presentation

3. **TagsSelectionView**
   - Creates the appropriate selection state based on initialization
   - Manages tag selection/deselection for both scenarios
   - Handles tag deletion in edit mode

## Benefits
- Type-safe handling of different selection scenarios
- Clear separation of concerns between existing and new friend tag management
- Consistent visual feedback across both use cases
- Better maintainability through explicit state management

## Usage Example
```swift
// For existing friends
TagsSelectionView(friend: existingFriend)

// For new friends during onboarding
TagsSelectionView(selectedTags: $viewModel.selectedTags)
```

## Implementation Details

### Tag Selection
- For existing friends: Uses the friend's tags array through SwiftData relationships
- For new friends: Uses a temporary Set<Tag> binding that gets applied when the friend is created

### Visual Feedback
The `TagButton` component shows selection state through:
- Background color change
- Checkmark icon
- Text color change

### State Management
- Selection state is computed based on the initialization type
- Changes are immediately reflected in the UI
- For existing friends, changes are persisted through SwiftData
- For new friends, changes are held in memory until friend creation 