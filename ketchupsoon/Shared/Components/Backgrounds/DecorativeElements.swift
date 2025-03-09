import SwiftUI

/// A reusable component for creating small decorative elements in backgrounds
struct DecorativeElement: View {
    var shape: AnyView
    var offset: CGPoint
    
    init<S: View>(shape: S, offset: CGPoint) {
        self.shape = AnyView(shape)
        self.offset = offset
    }
    
    var body: some View {
        shape
            .offset(x: offset.x, y: offset.y)
    }
}

/// A collection of multiple decorative elements
struct DecorativeElements: View {
    var elements: [DecorativeElement]
    
    var body: some View {
        ZStack {
            ForEach(0..<elements.count, id: \.self) { index in
                elements[index]
            }
        }
    }
}

/// Factory for creating predefined sets of decorative elements
struct BackgroundElementFactory {
    /// Create elements for the home screen
    static func homeElements() -> DecorativeElements {
        DecorativeElements(elements: [
            // Mint circle
            DecorativeElement(
                shape: Circle()
                    .fill(AppColors.mint.opacity(0.8))
                    .frame(width: 16, height: 16),
                offset: CGPoint(x: -140, y: 180)
            ),
            
            // Accent secondary circle
            DecorativeElement(
                shape: Circle()
                    .fill(AppColors.accentSecondary.opacity(0.8))
                    .frame(width: 10, height: 10),
                offset: CGPoint(x: 150, y: 400)
            ),
            
            // Accent circle
            DecorativeElement(
                shape: Circle()
                    .fill(AppColors.accent.opacity(0.8))
                    .frame(width: 12, height: 12),
                offset: CGPoint(x: -130, y: 500)
            ),
            
            // Purple rectangle
            DecorativeElement(
                shape: RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.purple.opacity(0.8))
                    .frame(width: 15, height: 15)
                    .rotationEffect(.degrees(30)),
                offset: CGPoint(x: 120, y: 220)
            ),
            
            // Accent secondary rectangle
            DecorativeElement(
                shape: RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.accentSecondary.opacity(0.8))
                    .frame(width: 10, height: 10)
                    .rotationEffect(.degrees(-15)),
                offset: CGPoint(x: -130, y: 380)
            )
        ])
    }
    
    /// Create elements for profile screen
    static func profileElements() -> DecorativeElements {
        DecorativeElements(elements: [
            // Mint circle
            DecorativeElement(
                shape: Circle()
                    .fill(AppColors.mint.opacity(0.8))
                    .frame(width: 16, height: 16),
                offset: CGPoint(x: -120, y: 200)
            ),
            
            // Accent secondary circle
            DecorativeElement(
                shape: Circle()
                    .fill(AppColors.accentSecondary.opacity(0.8))
                    .frame(width: 12, height: 12),
                offset: CGPoint(x: 170, y: 350)
            ),
            
            // Accent circle
            DecorativeElement(
                shape: Circle()
                    .fill(AppColors.accent.opacity(0.8))
                    .frame(width: 14, height: 14),
                offset: CGPoint(x: -150, y: 450)
            ),
            
            // Purple rectangle
            DecorativeElement(
                shape: RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.purple.opacity(0.8))
                    .frame(width: 15, height: 15)
                    .rotationEffect(.degrees(45)),
                offset: CGPoint(x: 100, y: 250)
            ),
            
            // Accent secondary rectangle
            DecorativeElement(
                shape: RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.accentSecondary.opacity(0.8))
                    .frame(width: 10, height: 10)
                    .rotationEffect(.degrees(-25)),
                offset: CGPoint(x: -110, y: 350)
            )
        ])
    }
    
    /// Create elements for onboarding screen
    static func onboardingElements() -> DecorativeElements {
        DecorativeElements(elements: [
            // Mint circle
            DecorativeElement(
                shape: Circle()
                    .fill(AppColors.mint.opacity(0.8))
                    .frame(width: 18, height: 18),
                offset: CGPoint(x: -160, y: 150)
            ),
            
            // Accent secondary circle
            DecorativeElement(
                shape: Circle()
                    .fill(AppColors.accentSecondary.opacity(0.8))
                    .frame(width: 14, height: 14),
                offset: CGPoint(x: 130, y: 420)
            ),
            
            // Purple rectangle
            DecorativeElement(
                shape: RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.purple.opacity(0.8))
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(15)),
                offset: CGPoint(x: 110, y: 280)
            ),
            
            // Accent rectangle
            DecorativeElement(
                shape: RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.accent.opacity(0.8))
                    .frame(width: 12, height: 12)
                    .rotationEffect(.degrees(-30)),
                offset: CGPoint(x: -120, y: 450)
            )
        ])
    }
}

/// A simple gradient background component
struct DecorativeGradientBackground: View {
    var colors: [Color]
    var startPoint: UnitPoint
    var endPoint: UnitPoint
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint
        )
        .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.9).ignoresSafeArea()
        
        // Show different element styles
        VStack {
            Text("Home Elements")
                .foregroundColor(.white)
                .padding()
            
            ZStack {
                Color(AppColors.backgroundPrimary).opacity(0.7)
                BackgroundElementFactory.homeElements()
            }
            .frame(height: 150)
            .cornerRadius(20)
            .padding(.horizontal)
            
            Text("Profile Elements")
                .foregroundColor(.white)
                .padding()
            
            ZStack {
                Color(AppColors.backgroundPrimary).opacity(0.7)
                BackgroundElementFactory.profileElements()
            }
            .frame(height: 150)
            .cornerRadius(20)
            .padding(.horizontal)
            
            Text("Onboarding Elements")
                .foregroundColor(.white)
                .padding()
            
            ZStack {
                Color(AppColors.backgroundPrimary).opacity(0.7)
                BackgroundElementFactory.onboardingElements()
            }
            .frame(height: 150)
            .cornerRadius(20)
            .padding(.horizontal)
        }
    }
} 