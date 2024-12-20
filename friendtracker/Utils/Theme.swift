import SwiftUI

enum AppTheme {
    // MARK: - Corner Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    
    // MARK: - Spacing
    static let spacingTiny: CGFloat = 4
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 16
    static let spacingLarge: CGFloat = 24
    static let spacingXLarge: CGFloat = 32
    
    // MARK: - Shadows
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    static let shadowSmall = ShadowStyle(
        color: Color.black.opacity(0.1),
        radius: 4,
        x: 0,
        y: 2
    )
    
    static let shadowMedium = ShadowStyle(
        color: Color.black.opacity(0.15),
        radius: 8,
        x: 0,
        y: 4
    )
    
    // MARK: - Text Styles
    static let titleFont: Font = .system(.title, design: .rounded, weight: .bold)
    static let headlineFont: Font = .system(.headline, design: .rounded, weight: .semibold)
    static let bodyFont: Font = .system(.body, design: .rounded)
    static let captionFont: Font = .system(.caption, design: .rounded)
    
    // MARK: - Animation
    static let defaultAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.7)
    
    // MARK: - Button Styles
    static func primaryButtonStyle() -> some ButtonStyle {
        return CustomButtonStyle(
            backgroundColor: AppColors.accent,
            foregroundColor: .white,
            cornerRadius: cornerRadiusMedium
        )
    }
    
    static func secondaryButtonStyle() -> some ButtonStyle {
        return CustomButtonStyle(
            backgroundColor: AppColors.systemBackground,
            foregroundColor: AppColors.accent,
            cornerRadius: cornerRadiusMedium
        )
    }
}

// Custom button style
struct CustomButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let cornerRadius: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, AppTheme.spacingLarge)
            .padding(.vertical, AppTheme.spacingMedium)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: AppTheme.shadowSmall.color,
                radius: AppTheme.shadowSmall.radius,
                x: AppTheme.shadowSmall.x,
                y: AppTheme.shadowSmall.y
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(AppTheme.defaultAnimation, value: configuration.isPressed)
    }
} 