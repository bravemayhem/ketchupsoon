import SwiftUI

/// A protocol for background decoration elements
protocol PositionedElement: View {
    var position: CGPoint { get set }
    var color: Color { get set }
}

/// A circular decoration element
struct PositionedCircle: PositionedElement {
    var position: CGPoint
    var color: Color
    var size: CGFloat
    var opacity: Double = 0.7
    
    var body: some View {
        Circle()
            .fill(color)
            .opacity(opacity)
            .frame(width: size, height: size)
            .position(position)
    }
}

/// A rectangular decoration element
struct PositionedRectangle: PositionedElement {
    var position: CGPoint
    var color: Color
    var width: CGFloat
    var height: CGFloat
    var rotation: Angle = .zero
    var opacity: Double = 0.7
    
    var body: some View {
        Rectangle()
            .fill(color)
            .opacity(opacity)
            .frame(width: width, height: height)
            .rotationEffect(rotation)
            .position(position)
    }
}

/// A view that displays multiple decorative elements
struct PositionedElements: View {
    var elements: [AnyView]
    
    init<T: PositionedElement>(elements: [T]) {
        self.elements = elements.map { AnyView($0) }
    }
    
    init(elements: [AnyView]) {
        self.elements = elements
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<elements.count, id: \.self) { index in
                elements[index]
            }
        }
    }
}

/// Factory for creating common background elements
struct PositionedElementFactory {
    /// Create a set of decorative elements for the onboarding screen
    static func onboardingElements(screenWidth: CGFloat = UIScreen.main.bounds.width) -> PositionedElements {
        let elements: [AnyView] = [
            AnyView(PositionedCircle(
                position: CGPoint(x: 40, y: 180),
                color: AppColors.mint,
                size: 6
            )),
            
            AnyView(PositionedCircle(
                position: CGPoint(x: screenWidth - 40, y: 400),
                color: AppColors.accentSecondary,
                size: 4
            )),
            
            AnyView(PositionedCircle(
                position: CGPoint(x: 70, y: 500),
                color: AppColors.accent,
                size: 5
            )),
            
            AnyView(PositionedRectangle(
                position: CGPoint(x: screenWidth - 70, y: 220),
                color: AppColors.purple,
                width: 12,
                height: 12,
                rotation: Angle(degrees: 30)
            ))
        ]
        
        return PositionedElements(elements: elements)
    }
    
    /// Create a set of decorative elements for the home screen
    static func homeElements(screenWidth: CGFloat = UIScreen.main.bounds.width) -> PositionedElements {
        let elements: [AnyView] = [
            AnyView(PositionedCircle(
                position: CGPoint(x: screenWidth - 140, y: 180),
                color: AppColors.mint,
                size: 16
            )),
            
            AnyView(PositionedCircle(
                position: CGPoint(x: screenWidth - 150, y: 400),
                color: AppColors.accentSecondary,
                size: 10
            )),
            
            AnyView(PositionedRectangle(
                position: CGPoint(x: screenWidth - 120, y: 220),
                color: AppColors.purple,
                width: 15,
                height: 15,
                rotation: Angle(degrees: 30)
            ))
        ]
        
        return PositionedElements(elements: elements)
    }
    
    /// Create a set of decorative elements for the profile screen
    static func profileElements(screenWidth: CGFloat = UIScreen.main.bounds.width) -> PositionedElements {
        let elements: [AnyView] = [
            AnyView(PositionedCircle(
                position: CGPoint(x: 60, y: 160),
                color: AppColors.mint,
                size: 8
            )),
            
            AnyView(PositionedCircle(
                position: CGPoint(x: screenWidth - 70, y: 380),
                color: AppColors.accentSecondary,
                size: 7
            )),
            
            AnyView(PositionedRectangle(
                position: CGPoint(x: screenWidth - 50, y: 250),
                color: AppColors.purple,
                width: 10,
                height: 10,
                rotation: Angle(degrees: 45)
            )),
            
            AnyView(PositionedCircle(
                position: CGPoint(x: 40, y: 500),
                color: AppColors.accent,
                size: 6
            ))
        ]
        
        return PositionedElements(elements: elements)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.9).ignoresSafeArea()
        
        // Show different element sets
        VStack {
            Text("Onboarding Elements")
                .foregroundColor(.white)
                .padding()
            
            ZStack {
                Color(AppColors.backgroundPrimary).opacity(0.7)
                PositionedElementFactory.onboardingElements()
            }
            .frame(height: 150)
            .cornerRadius(20)
            .padding(.horizontal)
            
            Text("Home Elements")
                .foregroundColor(.white)
                .padding()
            
            ZStack {
                Color(AppColors.backgroundPrimary).opacity(0.7)
                PositionedElementFactory.homeElements()
            }
            .frame(height: 150)
            .cornerRadius(20)
            .padding(.horizontal)
            
            Text("Profile Elements")
                .foregroundColor(.white)
                .padding()
            
            ZStack {
                Color(AppColors.backgroundPrimary).opacity(0.7)
                PositionedElementFactory.profileElements()
            }
            .frame(height: 150)
            .cornerRadius(20)
            .padding(.horizontal)
        }
    }
} 