import SwiftUI

/// A base card component that provides consistent styling and layout for all cards in the app.
/// This component handles the common card appearance including background, shadow, and padding.
struct BaseCardView<Content: View>: View {
    let content: Content
    var padding: EdgeInsets = EdgeInsets(
        top: AppTheme.spacingMedium,
        leading: AppTheme.spacingMedium,
        bottom: AppTheme.spacingMedium,
        trailing: AppTheme.spacingMedium
    )
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    init(padding: EdgeInsets, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .padding(padding)
            .cardBackground()
    }
}

#Preview {
    VStack(spacing: 20) {
        BaseCardView {
            Text("Simple Card")
                .font(AppTheme.subtitleFont)
        }
        
        BaseCardView {
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading) {
                    Text("Complex Card")
                        .font(AppTheme.subtitleFont)
                    Text("With multiple elements")
                        .cardSecondaryText()
                }
            }
        }
    }
    .padding()
    .background(AppColors.systemBackground)
} 