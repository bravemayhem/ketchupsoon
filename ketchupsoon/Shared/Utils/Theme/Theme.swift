// Theme: Handles the theme of the app
// This is a singleton that provides the theme of the app
// It is used in the App.swift file
// The file handles broader design system elements like spacing, shadows, typography, and component styles

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
        var color: Color
        var radius: CGFloat
        var x: CGFloat
        var y: CGFloat
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

// Custom text field style
struct AppTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .foregroundColor(AppColors.label)
    }
}

extension View {
    func appTextFieldStyle() -> some View {
        self.modifier(AppTextFieldStyle())
    }
}

// Search results popup style
struct SearchResultsPopupStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.secondarySystemBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
            .shadow(
                color: AppColors.label.opacity(0.1),
                radius: AppTheme.shadowSmall.radius,
                x: AppTheme.shadowSmall.x,
                y: AppTheme.shadowSmall.y
            )
    }
}

extension View {
    func searchResultsPopupStyle() -> some View {
        self.modifier(SearchResultsPopupStyle())
    }
}

#Preview("Theme") {
    ScrollView {
        VStack(alignment: .leading, spacing: AppTheme.spacingLarge) {
            // Typography
            VStack(alignment: .leading) {
                Text("Typography")
                    .font(.headline)
                Text("Title")
                    .font(AppTheme.titleFont)
                Text("Headline")
                    .font(AppTheme.headlineFont)
                Text("Body")
                    .font(AppTheme.bodyFont)
                Text("Caption")
                    .font(AppTheme.captionFont)
            }
            
            // Spacing
            VStack(alignment: .leading) {
                Text("Spacing")
                    .font(.headline)
                HStack {
                    spacingPreview(AppTheme.spacingTiny, "Tiny")
                    spacingPreview(AppTheme.spacingSmall, "Small")
                    spacingPreview(AppTheme.spacingMedium, "Medium")
                    spacingPreview(AppTheme.spacingLarge, "Large")
                    spacingPreview(AppTheme.spacingXLarge, "XLarge")
                }
            }
            
            // Corner Radius
            VStack(alignment: .leading) {
                Text("Corner Radius")
                    .font(.headline)
                HStack {
                    cornerRadiusPreview(AppTheme.cornerRadiusSmall, "Small")
                    cornerRadiusPreview(AppTheme.cornerRadiusMedium, "Medium")
                    cornerRadiusPreview(AppTheme.cornerRadiusLarge, "Large")
                }
            }
            
            // Shadows
            VStack(alignment: .leading) {
                Text("Shadows")
                    .font(.headline)
                HStack {
                    shadowPreview(AppTheme.shadowSmall, "Small")
                    shadowPreview(AppTheme.shadowMedium, "Medium")
                }
            }
            
            // Buttons
            VStack(alignment: .leading) {
                Text("Buttons")
                    .font(.headline)
                VStack(spacing: AppTheme.spacingMedium) {
                    Button("Primary Button") {}
                        .buttonStyle(AppTheme.primaryButtonStyle())
                    Button("Secondary Button") {}
                        .buttonStyle(AppTheme.secondaryButtonStyle())
                }
            }
        }
        .padding()
    }
    .background(AppColors.systemBackground)
}

private func spacingPreview(_ spacing: CGFloat, _ name: String) -> some View {
    VStack {
        Rectangle()
            .fill(AppColors.accent)
            .frame(width: spacing, height: spacing)
        Text(name)
            .font(.caption)
    }
}

private func cornerRadiusPreview(_ radius: CGFloat, _ name: String) -> some View {
    VStack {
        RoundedRectangle(cornerRadius: radius)
            .fill(AppColors.accent)
            .frame(width: 60, height: 60)
        Text(name)
            .font(.caption)
    }
}

private func shadowPreview(_ shadow: AppTheme.ShadowStyle, _ name: String) -> some View {
    VStack {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
            .fill(AppColors.secondarySystemBackground)
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
            .frame(width: 60, height: 60)
        Text(name)
            .font(.caption)
    }
} 