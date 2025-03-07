import SwiftUI

// A button style that provides a subtle scale and glow effect when pressed
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .shadow(
                color: configuration.isPressed ? 
                    AppColors.accent.opacity(0.3) : 
                    Color.clear,
                radius: configuration.isPressed ? 5 : 0
            )
    }
}

// Extension for GradientButtonStyle with disabled state handling
extension GradientButtonStyle {
    // Convenience initializer for primary action buttons with disabled state
    static func primary(isDisabled: Bool = false) -> GradientButtonStyle {
        GradientButtonStyle(
            gradientColors: isDisabled ? 
                [Color.gray.opacity(0.5), Color.gray.opacity(0.6)] : 
                [AppColors.gradient1Start, AppColors.gradient1End],
            foregroundColor: .white,
            cornerRadius: 16,
            useGlow: !isDisabled
        )
    }
}

// A secondary button style with border
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
} 