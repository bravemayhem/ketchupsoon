import SwiftUI

struct BackgroundView: View {
    var body: some View {
        ZStack {
            // Main background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(UIColor(red: 13/255, green: 10/255, blue: 34/255, alpha: 1)),
                    Color(UIColor(red: 23/255, green: 19/255, blue: 48/255, alpha: 1))
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Top right bubble
            Circle()
                .fill(Color(UIColor(red: 100/255, green: 66/255, blue: 255/255, alpha: 0.25)))
                .frame(width: 360, height: 360)
                .offset(x: 100, y: -100)
                .blur(radius: 40)
            
            // Bottom left bubble
            Circle()
                .fill(Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 0.15)))
                .frame(width: 320, height: 320)
                .offset(x: -100, y: 400)
                .blur(radius: 40)
            
            // Small decorative elements
            Circle()
                .fill(Color(UIColor(red: 66/255, green: 221/255, blue: 189/255, alpha: 0.7)))
                .frame(width: 6, height: 6)
                .position(x: 40, y: 180)
                
            Circle()
                .fill(Color(UIColor(red: 255/255, green: 138/255, blue: 66/255, alpha: 0.7)))
                .frame(width: 4, height: 4)
                .position(x: UIScreen.main.bounds.width - 40, y: 400)
                
            Circle()
                .fill(Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 0.7)))
                .frame(width: 5, height: 5)
                .position(x: 70, y: 500)
                
            Rectangle()
                .fill(Color(UIColor(red: 100/255, green: 66/255, blue: 255/255, alpha: 0.7)))
                .frame(width: 12, height: 12)
                .rotationEffect(Angle(degrees: 30))
                .position(x: UIScreen.main.bounds.width - 70, y: 220)
            
            // Noise texture overlay
            Rectangle()
                .fill(Color.white.opacity(0.04))
                .ignoresSafeArea()
        }
    }
} 