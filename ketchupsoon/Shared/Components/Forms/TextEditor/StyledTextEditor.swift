import SwiftUI

/// A styled text editor that applies consistent styling based on the provided FormStyle
public struct StyledTextEditor: View {
    // MARK: - Properties
    
    /// The title/label for the text editor
    private let title: String
    
    /// The placeholder text
    private let placeholder: String
    
    /// Binding to the text value
    @Binding private var text: String
    
    /// The form style to apply
    private let style: FormStyle
    
    /// The height of the text editor
    private let height: CGFloat
    
    // MARK: - Initialization
    
    /// Create a styled text editor
    /// - Parameters:
    ///   - title: The title/label for the text editor
    ///   - placeholder: The placeholder text
    ///   - text: Binding to the text value
    ///   - style: The form style to apply (defaults to .standard)
    ///   - height: The height of the text editor (defaults to 100)
    public init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        style: FormStyle = .standard,
        height: CGFloat = 100
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.style = style
        self.height = height
    }
    
    // MARK: - Body
    
    public var body: some View {
        let config = FormStyleConfiguration(style: style)
        
        return VStack(alignment: .leading, spacing: 6) {
            // Label
            Text(title)
                .formLabelStyle(style)
            
            // Text editor with custom styling
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .fill(config.backgroundColor)
                    .frame(height: height)
                    .overlay(
                        RoundedRectangle(cornerRadius: config.cornerRadius)
                            .stroke(config.borderGradient, lineWidth: 1)
                    )
                
                if text.isEmpty {
                    Text(placeholder)
                        .font(config.inputFont)
                        .foregroundColor(config.placeholderColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                
                TextEditor(text: $text)
                    .font(config.inputFont)
                    .foregroundColor(config.textColor)
                    .frame(height: height)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    .accentColor(AppColors.accent)
                    .accessibilityLabel(title)
            }
        }
    }
} 