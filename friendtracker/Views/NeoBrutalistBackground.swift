import SwiftUI

struct NeoBrutalistBackground: View {
    var body: some View {
        ZStack {
            // Drop shadow
            Rectangle()
                .fill(Color.black)
                .offset(x: Theme.shadowOffset.x, y: Theme.shadowOffset.y)
            
            // Main card background
            Rectangle()
                .fill(Theme.cardBackground)
                .overlay(
                    Rectangle()
                        .stroke(Theme.cardBorder, lineWidth: 2)
                )
        }
    }
} 