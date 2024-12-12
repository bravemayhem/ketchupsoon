import SwiftUI

struct Theme {
    enum Mode {
        case light, dark
    }
    
    static var current: Mode = .dark // Default theme
    
    // Main colors - Using provided neobrutalist palette
    static var background: Color {
        switch current {
        case .dark: return Color(hex: "FCFFDA") // Soft yellow background
        case .light: return Color(hex: "FCFFDA") // Same for light mode
        }
    }
    
    static var secondaryBackground: Color {
        switch current {
        case .dark: return Color(hex: "B8FF9F") // Mint green
        case .light: return Color(hex: "B8FF9F")
        }
    }
    
    static var cardBackground: Color {
        switch current {
        case .dark: return Color(hex: "B8FF9F") // Mint green cards
        case .light: return Color(hex: "B8FF9F")
        }
    }
    
    // Accent colors - Using white sparingly and keeping coral
    static let primary = Color(hex: "FF6B6B") // Vibrant coral for important elements
    static let secondary = Color(hex: "FFFFFF") // Pure white for special highlights
    
    // Text colors - High contrast
    static var primaryText: Color {
        switch current {
        case .dark: return Color.black // Black text for contrast
        case .light: return Color.black
        }
    }
    
    static var secondaryText: Color {
        switch current {
        case .dark: return Color(hex: "2D2D2D") // Dark gray text
        case .light: return Color(hex: "2D2D2D")
        }
    }
    
    // Card border and shadow properties for neobrutalism
    static var cardBorder: Color {
        return Color.black // Always black border for neobrutalism
    }
    
    // Shadow opacity - Stronger for neobrutalism
    static var shadowOpacity: Double {
        return 1.0 // Full opacity for brutal look
    }
    
    // Shadow offset for neobrutalism
    static var shadowOffset: CGPoint {
        return CGPoint(x: 4, y: 4) // Distinct offset for brutal look
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