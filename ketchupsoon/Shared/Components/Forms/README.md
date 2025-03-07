# Form Components & Styles

This directory contains reusable form components with a consistent styling system that can be applied to various form elements throughout the app.

## Available Components

- `StyledTextField`: A text field with customizable styling
- `SharedDatePicker`: A date picker with customizable styling
- `StyledTextEditor`: A text editor with customizable styling

## FormStyle System

The `FormStyle` enum provides a type-safe way to apply consistent styling to form components:

```swift
// Available styles:
FormStyle.standard           // Default style with dark background and subtle white border
FormStyle.accentGradient     // Pre-defined style with app's primary gradient border
FormStyle.gradient(colors:)  // Custom gradient border with specified colors
FormStyle.custom(...)        // Fully customizable style
```

## Usage Examples

### Text Field

```swift
// Standard style (default)
StyledTextField(
    title: "Email",
    placeholder: "john@example.com",
    text: $email
)

// Accent gradient style
StyledTextField(
    title: "Username",
    placeholder: "johndoe",
    text: $username,
    style: .accentGradient
)

// Custom gradient style
StyledTextField(
    title: "Password",
    placeholder: "Enter password",
    text: $password,
    style: .gradient(colors: [.red.opacity(0.5), .orange.opacity(0.3)])
)
```

### Date Picker

```swift
// Standard style (default)
SharedDatePicker(
    title: "Birthday",
    selection: $birthdate
)

// Accent gradient style
SharedDatePicker(
    title: "Event Date",
    selection: $eventDate,
    style: .accentGradient
)
```

### Text Editor

```swift
// Standard style (default)
StyledTextEditor(
    title: "Bio",
    placeholder: "Tell us about yourself...",
    text: $bio
)

// Custom height
StyledTextEditor(
    title: "Description",
    placeholder: "Enter description...",
    text: $description,
    height: 150
)
```

## Applying Styles to Custom Views

You can also apply the form styles to your own custom views using the provided modifiers:

```swift
// Apply form field style to any view
myCustomView
    .formFieldStyle(.accentGradient)

// Apply form label style to text
Text("My Label")
    .formLabelStyle(.standard)
```