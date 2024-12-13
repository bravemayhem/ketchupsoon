import SwiftUI

struct LightTheme: ThemeProtocol {
    static var background: Color = Color(hex: "#FAFAFA")
    static var secondaryBackground: Color = Color(hex: "#F1F5F9")
    static var cardBackground: Color = Color(hex: "#FFFFFF")
    static var primary: Color = Color(hex: "#0EA5E9")
    static var primaryAccent: Color = Color(hex: "#38BDF8")
    static var primaryText: Color = Color(hex: "#0F172A")
    static var secondaryText: Color = Color(hex: "#475569")
    static var cardBorder: Color = Color(hex: "#E2E8F0").opacity(0.7)
    static var shadowOpacity: Double = 0.08
    static var shadowOffset: CGPoint = CGPoint(x: 0, y: 1)
    static var shadowRadius: CGFloat = 2
} 