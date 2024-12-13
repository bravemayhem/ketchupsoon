import SwiftUI

protocol ThemeProtocol {
    static var background: Color { get }
    static var secondaryBackground: Color { get }
    static var cardBackground: Color { get }
    static var primary: Color { get }
    static var primaryAccent: Color { get }
    static var primaryText: Color { get }
    static var secondaryText: Color { get }
    static var cardBorder: Color { get }
    static var shadowOpacity: Double { get }
    static var shadowOffset: CGPoint { get }
    static var shadowRadius: CGFloat { get }
} 