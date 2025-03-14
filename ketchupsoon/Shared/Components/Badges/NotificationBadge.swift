import SwiftUI

/// A reusable notification badge component with different style variants
struct NotificationBadge: View {
    // MARK: - Properties
    let count: Int
    var style: BadgeStyle = .standard
    var fontSize: CGFloat = 12
    var fontWeight: Font.Weight = .bold
    var showZero: Bool = false
    var customOffset: CGPoint? = nil
    
    // MARK: - Badge Style Types
    enum BadgeStyle {
        case standard       // Default red circle
        case accent         // Uses app accent color
        case gradient       // Uses a gradient fill
        case outline        // Outlined style
        case small          // Smaller size for icons
        case large          // Larger size for more prominence
    }
    
    // MARK: - Body
    var body: some View {
        // Only show if we have a positive count or showZero is true
        if count > 0 || showZero {
            ZStack {
                // Badge background
                Circle()
                    .fill(getBackgroundFill())
                    .frame(width: badgeSize.width, height: badgeSize.height)
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 0)
                    .overlay(
                        Group {
                            if style == .outline {
                                Circle()
                                    .stroke(AppColors.purple.opacity(0.4), lineWidth: 1)
                            }
                        }
                    )
                
                // Badge text
                Text("\(count)")
                    .font(.system(size: fontSize, weight: fontWeight))
                    .foregroundColor(.white)
            }
            .offset(x: customOffset?.x ?? defaultOffset.x, 
                    y: customOffset?.y ?? defaultOffset.y)
        }
    }
    
    // MARK: - Helper Methods
    private func getBackgroundFill() -> AnyShapeStyle {
        let shapeStyle: AnyShapeStyle
        
        switch style {
        case .standard:
            shapeStyle = AnyShapeStyle(Color.red)
        case .accent:
            shapeStyle = AnyShapeStyle(AppColors.accent)
        case .gradient:
            shapeStyle = AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.gradient5Start, AppColors.pureBlue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .outline:
            shapeStyle = AnyShapeStyle(Color(UIColor.systemGray6).opacity(0.3))
        case .small, .large:
            shapeStyle = AnyShapeStyle(AppColors.accent)
        }
        
        return shapeStyle
    }
    
    private var badgeSize: CGSize {
        switch style {
        case .small:
            return CGSize(width: 18, height: 18)
        case .large:
            return CGSize(width: 28, height: 28)
        default:
            return CGSize(width: 24, height: 24)
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .gradient:
            return AppColors.pureBlue.opacity(0.4)
        case .outline:
            return Color.clear
        default:
            return AppColors.accent.opacity(0.5)
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .small:
            return 2
        case .large:
            return 5
        default:
            return 4
        }
    }
    
    private var defaultOffset: CGPoint {
        switch style {
        case .small:
            return CGPoint(x: 1, y: -6)
        case .large:
            return CGPoint(x: 10, y: -12)
        default:
            return CGPoint(x: 8, y: -10)
        }
    }
}

// MARK: - Extension for View Modifier
extension View {
    /// Adds a notification badge to a view
    func withBadge(
        count: Int, 
        style: NotificationBadge.BadgeStyle = .standard, 
        fontSize: CGFloat = 12,
        fontWeight: Font.Weight = .bold,
        alignment: Alignment = .topTrailing, 
        offset: CGPoint? = nil
    ) -> some View {
        self.overlay(
            NotificationBadge(
                count: count, 
                style: style, 
                fontSize: fontSize,
                fontWeight: fontWeight,
                customOffset: offset
            ),
            alignment: alignment
        )
    }
}

// MARK: - Preview
#Preview("Notification Badges") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            // Standard badge
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    
                NotificationBadge(count: 5, style: .standard)
            }
            .frame(width: 40, height: 40)
            
            // Accent badge
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "bell.fill")
                    .foregroundColor(.white)
                    
                NotificationBadge(count: 12, style: .accent)
            }
            .frame(width: 40, height: 40)
            
            // Gradient badge
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "message.fill")
                    .foregroundColor(.white)
                    
                NotificationBadge(count: 3, style: .gradient)
            }
            .frame(width: 40, height: 40)
        }
        
        HStack(spacing: 20) {
            // Small badge
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "envelope.fill")
                    .foregroundColor(.white)
                    
                NotificationBadge(count: 1, style: .small, fontSize: 10)
            }
            .frame(width: 40, height: 40)
            
            // Large badge
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    
                NotificationBadge(count: 99, style: .large, fontSize: 14)
            }
            .frame(width: 40, height: 40)
            
            // Outline badge
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "star.fill")
                    .foregroundColor(.white)
                    
                NotificationBadge(count: 7, style: .outline)
            }
            .frame(width: 40, height: 40)
        }
        
        // Demo of the new extension
        HStack(spacing: 20) {
            Button(action: {}) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 24))
                    .frame(width: 40, height: 40)
            }
            .withBadge(count: 5)
            
            Image(systemName: "envelope.fill")
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .withBadge(count: 3, style: .gradient)
        }
    }
    .padding(40)
    .background(Color.black)
} 