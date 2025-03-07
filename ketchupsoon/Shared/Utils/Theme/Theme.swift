// Theme: Handles the theme of the app
// This is a singleton that provides the theme of the app
// It is used in the App.swift file
// The file handles broader design system elements like spacing, shadows, typography, and component styles

import SwiftUI

enum AppTheme {
    // MARK: - Corner Radius - Updated for Gen Z aesthetic
    static let cornerRadiusSmall: CGFloat = 12
    static let cornerRadiusMedium: CGFloat = 20
    static let cornerRadiusLarge: CGFloat = 24
    static let cornerRadiusPill: CGFloat = 30
    
    // MARK: - Spacing
    static let spacingTiny: CGFloat = 4
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 16
    static let spacingLarge: CGFloat = 24
    static let spacingXLarge: CGFloat = 32
    
    // MARK: - Shadows
    struct ShadowStyle {
        var color: Color
        var radius: CGFloat
        var x: CGFloat
        var y: CGFloat
    }
    
    // Updated for clay morphism effect
    static let shadowSmall = ShadowStyle(
        color: Color.black.opacity(0.2),
        radius: 4,
        x: 0,
        y: 4
    )
    
    // Updated for glow effect
    static let shadowGlow = ShadowStyle(
        color: AppColors.accent.opacity(0.5),
        radius: 10,
        x: 0,
        y: 0
    )
    
    static let shadowMedium = ShadowStyle(
        color: Color.black.opacity(0.15),
        radius: 8,
        x: 0,
        y: 4
    )
    
    // MARK: - Text Styles - Updated for Gen Z aesthetic
    static let titleFont: Font = .system(size: 26, weight: .bold, design: .default)
    static let headlineFont: Font = .system(size: 20, weight: .bold, design: .default)
    static let subtitleFont: Font = .system(size: 18, weight: .semibold, design: .default)
    static let bodyFont: Font = .system(size: 16)
    static let captionFont: Font = .system(size: 12)
    
    // MARK: - Animation
    static let defaultAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.7)
    static let bounceAnimation: Animation = .spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.3)
    
    // MARK: - Card Styles
    static func clayCardStyle(cornerRadius: CGFloat = cornerRadiusLarge) -> some ViewModifier {
        return ClayCardModifier(cornerRadius: cornerRadius)
    }
    
    // MARK: - Button Styles
    static func primaryButtonStyle() -> some ButtonStyle {
        return GradientButtonStyle(
            gradientColors: [AppColors.gradient1Start, AppColors.gradient1End],
            foregroundColor: .white,
            cornerRadius: cornerRadiusPill,
            useGlow: true
        )
    }
    
    static func secondaryButtonStyle() -> some ButtonStyle {
        return GradientButtonStyle(
            gradientColors: [AppColors.gradient2Start, AppColors.gradient2End],
            foregroundColor: .white,
            cornerRadius: cornerRadiusPill,
            useGlow: true
        )
    }
    
    static func tertiaryButtonStyle() -> some ButtonStyle {
        return ClayButtonStyle(
            foregroundColor: .white,
            cornerRadius: cornerRadiusPill
        )
    }
    
    // MARK: - Icon Button Style
    static func iconButtonStyle() -> some ButtonStyle {
        return IconButtonStyle()
    }
}

// Clay Card Modifier
struct ClayCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(AppColors.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// Gradient Button Style
struct GradientButtonStyle: ButtonStyle {
    let gradientColors: [Color]
    let foregroundColor: Color
    let cornerRadius: CGFloat
    let useGlow: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, AppTheme.spacingLarge)
            .padding(.vertical, AppTheme.spacingMedium)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: useGlow ? gradientColors[0].opacity(0.5) : Color.black.opacity(0.2),
                radius: useGlow ? 10 : 4,
                x: 0,
                y: useGlow ? 0 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(AppTheme.bounceAnimation, value: configuration.isPressed)
    }
}

// Clay Button Style
struct ClayButtonStyle: ButtonStyle {
    let foregroundColor: Color
    let cornerRadius: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, AppTheme.spacingLarge)
            .padding(.vertical, AppTheme.spacingMedium)
            .background(Color.white.opacity(0.1))
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(AppTheme.bounceAnimation, value: configuration.isPressed)
    }
}

// Icon Button Style
struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(AppTheme.defaultAnimation, value: configuration.isPressed)
    }
}

// Custom text field style
struct AppTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .foregroundColor(AppColors.textPrimary)
    }
}

// Search results popup style
struct SearchResultsPopupStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 10,
                x: 0,
                y: 5
            )
    }
}

// View Extensions
extension View {
    func appTextFieldStyle() -> some View {
        self.modifier(AppTextFieldStyle())
    }
    
