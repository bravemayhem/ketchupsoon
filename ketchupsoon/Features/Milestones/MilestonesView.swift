import SwiftUI
import SwiftData

// This view is kept for backward compatibility but now forwards to MomentsView
struct MilestonesView: View {
    var body: some View {
        MomentsView()
    }
}

#Preview {
    NavigationStack {
        MilestonesView()
    }
} 