import SwiftUI

/// A reusable avatar view for displaying friends
/// Can be used in both selectable and non-selectable contexts
struct FriendAvatarView: View {
    // Required parameters
    let emoji: String
    let name: String
    
    // Optional parameters with defaults
    var size: CGFloat = 90
    var gradientColors: [Color] = [AppColors.gradient1Start, AppColors.gradient1End]
    var nameFontSize: CGFloat = 14
    var emojiFontSize: CGFloat = 30
    
    // Selection related parameters (optional)
    var isSelected: Bool = false
    var onSelect: (() -> Void)? = nil
    
    // Glow effect control
    var useGlowEffect: Bool = false
    var glowRadius: CGFloat = 6
    var glowOpacity: Double = 0.5
    
    // Computed properties
    private var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var innerCircleSize: CGFloat {
        size * 0.89 // Maintain proportion between outer and inner circles
    }
    
    private var isSelectable: Bool {
        onSelect != nil
    }
    
    var body: some View {
        Button(action: {
            onSelect?()
        }) {
            VStack {
                ZStack {
                    // Selection glow for selected friends (only if selectable)
                    if isSelected {
                        Circle()
                            .fill(gradient)
                            .opacity(0.3)
                            .frame(width: size + 6, height: size + 6)
                    }
                    
                    // Main avatar circle
                    Circle()
                        .fill(gradient)
                        .frame(width: size, height: size)
                        .shadow(color: gradientColors[0].opacity(0.3), radius: 6, x: 0, y: 0)
                        .conditionalModifier(useGlowEffect, modifier: GlowModifier(color: gradientColors[0], radius: glowRadius, opacity: glowOpacity))
                    
                    // Inner circle
                    Circle()
                        .fill(AppColors.cardBackground)
                        .frame(width: innerCircleSize, height: innerCircleSize)
                    
                    // Emoji
                    Text(emoji)
                        .font(.system(size: emojiFontSize))
                    
                    // Selection indicator (only if selected and selectable)
                    if isSelected {
                        Circle()
                            .fill(gradient)
                            .frame(width: size/3, height: size/3)
                            .overlay(
                                Text("✓")
                                    .font(.system(size: size/6, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: size/3, y: -size/3)
                    }
                }
                
                // Friend name
                Text(name)
                    .font(.system(size: nameFontSize))
                    .foregroundColor(.white)
                    .padding(.top, 5)
            }
        }
        .buttonStyle(PlainButtonStyle()) // Prevent default button styling
        .disabled(onSelect == nil) // Only enable button if onSelect is provided
    }
    
    // Convenience initializer that takes a FriendItem
    init(friend: FriendItem, isSelected: Bool = false, onSelect: (() -> Void)? = nil) {
        self.emoji = friend.emoji
        self.name = friend.name
        self.gradientColors = friend.gradient
        self.isSelected = isSelected
        self.onSelect = onSelect
    }
    
    // Convenience initializer with simpler parameters for non-selectable use
    init(emoji: String, name: String, gradient: LinearGradient, size: CGFloat = 60, emojiFontSize: CGFloat = 20, nameFontSize: CGFloat = 12) {
        self.emoji = emoji
        self.name = name
        if let gradientValue = Mirror(reflecting: gradient).descendant("gradient") as? Gradient {
            self.gradientColors = gradientValue.stops.map { $0.color }
        } else {
            self.gradientColors = [AppColors.gradient1Start, AppColors.gradient1End]
        }
        self.size = size
        self.emojiFontSize = emojiFontSize
        self.nameFontSize = nameFontSize
        self.useGlowEffect = true // Enable glow for this initializer
    }
}

// Empty modifier for when glow is not needed
struct NoGlowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

// Helper for glow effect to match what was in CreateMeetupView
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(
                content
                    .blur(radius: radius)
                    .opacity(opacity)
            )
    }
}

// FriendItem struct for use with FriendAvatarView
struct FriendItem: Identifiable {
    let id: String
    let name: String
    let bio: String    
    let phoneNumber: String
    let email: String
    let birthday: Date
    let emoji: String
    let lastHangout: String
    let gradient: [Color]
}

// MARK: - Conditional Modifier Extension

extension View {
    @ViewBuilder
    func conditionalModifier<M: ViewModifier>(_ condition: Bool, modifier: M) -> some View {
        if condition {
            self.modifier(modifier)
        } else {
            self
        }
    }
} 
