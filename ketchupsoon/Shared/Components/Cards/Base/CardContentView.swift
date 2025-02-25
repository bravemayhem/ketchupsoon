import SwiftUI

/// A shared component for standardizing card content layout across the app.
/// This component provides a consistent way to display a profile image with
/// primary and secondary content.
struct CardContentView<SecondaryContent: View>: View {
    let friend: Friend
    let showChevron: Bool
    @ViewBuilder let secondaryContent: () -> SecondaryContent
    
    init(
        friend: Friend,
        showChevron: Bool = true,
        @ViewBuilder secondaryContent: @escaping () -> SecondaryContent
    ) {
        self.friend = friend
        self.showChevron = showChevron
        self.secondaryContent = secondaryContent
    }
    
    var body: some View {
        HStack(spacing: AppTheme.spacingMedium) {
            ProfileImage(friend: friend)
            
            VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                Text(friend.name)
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppColors.label)
                    .lineLimit(1)
                
                secondaryContent()
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.secondaryLabel)
                    .font(.system(size: 14, weight: .semibold))
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Basic usage
        BaseCardView {
            CardContentView(friend: Friend(name: "Test Friend")) {
                Text("Secondary text").cardSecondaryText()
            }
        }
        
        // Multiple secondary items
        BaseCardView {
            CardContentView(friend: Friend(name: "Test Friend")) {
                VStack(alignment: .leading) {
                    Text("First line").cardSecondaryText()
                    Text("Second line").cardSecondaryText()
                }
            }
        }
        
        // Without chevron
        BaseCardView {
            CardContentView(
                friend: Friend(name: "Test Friend"),
                showChevron: false
            ) {
                Text("No chevron").cardSecondaryText()
            }
        }
    }
    .padding()
    .background(AppColors.systemBackground)
} 