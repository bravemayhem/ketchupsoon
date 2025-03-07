# CustomNavigationBar Migration Guide

This guide explains how to migrate from the current `NavigationTab` implementation in `ContentView.swift` to the new reusable `CustomNavigationBar` component.

## Current Structure (NavigationTab)

The current implementation uses a `NavigationTab` struct in `ContentView.swift` that contains both the navigation bar and the tab item configuration:

```swift
private struct NavigationTab<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String
    @Binding var showImportOptions: Bool
    @Binding var showingDebugAlert: Bool
    @State private var showingSettings = false
    let clearData: () async -> Void
    let content: Content
    
    // ... init ...
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondaryLabel)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                content
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(AppColors.label)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showImportOptions = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(AppColors.label)
                    }
                    #if DEBUG
                    .onLongPressGesture {
                        showingDebugAlert = true
                    }
                    #endif
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .tabItem {
            Label(title, systemImage: icon)
        }
    }
}
```

## New Design Option

The component now offers two design styles:

1. **Classic Design**: The original design with standard navigation bar styling
2. **New Design**: A custom design based on Home1View with a status bar and unique header styling

### Classic Design Example

```swift
CustomNavigationBar(
    title: "Friends",
    subtitle: "Keep track of the details that matter to you",
    leadingButtonAction: {
        showSettings()
    },
    trailingButtonAction: {
        showAddOptions()
    }
)
```

### New Design Example

```swift
CustomNavigationBar(
    title: "Friends",  // Note: Title is only used for identification, not displayed in new design
    leadingIcon: "gear",
    leadingButtonAction: {
        showSettings()
    },
    trailingIcon: "plus",
    trailingButtonAction: {
        showAddOptions()
    },
    useNewDesign: true,
    profileEmoji: "👋"  // Optional custom emoji
)
```

## Migration Strategy

### Option 1: Full Migration with Classic Design (Recommended for Consistency)

Replace the current `NavigationTab` implementation with the new `CustomNavigationBarContainer`:

```swift
private struct NavigationTab<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String
    @Binding var showImportOptions: Bool
    @Binding var showingDebugAlert: Bool
    let clearData: () async -> Void
    let content: Content
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        subtitleAlwaysVisible: Bool = false,
        showImportOptions: Binding<Bool>,
        showingDebugAlert: Binding<Bool>,
        clearData: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._showImportOptions = showImportOptions
        self._showingDebugAlert = showingDebugAlert
        self.clearData = clearData
        self.content = content()
    }
    
    var body: some View {
        // Create a custom NavigationStack with our CustomNavigationBar
        NavigationStack {
            VStack(spacing: 0) {
                // Use CustomNavigationBar component
                CustomNavigationBar(
                    title: title,
                    subtitle: subtitle,
                    leadingButtonAction: {
                        showingSettings = true
                    },
                    enableDebugMode: true,
                    debugModeAction: {
                        showingDebugAlert = true
                    },
                    trailingButtonAction: {
                        showImportOptions = true
                    }
                )
                
                // Content
                content
            }
            .navigationBarHidden(true) // Hide the default navigation bar
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .tabItem {
            Label(title, systemImage: icon)
        }
    }
    
    @State private var showingSettings = false
}
```

### Option 2: Full Migration with New Design

Replace with the new design for a complete UI refresh:

```swift
private struct NavigationTab<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String
    @Binding var showImportOptions: Bool
    @Binding var showingDebugAlert: Bool
    let clearData: () async -> Void
    let content: Content
    
    // ... same init ...
    
    var body: some View {
        // Create a custom NavigationStack with our CustomNavigationBar
        NavigationStack {
            VStack(spacing: 0) {
                // Use CustomNavigationBar component with new design
                CustomNavigationBar(
                    title: title,
                    leadingIcon: "gear",
                    leadingButtonAction: {
                        showingSettings = true
                    },
                    trailingIcon: "plus",
                    trailingButtonAction: {
                        showImportOptions = true
                    },
                    enableDebugMode: true,
                    debugModeAction: {
                        showingDebugAlert = true
                    },
                    useNewDesign: true  // Enable new design
                )
                
                // Content
                content
            }
            .navigationBarHidden(true) // Hide the default navigation bar
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .tabItem {
            Label(title, systemImage: icon)
        }
    }
    
    @State private var showingSettings = false
}
```

### Option 3: Hybrid Approach

Keep the current `NavigationTab` structure but extract the navigation bar elements into the reusable component for specific views.

## Using CustomNavigationBar in Individual Views

For views that need a specific navigation bar layout different from the main tabs:

### Classic Design in Individual Views

```swift
struct CustomPageView: View {
    @State private var showingSettings = false
    @State private var showingHelp = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CustomNavigationBar(
                    title: "My Custom Page",
                    subtitle: "This is a custom page with its own navigation bar",
                    leadingIcon: "arrow.left",
                    leadingButtonAction: {
                        // Go back or dismiss
                    },
                    trailingIcon: "questionmark.circle",
                    trailingButtonAction: {
                        showingHelp = true
                    }
                )
                
                // Page content
                ScrollView {
                    // Your content here
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingHelp) {
                // Help view
            }
        }
    }
}
```

### New Design in Individual Views

```swift
struct CustomPageView: View {
    @State private var showingHelp = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CustomNavigationBar(
                    title: "My Custom Page",
                    leadingIcon: "arrow.left",
                    leadingButtonAction: {
                        // Go back or dismiss
                    },
                    trailingIcon: "questionmark.circle",
                    trailingButtonAction: {
                        showingHelp = true
                    },
                    useNewDesign: true
                )
                
                // Page content
                ScrollView {
                    // Your content here
                }
                .background(NewAppColors.deepBlue)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingHelp) {
                // Help view
            }
        }
        .background(NewAppColors.deepBlue)
    }
}
```

## Benefits of Migration

1. **Consistency**: All navigation bars have a consistent look and feel
2. **Flexibility**: Each page can customize its navigation bar as needed
3. **Maintainability**: Changes to navigation bar appearance can be made in one place
4. **Reusability**: The same component can be used throughout the app
5. **Simplified Code**: Navigation bar logic is encapsulated in a dedicated component
6. **Design Options**: Switch between classic and new designs easily 