import SwiftUI

/// A custom NavigationLink that hides the default chevron accessory view.
/// This component is useful when you want navigation functionality without the visual chevron indicator.
struct BetterNavigationLink<Label: View, Destination: View>: View {
    let label: Label
    let destination: Destination

    init(@ViewBuilder label: () -> Label,
         @ViewBuilder destination: () -> Destination) {
        self.label = label()
        self.destination = destination()
    }

    var body: some View {
        // HACK: ZStack with zero opacity + EmptyView
        // Hides default chevron accessory view for NavigationLink
        ZStack {
            NavigationLink {
                self.destination
            } label: {
                EmptyView()
            }
            .opacity(0)

            self.label
        }
    }
}

#Preview {
    NavigationStack {
        BetterNavigationLink {
            Text("Example Item")
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        } destination: {
            Text("Destination View")
        }
    }
} 