    func searchResultsPopupStyle() -> some View {
        self.modifier(SearchResultsPopupStyle())
    }
    
    func clayCard(cornerRadius: CGFloat = AppTheme.cornerRadiusLarge) -> some View {
        self.modifier(AppTheme.clayCardStyle(cornerRadius: cornerRadius))
    }
}

#Preview("Theme") {
    ScrollView {
        VStack(alignment: .leading, spacing: AppTheme.spacingLarge) {
            // Typography
            VStack(alignment: .leading) {
                Text("Typography")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Title")
                    .font(AppTheme.titleFont)
                    .foregroundColor(.white)
                Text("Headline")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(.white)
                Text("Subtitle")
                    .font(AppTheme.subtitleFont)
                    .foregroundColor(.white)
                Text("Body")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(.white)
                Text("Caption")
                    .font(AppTheme.captionFont)
                    .foregroundColor(.white)
            }
            .padding()
            .clayCard()
            
            // Spacing
            VStack(alignment: .leading) {
                Text("Spacing")
                    .font(.headline)
                    .foregroundColor(.white)
                HStack {
                    spacingPreview(AppTheme.spacingTiny, "Tiny")
                    spacingPreview(AppTheme.spacingSmall, "Small")
                    spacingPreview(AppTheme.spacingMedium, "Medium")
                    spacingPreview(AppTheme.spacingLarge, "Large")
                    spacingPreview(AppTheme.spacingXLarge, "XLarge")
                }
            }
            .padding()
            .clayCard()
            
            // Corner Radius
            VStack(alignment: .leading) {
                Text("Corner Radius")
                    .font(.headline)
                    .foregroundColor(.white)
                HStack {
                    cornerRadiusPreview(AppTheme.cornerRadiusSmall, "Small")
                    cornerRadiusPreview(AppTheme.cornerRadiusMedium, "Medium")
                    cornerRadiusPreview(AppTheme.cornerRadiusLarge, "Large")
                    cornerRadiusPreview(AppTheme.cornerRadiusPill, "Pill")
                }
            }
            .padding()
            .clayCard()
            
            // Shadows
            VStack(alignment: .leading) {
                Text("Effects")
                    .font(.headline)
                    .foregroundColor(.white)
                HStack {
                    shadowPreview(AppTheme.shadowSmall, "Clay")
                    shadowPreview(AppTheme.shadowGlow, "Glow")
                }
            }
            .padding()
            .clayCard()
            
            // Buttons
            VStack(alignment: .leading) {
                Text("Buttons")
                    .font(.headline)
                    .foregroundColor(.white)
                VStack(spacing: AppTheme.spacingMedium) {
                    Button("Primary Button") {}
                        .buttonStyle(AppTheme.primaryButtonStyle())
                    Button("Secondary Button") {}
                        .buttonStyle(AppTheme.secondaryButtonStyle())
                    Button("Tertiary Button") {}
                        .buttonStyle(AppTheme.tertiaryButtonStyle())
                }
            }
            .padding()
            .clayCard()
            
            // Text Fields
            VStack(alignment: .leading) {
                Text("Text Fields")
                    .font(.headline)
                    .foregroundColor(.white)
                TextField("Enter text...", text: .constant(""))
                    .appTextFieldStyle()
            }
            .padding()
            .clayCard()
        }
        .padding()
    }
    .background(AppColors.backgroundGradient)
}

private func spacingPreview(_ spacing: CGFloat, _ name: String) -> some View {
    VStack {
        Rectangle()
            .fill(AppColors.accent)
            .frame(width: spacing, height: spacing)
        Text(name)
            .font(.caption)
            .foregroundColor(.white)
    }
}

private func cornerRadiusPreview(_ radius: CGFloat, _ name: String) -> some View {
    VStack {
        RoundedRectangle(cornerRadius: radius)
            .fill(AppColors.accentGradient1)
            .frame(width: 60, height: 60)
        Text(name)
            .font(.caption)
            .foregroundColor(.white)
    }
}

private func shadowPreview(_ shadow: AppTheme.ShadowStyle, _ name: String) -> some View {
    VStack {
        if name == "Glow" {
            Circle()
                .fill(AppColors.accentGradient1)
                .frame(width: 60, height: 60)
                .shadow(
                    color: shadow.color,
                    radius: shadow.radius,
                    x: shadow.x,
                    y: shadow.y
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(
                    color: shadow.color,
                    radius: shadow.radius,
                    x: shadow.x,
                    y: shadow.y
                )
                .frame(width: 60, height: 60)
        }
        
        Text(name)
            .font(.caption)
            .foregroundColor(.white)
    }
} 
 
