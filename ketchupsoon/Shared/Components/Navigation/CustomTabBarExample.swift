import SwiftUI

struct CustomTabBarExample: View {
    @State private var selectedTab = 0
    
    var body: some View {
        // Main content
        ZStack {
            // Background
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            // Content based on selected tab
            VStack {
                switch selectedTab {
                case 0:
                    homeTabContent
                case 1:
                    pulseTabContent
                case 2:
                    wishlistTabContent
                case 3:
                    profileTabContent
                default:
                    homeTabContent
                }
            }
            .padding()
        }
        // Apply custom tab bar
        .withCustomTabBar(selectedTab: selectedTab) { tab in
            selectedTab = tab
        }
    }
    
    // MARK: - Tab Content Views
    
    var homeTabContent: some View {
        VStack(spacing: 20) {
            Text("Home")
                .font(AppTheme.titleFont)
                .foregroundColor(.white)
            
            Text("Main home screen content")
                .foregroundColor(.white)
                .padding()
                .clayCard()
        }
    }
    
    var pulseTabContent: some View {
        VStack(spacing: 20) {
            Text("Ketchup Pulse")
                .font(AppTheme.titleFont)
                .foregroundColor(.white)
            
            Text("See upcoming ketchups and activity")
                .foregroundColor(.white)
                .padding()
                .clayCard()
        }
    }
    
    var wishlistTabContent: some View {
        VStack(spacing: 20) {
            Text("Wishlist")
                .font(AppTheme.titleFont)
                .foregroundColor(.white)
            
            Text("Wishlist content goes here")
                .foregroundColor(.white)
                .padding()
                .clayCard()
        }
    }
    
    var profileTabContent: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(AppTheme.titleFont)
                .foregroundColor(.white)
            
            Text("User profile and settings")
                .foregroundColor(.white)
                .padding()
                .clayCard()
        }
    }
}

struct CustomTabBarExample_Previews: PreviewProvider {
    static var previews: some View {
        CustomTabBarExample()
    }
} 