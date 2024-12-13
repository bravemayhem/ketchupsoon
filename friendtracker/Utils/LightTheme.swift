import SwiftUI

struct LightTheme: ThemeProtocol {
    static var background: Color = Color(hex: "#F5FFF8")
    static var secondaryBackground: Color = Color(hex: "#EDFFF0")
    static var cardBackground: Color = Color(hex: "#FFFFFF")
    static var primary: Color = Color(hex: "#FF7E54")
    static var primaryAccent: Color = Color(hex: "#FF9776")
    static var primaryText: Color = Color(hex: "#2C3E50")
    static var secondaryText: Color = Color(hex: "#7F8C8D")
    static var cardBorder: Color = Color(hex: "#FFE4D6").opacity(0.5)
    static var shadowOpacity: Double = 0.04
    static var shadowOffset: CGPoint = CGPoint(x: 0, y: 2)
    static var shadowRadius: CGFloat = 4
} 