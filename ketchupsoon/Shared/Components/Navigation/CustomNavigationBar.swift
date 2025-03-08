import SwiftUI

/// A reusable navigation bar component that can be customized for different pages.
/// Allows for optional leading and trailing buttons with custom actions.
struct CustomNavigationBar: View {
    // Title configuration
    var title: String
    var subtitle: String?
    var displayMode: NavigationBarItem.TitleDisplayMode = .large
    
    // Leading button (typically gear/settings)
    var showLeadingButton: Bool = true
    var leadingIcon: String = "gear"
    var leadingButtonAction: () -> Void = {}
    
    // Trailing button (typically add/plus)
    var showTrailingButton: Bool = true
    var trailingIcon: String = "plus"
    var trailingButtonAction: () -> Void = {}
    
    // Debug mode (optional long press gesture on trailing button)
    var enableDebugMode: Bool = false
    var debugModeAction: () -> Void = {}
    
    // Profile emoji
    var showProfileEmoji: Bool = true
    var profileEmoji: String = "👋"
    
    var body: some View {
        newDesignNavigationBar
    }
    
    // Original design (kept as reference, not used)
    /*
    private var classicNavigationBar: some View {
        HStack {
            if showLeadingButton {
                Button(action: leadingButtonAction) {
                    Image(systemName: leadingIcon)
                        .font(.title2)
                        .foregroundColor(AppColors.label)
                }
            } else {
                Spacer()
                    .frame(width: 44) // Reserve space for consistency
            }
            
            Spacer()
            
            VStack {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundColor(AppColors.label)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondaryLabel)
                }
            }
            
            Spacer()
            
            if showTrailingButton {
                Button(action: trailingButtonAction) {
                    Image(systemName: trailingIcon)
                        .font(.title2)
                        .foregroundColor(AppColors.label)
                }
                .modifier(ConditionalDebugModifier(
                    enableDebugMode: enableDebugMode,
                    action: debugModeAction
                ))
            } else {
                Spacer()
                    .frame(width: 44) // Reserve space for consistency
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    */
    
