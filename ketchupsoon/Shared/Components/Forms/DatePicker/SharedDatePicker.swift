import SwiftUI

/// A styled date picker that applies consistent styling based on the provided FormStyle
public struct SharedDatePicker: View {
    // MARK: - Properties
    
    /// The title/label for the date picker
    private let title: String
    
    /// Binding to the selected date
    @Binding private var selection: Date
    
    /// The form style to apply
    private let style: FormStyle
    
    /// Flag to control the date picker sheet visibility
    @State private var showingDatePicker = false
    
    // MARK: - Initialization
    
    /// Create a styled date picker
    /// - Parameters:
    ///   - title: The title/label for the date picker
    ///   - selection: Binding to the selected date
    ///   - style: The form style to apply (defaults to .standard)
    public init(
        title: String,
        selection: Binding<Date>,
        style: FormStyle = .standard
    ) {
        self.title = title
        self._selection = selection
        self.style = style
    }
    
    // MARK: - Body
    
    public var body: some View {
        let config = FormStyleConfiguration(style: style)
        
        return VStack(alignment: .leading, spacing: 6) {
            // Label
            Text(title)
                .formLabelStyle(style)
            
            // Date display with styling
            Button(action: {
                showingDatePicker = true
            }) {
                HStack {
                    Text(DateFormatter.birthday.string(from: selection))
                        .font(config.inputFont)
                        .foregroundColor(config.textColor)
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .foregroundColor(AppColors.accent)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .buttonStyle(PressableButtonStyle())
            .formFieldStyle(style)
            
            // Date picker fullscreen cover
            .fullScreenCover(isPresented: $showingDatePicker) {
                ZStack {
                    // Background that matches the app theme
                    BackgroundView()
                    
                    // Our custom styled date picker
                    DatePickerFullscreenView(
                        selectedDate: $selection,
                        isShowingPicker: $showingDatePicker
                    )
                    .transition(.opacity)
                    .animation(.easeInOut, value: showingDatePicker)
                }
            }
        }
    }
}

/// The fullscreen date picker view
struct DatePickerFullscreenView: View {
    @Binding var selectedDate: Date
    @Binding var isShowingPicker: Bool
    
    var body: some View {
        // This is a placeholder. You would implement your custom date picker UI here, 
        // or reuse the existing StyledDatePicker component from your codebase.
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Date")
                    .font(.custom("SpaceGrotesk-Bold", size: 20))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Done") {
                    isShowingPicker = false
                }
                .font(.custom("SpaceGrotesk-Medium", size: 16))
                .foregroundColor(AppColors.accent)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            
            // Date picker
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .accentColor(AppColors.accent)
            .padding()
            .colorScheme(.dark)
            
            Spacer()
        }
        .background(Color.black.opacity(0.9))
    }
} 