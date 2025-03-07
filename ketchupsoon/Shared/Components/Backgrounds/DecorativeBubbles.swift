import SwiftUI

/// A reusable component for creating decorative bubble elements with blur effects
struct DecorativeBubble: View {
    // Bubble properties
    var color: Color
    var width: CGFloat
    var height: CGFloat
    var offset: CGPoint
    var blurRadius: CGFloat
    var opacity: Double = 1.0
    
    init(
        color: Color,
        width: CGFloat = 360,
        height: CGFloat = 360,
        offset: CGPoint = CGPoint(x: 0, y: 0),
        blurRadius: CGFloat = 40,
        opacity: Double = 1.0
    ) {
        self.color = color
        self.width = width
        self.height = height
        self.offset = offset
        self.blurRadius = blurRadius
        self.opacity = opacity
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .opacity(opacity)
            .frame(width: width, height: height)
            .offset(x: offset.x, y: offset.y)
            .blur(radius: blurRadius)
    }
}

/// A collection of multiple decorative bubbles
struct DecorativeBubbles: View {
    var bubbles: [DecorativeBubble]
    
    var body: some View {
        ZStack {
            ForEach(0..<bubbles.count, id: \.self) { index in
                bubbles[index]
            }
        }
    }
}

// MARK: - Predefined Bubble Styles
extension DecorativeBubbles {
    /// Standard onboarding background bubbles
    static var onboarding: DecorativeBubbles {
        DecorativeBubbles(bubbles: [
            // Top right purple bubble
            DecorativeBubble(
                color: AppColors.purple.opacity(0.25),
                width: 360,
                height: 360,
                offset: CGPoint(x: 100, y: -100),
                blurRadius: 40
            ),
            
            // Bottom left accent bubble
            DecorativeBubble(
                color: AppColors.accent.opacity(0.15),
                width: 320,
                height: 320,
                offset: CGPoint(x: -100, y: 400),
                blurRadius: 40
            )
        ])
    }
    
    /// Home screen background bubbles
    static var home: DecorativeBubbles {
        DecorativeBubbles(bubbles: [
            // Top right purple bubble
            DecorativeBubble(
                color: AppColors.purple.opacity(0.3),
                width: 400,
                height: 400,
                offset: CGPoint(x: 150, y: -50),
                blurRadius: 50
            ),
            
            // Bottom left accent bubble
            DecorativeBubble(
                color: AppColors.accent.opacity(0.2),
                width: 360,
                height: 360,
                offset: CGPoint(x: -150, y: 300),
                blurRadius: 50
            )
        ])
    }
    
    /// Profile view background bubbles
    static var profile: DecorativeBubbles {
        DecorativeBubbles(bubbles: [
            // Top left mint bubble
            DecorativeBubble(
                color: AppColors.mint.opacity(0.2),
                width: 300,
                height: 300,
                offset: CGPoint(x: -120, y: -80),
                blurRadius: 45
            ),
            
            // Bottom right accent bubble
            DecorativeBubble(
                color: AppColors.accentSecondary.opacity(0.15),
                width: 280,
                height: 280,
                offset: CGPoint(x: 120, y: 350),
                blurRadius: 35
            )
        ])
    }
    
    /// Card background bubbles (smaller, more subtle)
    static var card: DecorativeBubbles {
        DecorativeBubbles(bubbles: [
            // Top right small bubble
            DecorativeBubble(
                color: AppColors.accent.opacity(0.15),
                width: 150,
                height: 150,
                offset: CGPoint(x: 80, y: -40),
                blurRadius: 20
            ),
            
            // Bottom left small bubble
            DecorativeBubble(
                color: AppColors.purple.opacity(0.15),
                width: 120,
                height: 120,
                offset: CGPoint(x: -70, y: 100),
                blurRadius: 15
            )
        ])
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.9).ignoresSafeArea()
        
        // Show different bubble styles
        VStack {
            Text("Onboarding Bubbles")
                .foregroundColor(.white)
                .padding()
            
            ZStack {
                Color(AppColors.backgroundPrimary).opacity(0.7)
                DecorativeBubbles.onboarding
            }
            .frame(height: 150)
            .cornerRadius(20)
            .padding(.horizontal)
            
            Text("Home Bubbles")
                .foregroundColor(.white)
                .padding()
            
            ZStack {
                Color(AppColors.backgroundPrimary).opacity(0.7)
                DecorativeBubbles.home
            }
            .frame(height: 150)
            .cornerRadius(20)
            .padding(.horizontal)
            
            Text("Profile Bubbles")
                .foregroundColor(.white)
                .padding()
            
            ZStack {
                Color(AppColors.backgroundPrimary).opacity(0.7)
                DecorativeBubbles.profile
            }
            .frame(height: 150)
            .cornerRadius(20)
            .padding(.horizontal)
        }
    }
} 