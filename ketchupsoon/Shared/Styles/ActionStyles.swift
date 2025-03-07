import SwiftUI

struct ActionButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(AppColors.accent)
    }
}

struct ActionLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
                .foregroundColor(AppColors.accent)
        } icon: {
            configuration.icon
                .foregroundColor(AppColors.accent)
        }
    }
}

extension View {
    func actionButtonStyle() -> some View {
        modifier(ActionButtonStyle())
    }
}

extension Label {
    func actionLabelStyle() -> some View {
        self.labelStyle(ActionLabelStyle())
    }
}

#Preview("Action Styles") {
    VStack(alignment: .leading, spacing: AppTheme.spacingLarge) {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            Text("Action Buttons")
                .font(AppTheme.subtitleFont)
            
            Button("Action Button") {}
                .actionButtonStyle()
            
            Button(action: {}) {
                Image(systemName: "star.fill")
            }
            .actionButtonStyle()
        }
        
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            Text("Action Labels")
                .font(AppTheme.subtitleFont)
            
            Label("Star Item", systemImage: "star.fill")
                .actionLabelStyle()
            
            Label("Add to Calendar", systemImage: "calendar.badge.plus")
                .actionLabelStyle()
            
            Label("Share", systemImage: "square.and.arrow.up")
                .actionLabelStyle()
        }
    }
    .padding()
    .background(AppColors.systemBackground)
} 