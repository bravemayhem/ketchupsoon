import SwiftUI

/// A reusable navigation bar component that can be customized for different pages.
/// Allows for optional leading and trailing buttons with custom actions.
struct CustomNavigationBar: View {
    @State private var pendingFriendRequests: Int = 3
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
    var profileEmoji: String = "👨‍💻"
    
    var body: some View {
        NavigationBar
    }
 
    private var NavigationBar: some View {
        // Simplified ZStack without the extra space for status bar
        ZStack {
            // Background just for the navigation bar itself
            Rectangle()
                .fill(AppColors.headerBackground)
                .frame(height: 60)
            
            // Main navigation content
            HStack {  // Removed the spacing parameter to control it more precisely
                // Updated to match StatusBarView styling
                Text("ketchupsoon")
                    .font(.custom("SpaceGrotesk-Bold", size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0)),
                                Color(UIColor(red: 255/255, green: 138/255, blue: 66/255, alpha: 1.0))
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(
                        color: Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 0.7)),
                        radius: 8,
                        x: 0,
                        y: 0
                    )
                    .fixedSize(horizontal: true, vertical: false)  // Prevent text from being truncated
                
                Spacer()
                
                // Group all the icons in a secondary HStack with consistent spacing
                HStack(spacing: 12) {  // Adjusted spacing for equal distance between icons
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
                        .overlay(
                            // Badge for friend requests
                            Group {
                                if pendingFriendRequests > 0 {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(
                                                gradient: Gradient(colors: [AppColors.gradient5Start, AppColors.pureBlue]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 18, height: 18)
                                            .shadow(color: AppColors.pureBlue.opacity(0.4), radius: 2, x: 0, y: 0)
                                        
                                        Text("\(pendingFriendRequests)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .offset(x: 1, y: -6)
                                }
                            },
                            alignment: .topTrailing
                        )
                    }
                    
                    if showProfileEmoji {
                        ZStack {
                            Circle()
                                .fill(AppColors.circleBackground())
                                .frame(width: 40, height: 40)
                            
                            Text(profileEmoji)
                                .font(.system(size: 18))
                        }
                    }
                }
            }
            .padding(.horizontal, 12) // Add horizontal padding to keep items from the edges
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
    let showLeadingButton: Bool
    let showTrailingButton: Bool
    let leadingIcon: String
    let trailingIcon: String
    let leadingButtonAction: () -> Void
    let trailingButtonAction: () -> Void
    var enableDebugMode: Bool
    var debugModeAction: () -> Void
    let content: Content
    var profileEmoji: String = "👨‍💻"
    
    init(
        showLeadingButton: Bool = true,
        showTrailingButton: Bool = true,
        leadingIcon: String = "gear",
        trailingIcon: String = "plus",
        leadingButtonAction: @escaping () -> Void = {},
        trailingButtonAction: @escaping () -> Void = {},
        enableDebugMode: Bool = false,
        debugModeAction: @escaping () -> Void = {},
        profileEmoji: String = "👨‍💻",
        @ViewBuilder content: () -> Content
    ) {
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
        // Use the exact same configuration as the New Design preview
        CustomNavigationBarContainer(
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
            // Design Preview
            CustomNavigationBarContainer(
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

#Preview("Navigation Bar (Simplified)") {
    CustomNavigationBar(
        showLeadingButton: true,
        showTrailingButton: true,
        profileEmoji: "👨‍💻"
    )
    .padding()
    .background(Color.black)
}

#Preview("Custom Nav Bar Container") {
    CustomNavigationBarContainer(
        showLeadingButton: true,
        showTrailingButton: true,
        content: { Text("Hello World!") }
    )
    .padding()
    .background(Color.black)
}
