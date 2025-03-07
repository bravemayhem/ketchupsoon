import SwiftUI

/// A preview component that showcases all available form styles
struct FormStylesPreview: View {
    @State private var textValue = ""
    @State private var dateValue = Date()
    @State private var multilineValue = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                Text("Form Styles Preview")
                    .font(.custom("SpaceGrotesk-Bold", size: 24))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                
                // Standard style section
                styleSection(
                    title: "Standard Style",
                    style: .standard
                )
                
                // Accent Gradient style section
                styleSection(
                    title: "Accent Gradient Style",
                    style: .accentGradient
                )
                
                // Custom Gradient style section
                styleSection(
                    title: "Custom Gradient Style",
                    style: .gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.3)])
                )
                
                // Custom style section
                styleSection(
                    title: "Custom Style",
                    style: .custom(
                        background: Color.black.opacity(0.7),
                        border: LinearGradient(
                            colors: [Color.green.opacity(0.6), Color.yellow.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        cornerRadius: 20
                    )
                )
            }
            .padding(20)
        }
        .background(BackgroundView())
    }
    
    /// Creates a section for a specific style
    private func styleSection(title: String, style: FormStyle) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title
            Text(title)
                .font(.custom("SpaceGrotesk-SemiBold", size: 18))
                .foregroundColor(.white)
            
            // TextField example
            StyledTextField(
                title: "Text Field",
                placeholder: "Enter text...",
                text: $textValue,
                style: style
            )
            
            // DatePicker example
            SharedDatePicker(
                title: "Date Picker",
                selection: $dateValue,
                style: style
            )
            
            // TextEditor example
            StyledTextEditor(
                title: "Text Editor",
                placeholder: "Enter multiple lines of text...",
                text: $multilineValue,
                style: style
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
    }
}

#Preview {
    FormStylesPreview()
} 