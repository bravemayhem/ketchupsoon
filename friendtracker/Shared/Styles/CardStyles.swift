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