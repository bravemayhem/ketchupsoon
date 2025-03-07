import SwiftUI

/// Defines the available styles for form fields
public enum FormStyle {
    /// Standard style with dark background and subtle white border
    case standard
    
    /// Gradient style with customizable gradient border colors
    case gradient(colors: [Color])
    
    /// Custom style with full control over appearance
    case custom(background: Color, border: LinearGradient, cornerRadius: CGFloat)
    
    /// Pre-defined gradient style with the app's primary accent colors
    public static var accentGradient: FormStyle {
        .gradient(colors: [AppColors.accent.opacity(0.5), AppColors.accentSecondary.opacity(0.3)])
    }
}

/// Configuration for form field styling
public struct FormStyleConfiguration {
    var backgroundColor: Color
    var borderGradient: LinearGradient
    var cornerRadius: CGFloat
    var textColor: Color
    var placeholderColor: Color
    var labelFont: Font
    var labelColor: Color
    var inputFont: Font
    var height: CGFloat
    var padding: EdgeInsets
    
    /// Initialize with default values for a given style
    init(style: FormStyle) {
        switch style {
        case .standard:
            self.backgroundColor = Color(UIColor(red: 21/255, green: 17/255, blue: 50/255, alpha: 0.7))
            self.borderGradient = LinearGradient(
                colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            self.cornerRadius = 16
            
        case .gradient(let colors):
            self.backgroundColor = Color.white.opacity(0.08)
            self.borderGradient = LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            self.cornerRadius = 12
            
        case .custom(let background, let border, let radius):
            self.backgroundColor = background
            self.borderGradient = border
            self.cornerRadius = radius
        }
        
        // Default values for all styles
        self.textColor = .white
        self.placeholderColor = .white.opacity(0.4)
        self.labelFont = .custom("SpaceGrotesk-Regular", size: 14)
        self.labelColor = .white.opacity(0.7)
        self.inputFont = .custom("SpaceGrotesk-Regular", size: 16)
        self.height = 50
        self.padding = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    }
}

/// ViewModifier to apply form field styling
struct FormFieldModifier: ViewModifier {
    let style: FormStyle
    
    func body(content: Content) -> some View {
        let config = FormStyleConfiguration(style: style)
        
        return content
            .frame(height: config.height)
            .padding(config.padding)
            .background(
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .fill(config.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: config.cornerRadius)
                            .stroke(config.borderGradient, lineWidth: 1)
                    )
            )
    }
}

/// ViewModifier for form field labels
struct FormLabelModifier: ViewModifier {
    let style: FormStyle
    
    func body(content: Content) -> some View {
        let config = FormStyleConfiguration(style: style)
        
        return content
            .font(config.labelFont)
            .foregroundColor(config.labelColor)
    }
}

// Extension to make it easier to apply the styles
extension View {
    /// Apply form field styling
    public func formFieldStyle(_ style: FormStyle) -> some View {
        modifier(FormFieldModifier(style: style))
    }
    
    /// Apply form label styling
    public func formLabelStyle(_ style: FormStyle) -> some View {
        modifier(FormLabelModifier(style: style))
    }
} 