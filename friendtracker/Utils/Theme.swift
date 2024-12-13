import SwiftUI

struct Theme {
    enum Mode {
        case light, dark
    }
    
    static var current: Mode = .dark // Default theme
    
    // Background colors - More subtle gradients
    static var background: Color {
        switch current {
        case .dark: return Color(hex: "#020817") // Darker, richer background
        case .light: return Color(hex: "#FFFFFF") // Clean white
        }
    }
    
    static var secondaryBackground: Color {
        switch current {
        case .dark: return Color(hex: "#1E293B") // Slate 800
        case .light: return Color(hex: "#F8FAFC") // Slate 50
        }
    }
    
    static var cardBackground: Color {
        switch current {
        case .dark: return Color(hex: "#0F172A") // Slate 900
        case .light: return Color(hex: "#FFFFFF") // White
        }
    }
    
    // Primary colors - More vibrant accents
    static let primary = Color(hex: "#0EA5E9") // Sky 500
    static let primaryAccent = Color(hex: "#38BDF8") // Sky 400
    
    // Text colors - Better contrast
    static var primaryText: Color {
        switch current {
        case .dark: return Color(hex: "#F8FAFC") // Slate 50
        case .light: return Color(hex: "#0F172A") // Slate 900
        }
    }
    
    static var secondaryText: Color {
        switch current {
        case .dark: return Color(hex: "#94A3B8") // Slate 400
        case .light: return Color(hex: "#64748B") // Slate 500
        }
    }
    
    // Card properties - More subtle borders
    static var cardBorder: Color {
        switch current {
        case .dark: return Color(hex: "#1E293B").opacity(0.5) // Slate 800 with opacity
        case .light: return Color(hex: "#E2E8F0").opacity(0.5) // Slate 200 with opacity
        }
    }
    
    // Shadow properties - More natural depth
    static var shadowOpacity: Double {
        switch current {
        case .dark: return 0.1
        case .light: return 0.05
        }
    }
    
    static var shadowOffset: CGPoint {
        return CGPoint(x: 0, y: 1) // Minimal offset
    }
    
    static var shadowRadius: CGFloat {
        return 2 // Subtle blur
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