import SwiftUI

enum AppColors {
    // Primary Brand Colors
    static let accent = Color(hex: "FF7E45")  // Soft orange
    static let accentLight = Color(hex: "FFA07A") // Light coral
    
    // Background Colors
    static let systemBackground = Color(hex: "F2F2F7") // iOS system background
    static let secondarySystemBackground = Color(hex: "FFFFFF") // iOS secondary background
    
    // Text Colors
    static let label = Color(hex: "000000")
    static let secondaryLabel = Color(hex: "3C3C43").opacity(0.6)
    static let tertiaryLabel = Color(hex: "3C3C43").opacity(0.3)
    
    // UI Element Colors
    static let separator = Color(hex: "3C3C43").opacity(0.2)
    static let systemGray = Color(hex: "8E8E93")
    
    // Semantic Colors
    static let success = Color(hex: "34C759") // iOS green
    static let warning = Color(hex: "FF9500") // iOS orange
    static let error = Color(hex: "FF3B30")   // iOS red
    
    // Gradient Colors
    static let gradientLight = Color(hex: "FF7E45").opacity(0.8)  // Soft orange
    static let gradientDark = Color(hex: "FF5126")   // Deeper orange
    
    // Gradient Presets
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(hex: "FFFFFF"),
            Color(hex: "F2F2F7")
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let accentGradient = LinearGradient(
        colors: [gradientLight, gradientDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Avatar Background Colors - Softer, more modern palette
    static let avatarColors: [Color] = [
        Color(hex: "FF7E45"),  // Soft orange (primary)
        Color(hex: "5856D6"),  // Soft purple
        Color(hex: "64D2FF"),  // Sky blue
        Color(hex: "FF2D55"),  // Pink
        Color(hex: "5856D6"),  // Purple
        Color(hex: "FF9500"),  // Orange
        Color(hex: "4CD964"),  // Green
    ]
    
    static func avatarColor(for name: String) -> Color {
        let index = abs(name.hashValue) % avatarColors.count
        return avatarColors[index]
    }
    
    // Frosted Glass Effect
    static func glassMorphism(opacity: Double = 0.5) -> some View {
        Rectangle()
            .fill(Color.white)
            .opacity(opacity)
            .background(.ultraThinMaterial)
            .blur(radius: 0.5)
    }
}

// Helper extension to create colors from hex values
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