import SwiftUI

final class Theme: ObservableObject {
    static let shared = Theme()
    
    // Default to light mode
    @Published var isDarkMode: Bool = false
    
    // MARK: - Colors
    var background: Color {
        isDarkMode ? Color(hex: "#020817") : Color(hex: "#E8EEF0")
    }
    
    var secondaryBackground: Color {
        isDarkMode ? Color(hex: "#1E293B") : Color(hex: "#DDE5E8")
    }
    
    var cardBackground: Color {
        isDarkMode ? Color(hex: "#0F172A") : Color(hex: "#FFFFFF")
    }
    
    // Primary brand colors (constant regardless of theme)
    let primary = Color(hex: "#4CAF90")
    let primaryAccent = Color(hex: "#65C4A6")
    
    var primaryText: Color {
        isDarkMode ? Color(hex: "#F8FAFC") : Color(hex: "#2F3B35")
    }
    
    var secondaryText: Color {
        isDarkMode ? Color(hex: "#94A3B8") : Color(hex: "#6B7C73")
    }
    
    var cardBorder: Color {
        (isDarkMode ? Color(hex: "#1E293B") : Color(hex: "#E3EBE7")).opacity(0.5)
    }
    
    // MARK: - Shadow Properties
    var shadowOpacity: Double {
        isDarkMode ? 0.1 : 0.04
    }
    
    let shadowOffset = CGPoint(x: 0, y: 2)
    let shadowRadius: CGFloat = 4
}

// MARK: - Hex Color Support
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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 