import SwiftUI

struct CustomTabBar: View {
    var selectedTab: Int
    var onTabSelected: (Int) -> Void
    
    // Tab items configuration
    private let tabItems = [
        TabItem(icon: "🏠", label: "home", index: 0),
        TabItem(icon: "📅", label: "pulse", index: 1),
        TabItem(icon: "⭐", label: "wishlist", index: 2),
        TabItem(icon: "😎", label: "profile", index: 3)
    ]
    
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 0) {
                ForEach(tabItems) { item in
                    CustomTabButton(
                        icon: item.icon,
                        label: item.label,
                        isActive: selectedTab == item.index
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            onTabSelected(item.index)
                        }
                    }
                }
            }
            .padding(.vertical, 10)
            .background(Color(AppColors.backgroundPrimary).opacity(0.9))
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.05)), alignment: .top)
        }
    }
}

// Tab Item model
struct TabItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let index: Int
}

// Tab Button component
struct CustomTabButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // Pill indicator for active tab
            if isActive {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(AppColors.accentGradient1)
                    .frame(width: 36, height: 5)
                    .offset(y: -2)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 36, height: 5)
                    .offset(y: -2)
            }
            
            Text(icon)
                .font(.system(size: 24))
                .foregroundColor(isActive ? .white : .white.opacity(0.5))
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(isActive ? .white : .white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// View extension to apply the tab bar overlay
extension View {
    func withCustomTabBar(selectedTab: Int, onTabSelected: @escaping (Int) -> Void) -> some View {
        self.overlay(
            CustomTabBar(selectedTab: selectedTab, onTabSelected: onTabSelected)
        )
    }
}

// Preview for the custom tab bar
struct CustomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()
            
            Text("Content Area")
                .font(.title)
                .foregroundColor(.white)
        }
        .withCustomTabBar(selectedTab: 0) { _ in }
    }
} 