import SwiftUI

/// Shared styling modifiers for card components throughout the app
struct CardStyles {
    /// Standard card background style with shadow
    struct Background: ViewModifier {
        func body(content: Content) -> some View {
            content
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                        .fill(AppColors.secondarySystemBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)   .stroke(AppColors.systemGray.opacity(0.10), lineWidth: 0.5) // Optional border
                            )
                        .shadow(
                            color: AppTheme.shadowSmall.color,
                            radius: AppTheme.shadowSmall.radius,
                            x: AppTheme.shadowSmall.x,
                            y: AppTheme.shadowSmall.y
                        )
                )
        }
    }
    
    /// Standard card button style
    struct Button: ViewModifier {
        let style: ButtonStyle
        
        enum ButtonStyle {
            case primary
            case secondary
            case outline
            
            var backgroundColor: Color {
                switch self {
                case .primary: return AppColors.accent
                case .secondary, .outline: return .clear
                }
            }
            
            var foregroundColor: Color {
                switch self {
                case .primary: return .white
                case .secondary, .outline: return AppColors.accent
                }
            }
        }
        
        func body(content: Content) -> some View {
            content
                .font(AppTheme.headlineFont)
                .foregroundColor(style.foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.spacingSmall)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                        .fill(style.backgroundColor)
                )
        }
    }
    
    /// Secondary text style for card content
    struct SecondaryText: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(AppTheme.captionFont)
                .foregroundColor(AppColors.secondaryLabel)
                .lineLimit(1)
        }
    }
}

// View extensions for easier usage
extension View {
    func cardBackground() -> some View {
        modifier(CardStyles.Background())
    }
    
    func cardButton(style: CardStyles.Button.ButtonStyle) -> some View {
        modifier(CardStyles.Button(style: style))
    }
    
    func cardSecondaryText() -> some View {
        modifier(CardStyles.SecondaryText())
    }
}

#Preview("Card Styles") {
    ScrollView {
        VStack(spacing: AppTheme.spacingLarge) {
            // Card Background
            VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
                Text("Card Background")
                    .font(AppTheme.headlineFont)
                
                VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                    Text("Card Title")
                        .font(AppTheme.headlineFont)
                    Text("Card content with background and shadow")
                        .font(AppTheme.bodyFont)
                }
                .padding()
                .cardBackground()
            }
            
            // Card Buttons
            VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
                Text("Card Buttons")
                    .font(AppTheme.headlineFont)
                
                Button("Primary Button") {}
                    .cardButton(style: .primary)
                
                Button("Secondary Button") {}
                    .cardButton(style: .secondary)
                
                Button("Outline Button") {}
                    .cardButton(style: .outline)
            }
            
            // Card Text Styles
            VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
                Text("Card Text")
                    .font(AppTheme.headlineFont)
                
                VStack(alignment: .leading) {
                    Text("Primary Text")
                        .font(AppTheme.bodyFont)
                    Text("Secondary Text Style")
                        .cardSecondaryText()
                    Text("This is a very long text that should be limited to one line and use secondary styling")
                        .cardSecondaryText()
                }
                .padding()
                .cardBackground()
            }
            
            // Complete Card Example
            VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
                Text("Complete Card")
                    .font(AppTheme.headlineFont)
                
                VStack(spacing: AppTheme.spacingMedium) {
                    VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                        Text("Card Title")
                            .font(AppTheme.headlineFont)
                        Text("Main content of the card")
                            .font(AppTheme.bodyFont)
                        Text("Additional information")
                            .cardSecondaryText()
                    }
                    
                    Divider()
                    
                    HStack(spacing: AppTheme.spacingMedium) {
                        Button("Cancel") {}
                            .cardButton(style: .secondary)
                        Button("Confirm") {}
                            .cardButton(style: .primary)
                    }
                }
                .padding()
                .cardBackground()
            }
        }
        .padding()
    }
    .background(AppColors.systemBackground)
} 
