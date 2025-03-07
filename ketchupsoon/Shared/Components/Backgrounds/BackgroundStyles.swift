import SwiftUI

/// A complete background style that combines gradient, bubbles, and decorative elements
struct CompleteBackground: View {
    // Background components
    var gradient: GradientBackground
    var bubbles: DecorativeBubbles?
    var elements: DecorativeElements?
    var noiseTexture: Bool = true
    var noiseOpacity: Double = 0.04
    
    var body: some View {
        ZStack {
            // Base gradient
            gradient
            
            // Decorative bubbles
            if let bubbles = bubbles {
                bubbles
            }
            
            // Small decorative elements
            if let elements = elements {
                elements
            }
            
            // Optional noise texture overlay
            if noiseTexture {
                Rectangle()
                    .fill(Color.white.opacity(noiseOpacity))
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Predefined Background Styles
extension CompleteBackground {
    /// Standard onboarding background
    static var onboarding: CompleteBackground {
        CompleteBackground(
            gradient: GradientBackground(
                colors: [
                    AppColors.backgroundPrimary,
                    AppColors.backgroundSecondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            bubbles: DecorativeBubbles.onboarding,
            elements: BackgroundElementFactory.onboardingElements()
        )
    }
    
    /// Home screen background
    static var home: CompleteBackground {
        CompleteBackground(
            gradient: GradientBackground(
                colors: [
                    AppColors.backgroundPrimary,
                    AppColors.backgroundSecondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            bubbles: DecorativeBubbles.home,
            elements: BackgroundElementFactory.homeElements()
        )
    }
    
    /// Profile screen background
    static var profile: CompleteBackground {
        CompleteBackground(
            gradient: GradientBackground(
                colors: [
                    AppColors.backgroundPrimary,
                    AppColors.backgroundSecondary.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            bubbles: DecorativeBubbles.profile,
            elements: BackgroundElementFactory.profileElements()
        )
    }
    
    /// Card background (smaller, more subtle)
    static var card: CompleteBackground {
        CompleteBackground(
            gradient: GradientBackground(
                colors: [
                    AppColors.cardBackground,
                    AppColors.cardBackground.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            bubbles: DecorativeBubbles.card,
            elements: nil,
            noiseTexture: false
        )
    }
    
    /// Simple gradient background without bubbles or elements
    static var simple: CompleteBackground {
        CompleteBackground(
            gradient: GradientBackground(
                colors: [
                    AppColors.backgroundPrimary,
                    AppColors.backgroundSecondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            bubbles: nil,
            elements: nil,
            noiseTexture: true,
            noiseOpacity: 0.02
        )
    }
}

/// BackgroundView replacement using the shared components
struct SharedBackgroundView: View {
    var style: CompleteBackground.Type = CompleteBackground.self
    var customStyle: CompleteBackground?
    
    var body: some View {
        if let customStyle = customStyle {
            customStyle
        } else {
            CompleteBackground.onboarding
        }
    }
}

#Preview {
    TabView {
        VStack {
            Text("Onboarding Background")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
            
            Spacer()
        }
        .background(CompleteBackground.onboarding)
        .tabItem {
            Text("Onboarding")
        }
        
        VStack {
            Text("Home Background")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
            
            Spacer()
        }
        .background(CompleteBackground.home)
        .tabItem {
            Text("Home")
        }
        
        VStack {
            Text("Profile Background")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
            
            Spacer()
        }
        .background(CompleteBackground.profile)
        .tabItem {
            Text("Profile")
        }
        
        VStack {
            Text("Simple Background")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
            
            Spacer()
        }
        .background(CompleteBackground.simple)
        .tabItem {
            Text("Simple")
        }
    }
    .preferredColorScheme(.dark)
} 