import SwiftUI

/// A styled text field that applies consistent styling based on the provided FormStyle
public struct StyledTextField: View {
    // MARK: - Properties
    
    /// The title/label for the text field
    private let title: String
    
    /// The placeholder text
    private let placeholder: String
    
    /// Binding to the text value
    @Binding private var text: String
    
    /// The form style to apply
    private let style: FormStyle
    
    // MARK: - Initialization
    
    /// Create a styled text field
    /// - Parameters:
    ///   - title: The title/label for the text field
    ///   - placeholder: The placeholder text
    ///   - text: Binding to the text value
    ///   - style: The form style to apply (defaults to .standard)
    public init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        style: FormStyle = .standard
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.style = style
    }
    
    // MARK: - Body
    
    public var body: some View {
        let config = FormStyleConfiguration(style: style)
        
        return VStack(alignment: .leading, spacing: 6) {
            // Label
            Text(title)
                .formLabelStyle(style)
            
            // Text field with styling
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(config.inputFont)
                        .foregroundColor(config.placeholderColor)
                }
                
                TextField("", text: $text)
                    .font(config.inputFont)
                    .foregroundColor(config.textColor)
                    .accentColor(AppColors.accent)
                    .accessibilityLabel(title)
            }
            .contentShape(Rectangle())
            .formFieldStyle(style)
        }
    }
} 