    // New design based on Home1View
    private var newDesignNavigationBar: some View {
        // Simplified ZStack without the extra space for status bar
        ZStack {
            // Background just for the navigation bar itself
            Rectangle()
                .fill(AppColors.headerBackground)
                .frame(height: 60)
            
            // Main navigation content
            HStack {
                // Changed from two separate Text views to a single Text with different styling
                Text("ketchup")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .kerning(-0.5) +
                Text("soon")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.accent)
                    .kerning(-0.5)
                
                Spacer()
                
                if showLeadingButton {
                    Button(action: leadingButtonAction) {
                        ZStack {
                            Circle()
                                .fill(AppColors.circleBackground())
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: leadingIcon)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                
                if showTrailingButton {
                    Button(action: trailingButtonAction) {
                        ZStack {
                            Circle()
                                .fill(AppColors.circleBackground())
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: trailingIcon)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    .modifier(ConditionalDebugModifier(
                        enableDebugMode: enableDebugMode,
                        action: debugModeAction
                    ))
                }
                
                if showProfileEmoji {
                    ZStack {
                        Circle()
                            .fill(AppColors.circleBackground())
                            .frame(width: 40, height: 40)
                        
                        Text(profileEmoji)
                            .font(.system(size: 18))
                    }
                    .padding(.trailing, 20)
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 60)
        }
    }
}

/// A modifier that adds a debug long press gesture when debug mode is enabled
struct ConditionalDebugModifier: ViewModifier {
    let enableDebugMode: Bool
    let action: () -> Void
    
    func body(content: Content) -> some View {
        if enableDebugMode {
            #if DEBUG
            content
                .onLongPressGesture {
                    action()
                }
            #else
            content
            #endif
        } else {
            content
        }
    }
}

/// An example of how to use CustomNavigationBar within a NavigationStack
struct CustomNavigationBarContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    let showLeadingButton: Bool
    let showTrailingButton: Bool
    let leadingIcon: String
    let trailingIcon: String
    let leadingButtonAction: () -> Void
    let trailingButtonAction: () -> Void
    var enableDebugMode: Bool
    var debugModeAction: () -> Void
    let content: Content
    var profileEmoji: String = "👋"
    
    init(
        title: String,
        subtitle: String? = nil,
        showLeadingButton: Bool = true,
        showTrailingButton: Bool = true,
        leadingIcon: String = "gear",
        trailingIcon: String = "plus",
        leadingButtonAction: @escaping () -> Void = {},
        trailingButtonAction: @escaping () -> Void = {},
        enableDebugMode: Bool = false,
        debugModeAction: @escaping () -> Void = {},
        profileEmoji: String = "👋",
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showLeadingButton = showLeadingButton
        self.showTrailingButton = showTrailingButton
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.leadingButtonAction = leadingButtonAction
        self.trailingButtonAction = trailingButtonAction
        self.enableDebugMode = enableDebugMode
        self.debugModeAction = debugModeAction
        self.profileEmoji = profileEmoji
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            // Use ZStack instead of VStack to ensure seamless background
            ZStack(alignment: .top) {
                // App background fills the entire screen
                AppColors.background
                    .ignoresSafeArea()
                
                // Content container
                VStack(spacing: 0) {
                    CustomNavigationBar(
                        title: title,
                        subtitle: subtitle,
                        showLeadingButton: showLeadingButton,
                        leadingIcon: leadingIcon,
                        leadingButtonAction: leadingButtonAction,
                        showTrailingButton: showTrailingButton,
                        trailingIcon: trailingIcon,
                        trailingButtonAction: trailingButtonAction,
                        enableDebugMode: enableDebugMode,
                        debugModeAction: debugModeAction,
                        profileEmoji: profileEmoji
                    )
                    
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Example Usage Preview
struct CustomNavigationBarPreview: View {
    var body: some View {
        CustomNavigationBarContainer(
            title: "Friends",
            subtitle: "Stay connected",
            showLeadingButton: true,
            showTrailingButton: true,
            leadingIcon: "gear",
            trailingIcon: "plus",
            leadingButtonAction: {
                print("Leading button tapped")
            },
            trailingButtonAction: {
                print("Trailing button tapped")
            },
            enableDebugMode: true,
            debugModeAction: {
                print("Debug mode activated")
            }
        ) {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(1...10, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 80)
                            .overlay(
                                Text("Item \(index)")
                                    .foregroundColor(.primary)
                            )
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Status Bar Style Modifier
struct CustomStatusBarStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    // Status bar background
                    Rectangle()
                        .fill(AppColors.background)
                        .ignoresSafeArea(edges: .top)
                        .frame(height: 0) // Invisible but will affect status bar color
                }
                .edgesIgnoringSafeArea(.top), 
                alignment: .top
            )
    }
}

extension View {
    func customStatusBarStyle() -> some View {
        modifier(CustomStatusBarStyleModifier())
    }
}

// MARK: - Enhanced Preview
struct CustomNavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Classic Design Preview
            CustomNavigationBarContainer(
                title: "Classic Design",
                subtitle: "Original layout",
                showLeadingButton: true,
                showTrailingButton: true,
                leadingIcon: "gear",
                trailingIcon: "plus",
                enableDebugMode: true
            ) {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(1...5, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 80)
                                .overlay(
                                    Text("Item \(index)")
                                        .foregroundColor(.primary)
                                )
                        }
                    }
                    .padding()
                }
            }
            .previewDisplayName("Classic Design")
            
            // New Design Preview
            CustomNavigationBarContainer(
                title: "New Design",
                subtitle: nil,
                showLeadingButton: true,
                showTrailingButton: true,
                leadingIcon: "gear",
                trailingIcon: "plus",
                enableDebugMode: true,
                profileEmoji: "🚀"
            ) {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(1...5, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.5))
                                .frame(height: 80)
                                .overlay(
                                    Text("Item \(index)")
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .padding()
                }
            }
            .previewDisplayName("New Design")
        }
    }
}

// This preview uses the macOS 14+ format
#Preview("Navigation Bar (Classic)") {
    CustomNavigationBar(
        title: "Classic Bar",
        subtitle: "No buttons",
        showLeadingButton: false,
        showTrailingButton: false
    )
    .padding()
    .background(Color.white)
}

#Preview("Navigation Bar (New Design)") {
    CustomNavigationBar(
        title: "",
        showLeadingButton: true,
        showTrailingButton: true,
        profileEmoji: "👨‍💻"
    )
    .padding()
    .background(Color.black)
}

// Old code:
// #Preview {
//     CustomNavigationBarPreview()
// } 
