import SwiftUI

struct KetchupSectionView<Content: View>: View {
    let title: String
    let count: Int
    let showSeeAll: Bool
    let onSeeAllTapped: () -> Void
    let content: () -> Content
    
    init(
        title: String,
        count: Int,
        showSeeAll: Bool = true,
        onSeeAllTapped: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.count = count
        self.showSeeAll = showSeeAll
        self.onSeeAllTapped = onSeeAllTapped
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppColors.label)
                Spacer()
                if showSeeAll && count > 3 {
                    Button(action: onSeeAllTapped) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(AppColors.systemBackground)
            
            // Content
            VStack(spacing: AppTheme.spacingMedium) {
                content()
                
                if showSeeAll && count > 3 {
                    Button(action: onSeeAllTapped) {
                        Text("See All (\(count))")
                            .font(.subheadline)
                            .foregroundColor(AppColors.accent)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
            }
        }
    }
}

#Preview {
    KetchupSectionView(
        title: "Preview Section",
        count: 5,
        onSeeAllTapped: {}
    ) {
        Text("Content goes here")
            .padding()
    }
} 