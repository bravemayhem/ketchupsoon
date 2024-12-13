import SwiftUI

struct NeoBrutalistBackground: View {
    var body: some View {
        // Modern card background with subtle effects
        RoundedRectangle(cornerRadius: 8)
            .fill(Theme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.cardBorder, lineWidth: 0.5)
            )
            .shadow(
                color: Color.black.opacity(Theme.shadowOpacity),
                radius: Theme.shadowRadius,
                x: Theme.shadowOffset.x,
                y: Theme.shadowOffset.y
            )
    }
} 