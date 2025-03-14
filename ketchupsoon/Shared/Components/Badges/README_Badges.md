# Badge Components

This directory contains reusable badge components for the KetchupSoon app. These components provide a consistent visual language for notifications, status indicators, and other badge-style elements throughout the app.

## Available Badge Components

### NotificationBadge

A customizable notification badge component with different style variants. Perfect for showing notification counts or indicating unread items.

```swift
// Basic usage
NotificationBadge(count: 5)

// With styling options
NotificationBadge(
    count: 3,
    style: .gradient,
    fontSize: 10,
    fontWeight: .semibold
)

// As an overlay on another view
YourView()
    .overlay(
        NotificationBadge(count: pendingNotifications, style: .accent),
        alignment: .topTrailing
    )
```

#### Available Styles:
- `.standard` - Default red circle
- `.accent` - Uses app accent color
- `.gradient` - Uses a gradient fill
- `.outline` - Outlined style
- `.small` - Smaller size for icons
- `.large` - Larger size for more prominence

### ButtonBadge

A badge specifically designed for buttons and UI elements, with a convenient View extension for easier use.

```swift
// Basic usage with extension
Button { /* action */ } label: {
    Text("Messages")
}
.badged(count: 5)

// With styling options
Button { /* action */ } label: {
    Text("Friend Requests")
}
.badged(count: 3, style: .capsule, alignment: .trailing)

// Manual usage
ButtonBadge(count: 7, style: .prominent)
```

#### Available Styles:
- `.standard` - Default styling
- `.capsule` - Capsule shaped badge for buttons/pills
- `.prominent` - Larger, more attention-grabbing
- `.subtle` - More subdued appearance

### StatusBadge

A simple badge component for showing status indicators like online/offline, availability, etc.

```swift
// Basic usage with extension
AvatarView()
    .withStatus(.online)

// With styling options
AvatarView()
    .withStatus(.busy, size: .medium, alignment: .topTrailing)

// Custom status colors
AvatarView()
    .withStatus(.custom(AppColors.purple), size: .small)
```

#### Available Statuses:
- `.online` - Green indicator
- `.offline` - Gray indicator
- `.away` - Yellow indicator
- `.busy` - Red indicator
- `.custom(Color)` - Custom color indicator

#### Available Sizes:
- `.tiny` - 8pt (very discreet)
- `.small` - 12pt (default)
- `.medium` - 16pt
- `.large` - 20pt

## Best Practices

1. Use the same badge style for similar UI elements throughout your app.
2. Consider the size and position of badges - they should be noticeable but not overwhelming.
3. Use the appropriate badge component for each use case:
   - `NotificationBadge` for notification counts
   - `ButtonBadge` for action elements
   - `StatusBadge` for showing status

4. Use the convenience extensions whenever possible for cleaner code:
   - `.badged()` for adding count badges
   - `.withStatus()` for adding status indicators

## Implementation Examples

### Friend Request Button with Badge

```swift
Button(action: viewFriendRequests) {
    Text("Requests")
        .padding(.horizontal, 16)
        .frame(height: 34)
        .background(Color.gray.opacity(0.3))
        .clipShape(Capsule())
}
.badged(count: pendingRequests, style: .standard)
```

### Online Status for User Avatar

```swift
ProfileImageView(user: currentUser)
    .withStatus(.online, size: .small)
```

### Notification Icon with Badge

```swift
Image(systemName: "bell.fill")
    .font(.system(size: 20))
    .padding()
    .overlay(
        NotificationBadge(count: notifications, style: .gradient),
        alignment: .topTrailing
    )
``` 