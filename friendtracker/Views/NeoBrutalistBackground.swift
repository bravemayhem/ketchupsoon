import SwiftUI

struct NeoBrutalistBackground: View {
    @EnvironmentObject private var theme: Theme
    
    var body: some View {
        // Modern card background with subtle effects
        RoundedRectangle(cornerRadius: 8)
            .fill(theme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.cardBorder, lineWidth: 0.5)
            )
            .shadow(
                color: Color.black.opacity(theme.shadowOpacity),
                radius: theme.shadowRadius,
                x: theme.shadowOffset.x,
                y: theme.shadowOffset.y
            )
    }
} 