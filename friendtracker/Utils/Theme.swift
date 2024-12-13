import SwiftUI

struct Theme {
    enum Mode {
        case light, dark
    }
    
    static var current: Mode = .light // Changed default to light
    
    // Background colors
    static var background: Color {
        switch current {
        case .dark: return Color(hex: "#020817")
        case .light: return Color(hex: "#F2F7F5") // Very light sage green background
        }
    }
    
    static var secondaryBackground: Color {
        switch current {
        case .dark: return Color(hex: "#1E293B")
        case .light: return Color(hex: "#E8F1ED") // Slightly darker sage background
        }
    }
    
    static var cardBackground: Color {
        switch current {
        case .dark: return Color(hex: "#0F172A")
        case .light: return Color(hex: "#FFFFFF") // Pure white
        }
    }
    
    // Primary colors
    static let primary = Color(hex: "#4CAF90") // Sage green
    static let primaryAccent = Color(hex: "#65C4A6") // Light sage
    
    // Text colors
    static var primaryText: Color {
        switch current {
        case .dark: return Color(hex: "#F8FAFC")
        case .light: return Color(hex: "#2F3B35") // Dark sage gray
        }
    }
    
    static var secondaryText: Color {
        switch current {
        case .dark: return Color(hex: "#94A3B8")
        case .light: return Color(hex: "#6B7C73") // Medium sage gray
        }
    }
    
    // Card properties
    static var cardBorder: Color {
        switch current {
        case .dark: return Color(hex: "#1E293B").opacity(0.5)
        case .light: return Color(hex: "#E3EBE7").opacity(0.5) // Very light sage
        }
    }
    
    // Shadow properties
    static var shadowOpacity: Double {
        switch current {
        case .dark: return 0.1
        case .light: return 0.04
        }
    }
    
    static var shadowOffset: CGPoint {
        return CGPoint(x: 0, y: 2)
    }
    
    static var shadowRadius: CGFloat {
        return 4
    }
}

// Extension for hex color support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 