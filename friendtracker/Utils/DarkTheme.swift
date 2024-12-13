import SwiftUI

struct DarkTheme: ThemeProtocol {
    static var background: Color = Color(hex: "#020817")
    static var secondaryBackground: Color = Color(hex: "#1E293B")
    static var cardBackground: Color = Color(hex: "#0F172A")
    static var primary: Color = Color(hex: "#0EA5E9")
    static var primaryAccent: Color = Color(hex: "#38BDF8")
    static var primaryText: Color = Color(hex: "#F8FAFC")
    static var secondaryText: Color = Color(hex: "#94A3B8")
    static var cardBorder: Color = Color(hex: "#1E293B").opacity(0.5)
    static var shadowOpacity: Double = 0.1
    static var shadowOffset: CGPoint = CGPoint(x: 0, y: 1)
    static var shadowRadius: CGFloat = 2
} 