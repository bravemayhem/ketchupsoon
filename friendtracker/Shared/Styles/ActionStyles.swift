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