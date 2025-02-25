// This is a singleton that provides the colors of the app
// It is used in the App.swift file
// The file is specifically focused on color definitions and color-related utilities

import SwiftUI

enum AppColors {
    // Primary Brand Colors
    static let accent = Color(hex: "FF7E45")  // Soft orange
    static let accentLight = Color(hex: "FFA07A") // Light coral
    
    // Background Colors
    static let systemBackground = Color(.systemBackground)
    static let secondarySystemBackground = Color(.secondarySystemBackground)
    
    // Text Colors
    static let label = Color(.label)
    static let secondaryLabel = Color(.secondaryLabel)
    static let tertiaryLabel = Color(.tertiaryLabel)
    
    // UI Element Colors
    static let separator = Color(.separator)
    static let systemGray = Color(.systemGray)
    
    // Semantic Colors
    static let success = Color(.systemGreen)
    static let warning = Color(.systemOrange)
    static let error = Color(.systemRed)
    static let futureGreen = Color(hex: "4CD964")  // Stored for future use
    
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
    
    // Avatar Background Colors - Using only accent color for consistency
    static let avatarColors: [Color] = [
        accent,  // Soft orange (primary)
        futureGreen
    ]
    
    static func avatarColor(for name: String) -> Color {
        return accent
    }
    
    // Frosted Glass Effect
    static func glassMorphism(opacity: Double = 0.5) -> some View {
        Rectangle()
            .fill(Color.white)
            .opacity(opacity)
            .background(.ultraThinMaterial)
            .blur(radius: 0.5)
    }
    
    // Confetti Colors
    static let confettiColors: [Color] = [
        Color(hex: "FF7E45"),  // Soft orange (primary)
        Color(hex: "5856D6"),  // Soft purple
        Color(hex: "64D2FF"),  // Sky blue
        Color(hex: "FF2D55"),  // Pink
        Color(hex: "5856D6"),  // Purple
        Color(hex: "FF9500"),  // Orange
        Color(hex: "4CD964"),  // Green
        Color(hex: "FFCC00"),  // Yellow
        Color(hex: "FF3B30")   // Red
    ]
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

#Preview("Colors") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Group {
                Text("Brand Colors")
                    .font(.headline)
                HStack {
                    colorPreview(AppColors.accent, "Accent")
                    colorPreview(AppColors.accentLight, "Accent Light")
                }
            }
            
            Group {
                Text("Background Colors")
                    .font(.headline)
                HStack {
                    colorPreview(AppColors.systemBackground, "System")
                    colorPreview(AppColors.secondarySystemBackground, "Secondary")
                }
            }
            
            Group {
                Text("Text Colors")
                    .font(.headline)
                HStack {
                    colorPreview(AppColors.label, "Label")
                    colorPreview(AppColors.secondaryLabel, "Secondary")
                    colorPreview(AppColors.tertiaryLabel, "Tertiary")
                }
            }
            
            Group {
                Text("Semantic Colors")
                    .font(.headline)
                HStack {
                    colorPreview(AppColors.success, "Success")
                    colorPreview(AppColors.warning, "Warning")
                    colorPreview(AppColors.error, "Error")
                }
            }
            
            Group {
                Text("Gradients")
                    .font(.headline)
                VStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.backgroundGradient)
                        .frame(height: 60)
                        .overlay(Text("Background").foregroundColor(.black))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.accentGradient)
                        .frame(height: 60)
                        .overlay(Text("Accent").foregroundColor(.white))
                }
            }
            
            Group {
                Text("Avatar Colors")
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(AppColors.avatarColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                        }
                    }
                }
            }
        }
        .padding()
    }
    .background(Color(.systemBackground))
}

private func colorPreview(_ color: Color, _ name: String) -> some View {
    VStack {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 60, height: 60)
        Text(name)
            .font(.caption)
    }
} 
