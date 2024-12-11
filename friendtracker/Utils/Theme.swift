import SwiftUI

struct Theme {
    enum Mode {
        case light, dark
    }
    
    static var current: Mode = .dark // Default theme
    
    // Main colors
    static var background: Color {
        switch current {
        case .dark: return Color(hex: "000000")
        case .light: return Color(hex: "F2F2F7")
        }
    }
    
    static var secondaryBackground: Color {
        switch current {
        case .dark: return Color(hex: "1C1C1E")
        case .light: return Color(hex: "FFFFFF")
        }
    }
    
    static var cardBackground: Color {
        switch current {
        case .dark: return Color(hex: "2C2C2E")
        case .light: return Color(hex: "FFFFFF")
        }
    }
    
    // Accent colors - same for both themes
    static let primary = Color(hex: "4CD964") // Mint green accent
    static let secondary = Color(hex: "5856D6") // Purple accent
    
    // Text colors
    static var primaryText: Color {
        switch current {
        case .dark: return .white
        case .light: return Color(hex: "000000")
        }
    }
    
    static var secondaryText: Color {
        switch current {
        case .dark: return Color(hex: "AEAEB2")
        case .light: return Color(hex: "6C6C70")
        }
    }
    
    // Status colors - slightly adjusted for light theme
    static var success: Color {
        switch current {
        case .dark: return Color(hex: "34C759")
        case .light: return Color(hex: "30B650")
        }
    }
    
    static var warning: Color {
        switch current {
        case .dark: return Color(hex: "FF9F0A")
        case .light: return Color(hex: "F58300")
        }
    }
    
    static var error: Color {
        switch current {
        case .dark: return Color(hex: "FF453A")
        case .light: return Color(hex: "FF3B30")
        }
    }
    
    // Card border color - only visible in light mode
    static var cardBorder: Color {
        switch current {
        case .dark: return Color.white.opacity(0.1)
        case .light: return Color(hex: "E5E5EA")
        }
    }
    
    // Shadow opacity
    static var shadowOpacity: Double {
        switch current {
        case .dark: return 0.3
        case .light: return 0.1
        }
    }
    
    // Helper method for hex colors
    static func color(hex: String) -> Color {
        Color(hex: hex)
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