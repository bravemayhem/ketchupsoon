import SwiftUI

/// Renamed the custom gradient view to resolve ambiguity
struct KetchupGradientBackground: View {
    // Gradient colors
    var colors: [Color]
    
    // Gradient direction
    var startPoint: UnitPoint
    var endPoint: UnitPoint
    
    // Optional blur amount
    var blurRadius: CGFloat?
    
    // Optional opacity
    var opacity: Double = 1.0
    
    // Initialize with colors and gradient direction
    init(
        colors: [Color],
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing,
        blurRadius: CGFloat? = nil,
        opacity: Double = 1.0
    ) {
        self.colors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.blurRadius = blurRadius
        self.opacity = opacity
    }
    
    // Convenience initializer with a pre-defined gradient
    init(
        gradient: LinearGradient,
        blurRadius: CGFloat? = nil,
        opacity: Double = 1.0
    ) {
        // In SwiftUI LinearGradient we can't directly access colors and points
        // Using default values instead
        self.colors = []
        self.startPoint = .topLeading
        self.endPoint = .bottomTrailing
        self.blurRadius = blurRadius
        self.opacity = opacity
    }
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint
        )
        .opacity(opacity)
        .ifApply(blurRadius != nil) { view in
            view.blur(radius: blurRadius ?? 0)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Predefined Backgrounds
extension KetchupGradientBackground {
    /// Main app background
    static var main: KetchupGradientBackground {
        KetchupGradientBackground(
            colors: [
                AppColors.backgroundPrimary,
                AppColors.backgroundSecondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Onboarding background
    static var onboarding: KetchupGradientBackground {
        KetchupGradientBackground(
            colors: [
                AppColors.backgroundPrimary,
                AppColors.backgroundSecondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Card background
    static var card: KetchupGradientBackground {
        KetchupGradientBackground(
            colors: [
                AppColors.cardBackground,
                AppColors.cardBackground.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Profile background
    static var profile: KetchupGradientBackground {
        KetchupGradientBackground(
            colors: [
                AppColors.backgroundPrimary,
                AppColors.backgroundSecondary.opacity(0.7)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// Extension for conditional view modifications (renamed to avoid conflicts)
extension View {
    @ViewBuilder
    func ifApply<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    VStack {
        KetchupGradientBackground.main
        
        Text("Custom Gradient")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(
                KetchupGradientBackground(
                    colors: [
                        AppColors.gradient1Start,
                        AppColors.gradient1End
                    ],
                    blurRadius: 2,
                    opacity: 0.9
                )
                .frame(height: 100)
                .cornerRadius(20)
                .ignoresSafeArea(edges: [])
            )
    }
} 