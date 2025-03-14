import SwiftUI

/// A reusable badge component for buttons with different style options
struct ButtonBadge: View {
    // MARK: - Properties
    let count: Int
    var style: BadgeStyle = .standard
    var showZero: Bool = false
    var alignment: Alignment = .topTrailing
    var customOffset: CGPoint? = nil
    
    // MARK: - Badge Style Types
    enum BadgeStyle {
        case standard    // Default styling
        case capsule     // Capsule shaped badge for buttons/pills
        case prominent   // Larger, more attention-grabbing
        case subtle      // More subdued appearance
    }
    
    // MARK: - Body
    var body: some View {
        if count > 0 || showZero {
            ZStack {
                // Badge shape - either circle or capsule
                Group {
                    switch style {
                    case .capsule:
                        Capsule()
                            .fill(getBackgroundFill())
                            .frame(height: 20)
                            .frame(minWidth: 20)
                    default:
                        Circle()
                            .fill(getBackgroundFill())
                            .frame(width: badgeSize, height: badgeSize)
                    }
                }
                .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 0)
                
                // Badge text
                Text("\(count)")
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, style == .capsule ? 6 : 0)
            }
            .offset(x: customOffset?.x ?? defaultOffset.x, 
                    y: customOffset?.y ?? defaultOffset.y)
        }
    }
    
    // MARK: - Helper Methods
    // Instead of using @ViewBuilder, we return a specific ShapeStyle
    private func getBackgroundFill() -> AnyShapeStyle {
        let shapeStyle: AnyShapeStyle
        
        switch style {
        case .standard:
            shapeStyle = AnyShapeStyle(AppColors.accent)
        case .capsule:
            shapeStyle = AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.gradient1Start, AppColors.gradient1End]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .prominent:
            shapeStyle = AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.gradient5Start, AppColors.pureBlue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .subtle:
            shapeStyle = AnyShapeStyle(Color(UIColor.systemGray).opacity(0.7))
        }
        
        return shapeStyle
    }
    
    private var badgeSize: CGFloat {
        switch style {
        case .prominent:
            return 24
        case .subtle:
            return 18
        default:
            return 22
        }
    }
    
    private var fontSize: CGFloat {
        switch style {
        case .prominent:
            return 14
        case .subtle:
            return 10
        default:
            return 12
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .standard, .capsule:
            return AppColors.accent.opacity(0.5)
        case .prominent:
            return AppColors.pureBlue.opacity(0.4)
        case .subtle:
            return Color.black.opacity(0.2)
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .prominent:
            return 5
        case .subtle:
            return 2
        default:
            return 4
        }
    }
    
    private var defaultOffset: CGPoint {
        switch style {
        case .standard:
            return CGPoint(x: 8, y: -10)
        case .capsule:
            return CGPoint(x: 0, y: 0) // Capsules typically don't need offset
        case .prominent:
            return CGPoint(x: 10, y: -12)
        case .subtle:
            return CGPoint(x: 6, y: -8)
        }
    }
}

// MARK: - Extensions for View Modifiers
extension View {
    /// Adds a notification badge to a view
    func badged(count: Int, style: ButtonBadge.BadgeStyle = .standard, alignment: Alignment = .topTrailing, offset: CGPoint? = nil) -> some View {
        self.overlay(
            ButtonBadge(count: count, style: style, customOffset: offset),
            alignment: alignment
        )
    }
}

// MARK: - Preview
#Preview("Button Badges") {
    VStack(spacing: 30) {
        // Standard button badge
        Button(action: {}) {
            Text("Messages")
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
        }
        .badged(count: 5)
        
        // Capsule badge
        HStack {
            Text("Friend Requests")
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(20)
        }
        .badged(count: 3, style: .capsule, alignment: .trailing, offset: CGPoint(x: -10, y: 0))
        
        // Prominent badge
        Button(action: {}) {
            Image(systemName: "bell.fill")
                .font(.system(size: 20))
                .padding()
                .background(Circle().fill(Color.gray.opacity(0.3)))
        }
        .badged(count: 10, style: .prominent)
        
        // Subtle badge
        Button(action: {}) {
            Image(systemName: "envelope.fill")
                .font(.system(size: 20))
                .padding()
                .background(Circle().fill(Color.gray.opacity(0.3)))
        }
        .badged(count: 2, style: .subtle)
    }
    .padding()
    .background(Color.black)
} 