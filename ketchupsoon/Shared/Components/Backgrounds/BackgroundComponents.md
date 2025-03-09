# Shared Background Components

This folder contains reusable background components for consistent styling across the KetchupSoon app.

## Components

### GradientBackground

A customizable gradient background component that can be used as the base for any background.

```swift
// Using a predefined style
GradientBackground.main

// Custom gradient
GradientBackground(
    colors: [AppColors.backgroundPrimary, AppColors.purple.opacity(0.3)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing,
    blurRadius: 2,
    opacity: 0.9
)
```

### DecorativeBubbles

Blurred circular elements that add depth to backgrounds.

```swift
// Using a predefined style
DecorativeBubbles.onboarding

// Custom bubble
DecorativeBubble(
    color: AppColors.mint.opacity(0.2),
    width: 300,
    height: 300,
    offset: CGPoint(x: 100, y: -50),
    blurRadius: 50
)
```

### DecorativeElements

Small decorative elements using offset-based positioning.

```swift
// Using a predefined set of elements
BackgroundElementFactory.homeElements()

// Individual elements
DecorativeElement(
    shape: Circle()
        .fill(AppColors.mint.opacity(0.8))
        .frame(width: 16, height: 16),
    offset: CGPoint(x: -140, y: 180)
)
```

### PositionedElements (formerly BackgroundElements)

Small decorative elements using position-based placement.

```swift
// Using a predefined set of elements
PositionedElementFactory.onboardingElements()

// Individual elements
PositionedCircle(
    position: CGPoint(x: 40, y: 200),
    color: AppColors.accent,
    size: 8
)

PositionedRectangle(
    position: CGPoint(x: UIScreen.main.bounds.width - 50, y: 300),
    color: AppColors.accentSecondary,
    width: 14,
    height: 14,
    rotation: Angle(degrees: 45)
)
```

### BackgroundDecoration

A wrapper type that can accommodate both types of decorative elements.

```swift
// Wrapping DecorativeElements
BackgroundDecoration.offsetBased(BackgroundElementFactory.homeElements())

// Wrapping PositionedElements
BackgroundDecoration.positionBased(PositionedElementFactory.profileElements())
```

### CompleteBackground

A complete background style that combines gradient, bubbles, and decorative elements.

```swift
// Using a predefined style
CompleteBackground.onboarding
CompleteBackground.home
CompleteBackground.profile
CompleteBackground.card
CompleteBackground.simple

// Custom complete background
CompleteBackground(
    gradient: GradientBackground(...),
    bubbles: DecorativeBubbles(...),
    decoration: .positionBased(PositionedElementFactory.onboardingElements()),
    noiseTexture: true,
    noiseOpacity: 0.04
)
```

### SharedBackgroundView

A drop-in replacement for the original BackgroundView.

```swift
// As a direct replacement for BackgroundView
SharedBackgroundView()

// With a specific style
SharedBackgroundView(customStyle: CompleteBackground.home)
```

## Usage Examples

See `BackgroundUsageExample.swift` for detailed examples of how to use these components in various scenarios.

## Migrating from Old BackgroundView

To replace the existing BackgroundView with the new shared components:

```swift
// Old code
BackgroundView()

// New code
SharedBackgroundView()
```

## Benefits

- **Consistency**: Ensures visual consistency across the app
- **Customization**: Allows for easy customization while maintaining the overall design language
- **Reusability**: Prevents code duplication
- **Maintainability**: Makes it easier to update the app's visual style in one place 