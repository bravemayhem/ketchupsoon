// This is a singleton that provides the colors of the app
// It is used in the App.swift file
// The file is specifically focused on color definitions and color-related utilities

import SwiftUI

enum AppColors {
    // Primary Brand Colors
    static let accent = Color(hex: "FF2D55")  // Vibrant pink-red
    static let accentSecondary = Color(hex: "FF9500") // Bright orange
    static let primary = Color(hex: "5E17EB") // Vibrant purple (to maintain compatibility)
    static let secondary = Color(hex: "FF2D55") // Pink-red (to maintain compatibility)
    static let purple = Color(hex: "5E17EB") // Vibrant purple
    static let highlight = Color(hex: "00F5A0") // Bright mint (to maintain compatibility)
    static let mint = Color(hex: "00F5A0") // Bright mint
    static let pureBlue = Color(hex: "0073E6") // Pure blue color (RGB: 0, 115, 230 ≈ 0.0, 0.45, 0.9)
    
    // Background Colors - Dark mode focused
    static let background = Color(hex: "0A0728") // Deep blue-black
    static let backgroundPrimary = Color(hex: "0A0728") // Deep blue-black
    static let backgroundSecondary = Color(hex: "1A0E35") // Slightly lighter blue-purple
    static let cardBackground = Color(hex: "15103A") // Card background color
    
    // Legacy System Background Colors (for compatibility)
    static let systemBackground = Color(.systemBackground)
    static let secondarySystemBackground = Color(.secondarySystemBackground)
    
    // Navigation Bar Colors (for compatibility)
    static let statusBarBackground = background.opacity(0.9)
    static let headerBackground = background.opacity(0.85)
    
    // Text Colors
    static let label = Color.white // For compatibility
    static let secondaryLabel = Color.white.opacity(0.7) // For compatibility
    static let tertiaryLabel = Color.white.opacity(0.5) // For compatibility
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
    static let textAccent = accent
    
    // UI Element Colors
    static let separator = Color.white.opacity(0.1)
    static let outline = Color.white.opacity(0.2)
    
    // Semantic Colors
    static let success = Color(hex: "00F5A0") // Mint green success
    static let warning = Color(hex: "FF9500") // Orange warning
    static let error = Color(hex: "FF2D55") // Red error
    
    // Gradient Colors
    static let gradient1Start = Color(hex: "FF2D55") // Pink-red
    static let gradient1End = Color(hex: "FF9500") // Orange
    
    static let gradient2Start = Color(hex: "5E17EB") // Purple
    static let gradient2End = Color(hex: "FF2D55") // Pink-red
    
    static let gradient3Start = Color(hex: "FF9500") // Orange
    static let gradient3End = Color(hex: "FF2D55") // Pink-red
    
    static let gradient4Start = Color(hex: "00F5A0") // Mint
    static let gradient4End = Color(hex: "5E17EB") // Purple
    
    // Adding gradient5 from React file (blue-purple to mint)
    static let gradient5Start = Color(hex: "6B66FF") // Blue-purple
    static let gradient5End = Color(hex: "00F5A0") // Mint
    
    // Gradient Presets
    static let backgroundGradient = LinearGradient(
        colors: [
            backgroundPrimary,
            backgroundSecondary
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [gradient1Start, gradient1End],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient1 = LinearGradient(
        colors: [gradient1Start, gradient1End],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let primaryGradient = LinearGradient(
        colors: [gradient2Start, gradient2End],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient2 = LinearGradient(
        colors: [gradient2Start, gradient2End],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient3 = LinearGradient(
        colors: [gradient3Start, gradient3End],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient4 = LinearGradient(
        colors: [gradient4Start, gradient4End],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Adding gradient5 preset
    static let accentGradient5 = LinearGradient(
        colors: [gradient5Start, gradient5End],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // For compatibility with existing code
    static let addButtonGradient = accentGradient1
    
    // Gradient Arrays
    static let purplePink = [primary, secondary] // For compatibility
    static let redOrange = [accent, accentSecondary] // For compatibility
    static let greenPurple = [mint, primary] // For compatibility
    
    // Avatar Background Gradients
    static let avatarGradients: [LinearGradient] = [
        accentGradient1, 
        accentGradient2,
        accentGradient3,
        accentGradient4,
        accentGradient5
    ]
    
    // Avatar Colors (compatibility with existing code)
    static let avatarColors: [Color] = [
        primary,
        secondary,
        accent,
        accentSecondary,
        mint
    ]
    
    // Avatar Emojis - Gen Z friendly
    static let avatarEmojis: [String] = [
        "🌟", "🚀", "🎸", "🎨", "🎮", "🎵", "✨", "💫", "😎"
    ]
    
    // Gradient pairs for avatars and cards (for compatibility)
    static let gradientPairs: [[Color]] = [
        [gradient2Start, gradient2End],  // Purple to Pink
        [gradient1Start, gradient1End],  // Pink to Orange
        [gradient4Start, gradient4End],  // Mint to Purple
        [gradient3Start, gradient3End]   // Orange to Pink
    ]
    
    static func avatarGradient(for name: String) -> LinearGradient {
        let hash = abs(name.hash)
        let index = hash % avatarGradients.count
        return avatarGradients[index]
    }
    
    static func avatarEmoji(for name: String) -> String {
        let hash = abs(name.hash)
        let index = hash % avatarEmojis.count
        return avatarEmojis[index]
    }
    
    // For compatibility with existing code
    static func avatarColor(for name: String) -> Color {
        let index = abs(name.hashValue % avatarColors.count)
        return avatarColors[index]
    }
    
    // For compatibility with existing code
    static func gradientPair(for name: String) -> [Color] {
        let index = abs(name.hashValue % gradientPairs.count)
        return gradientPairs[index]
    }
    
    // Helper methods for navigation UI (for compatibility)
    static func circleBackground(opacity: Double = 0.05) -> Color {
        return Color.white.opacity(opacity)
    }
    
    static func borderOverlay(opacity: Double = 0.05) -> Color {
        return Color.white.opacity(opacity)
    }
    
    // Claymorphism Effect
    static func clayMorphism(cornerRadius: CGFloat = 24) -> some ViewModifier {
        struct ClayModifier: ViewModifier {
            let cornerRadius: CGFloat
            
            func body(content: Content) -> some View {
                content
                    .background(AppColors.cardBackground)
                    .cornerRadius(cornerRadius)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
        
        return ClayModifier(cornerRadius: cornerRadius)
    }
    
    // Glow Effect
    static func glowEffect(color: Color = accent, radius: CGFloat = 6, opacity: Double = 0.8) -> some ViewModifier {
        struct GlowModifier: ViewModifier {
            let color: Color
            let radius: CGFloat
            let opacity: Double
            
            func body(content: Content) -> some View {
                content
                    .shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 0)
            }
        }
        
        return GlowModifier(color: color, radius: radius, opacity: opacity)
    }
    
    // Frosted Glass Effect (for compatibility)
    static func glassMorphism(opacity: Double = 0.15) -> some View {
        Rectangle()
            .fill(primary)
            .opacity(opacity)
            .background(.ultraThinMaterial)
            .blur(radius: 0.5)
    }
    
    // Confetti Colors - More vibrant
    static let confettiColors: [Color] = [
        Color(hex: "FF2D55"),  // Pink-red
        Color(hex: "5E17EB"),  // Purple
        Color(hex: "FF9500"),  // Orange
        Color(hex: "00F5A0"),  // Mint
        Color(hex: "64D2FF"),  // Sky blue
        Color(hex: "FFC700"),  // Yellow
    ]
}

// MARK: - AddFriendView Colors (Experimental)
// This enum contains all the colors used in AddFriendViewOne for experimentation
enum AddFriendViewColors {
    // Base Colors
    static let backgroundDark = Color(hex: "0A0728")      // Deep blue-black (same as AppColors.backgroundPrimary)
    static let backgroundLight = Color(hex: "1A0E35")     // Slightly lighter blue-purple (same as AppColors.backgroundSecondary)
    static let cardBackground = Color(hex: "15103A")      // Card background color (same as AppColors.cardBackground)
    static let purple = Color(hex: "5E17EB")              // Vibrant purple (same as AppColors.purple)
    static let pinkRed = Color(hex: "FF2D55")             // Pink-red (same as AppColors.accent)
    static let orange = Color(hex: "FF9500")              // Orange (same as AppColors.accentSecondary)
    static let mint = Color(hex: "00F5A0")                // Mint green (same as AppColors.mint)
    static let emerald = Color(hex: "00B07A")             // Deeper emerald green for success states
    static let bluePurple = Color(hex: "6B66FF")          // Blue-purple (same as AppColors.gradient5Start)
    
    // Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
    
    // Border Colors
    static let separator = Color.white.opacity(0.1)
    static let outline = Color.white.opacity(0.2)
    
    // Gradients Used in AddFriendViewOne
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [backgroundDark, backgroundLight]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let pinkOrangeGradient = LinearGradient(
        gradient: Gradient(colors: [pinkRed, orange]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let purplePinkGradient = LinearGradient(
        gradient: Gradient(colors: [purple, pinkRed]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let mintPurpleGradient = LinearGradient(
        gradient: Gradient(colors: [mint, purple]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let blueMintGradient = LinearGradient(
        gradient: Gradient(colors: [bluePurple, mint]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        gradient: Gradient(colors: [mint, emerald]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Contact Avatar Styles
    static let contactAvatarGradients = [
        mintPurpleGradient,
        blueMintGradient
    ]
    
    static let contactAvatarEmojis = [
        "🦋", "🔮"
    ]
    
    // UI Components Examples
    static func tabButton(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(isSelected ? AnyShapeStyle(pinkOrangeGradient) : AnyShapeStyle(cardBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : separator, lineWidth: 1)
            )
            .shadow(color: isSelected ? purple.opacity(0.5) : .clear, radius: 8, x: 0, y: 0)
    }
    
    static func contactCard(buttonType: ButtonType = .add) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(separator, lineWidth: 1)
            )
    }
    
    static func actionButton(type: ButtonType) -> some View {
        Group {
            if type == .add {
                Text("add")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textPrimary)
                    .frame(width: 60, height: 30)
                    .background(
                        pinkOrangeGradient
                            .cornerRadius(15)
                    )
                    .shadow(color: purple.opacity(0.5), radius: 6, x: 0, y: 0)
            } else if type == .added {
                Text("added")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textPrimary)
                    .frame(width: 60, height: 30)
                    .background(
                        successGradient
                            .cornerRadius(15)
                    )
                    .shadow(color: mint.opacity(0.5), radius: 6, x: 0, y: 0)
            } else {
                Text("invite")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textSecondary)
                    .frame(width: 60, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(outline, lineWidth: 1)
                            )
                    )
            }
        }
    }
    
    enum ButtonType {
        case add, invite, added
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

// View extensions for applying effects
extension View {
    func clayMorphism(cornerRadius: CGFloat = 24) -> some View {
        self.modifier(AppColors.clayMorphism(cornerRadius: cornerRadius))
    }
    
    func glow(color: Color = AppColors.accent, radius: CGFloat = 6, opacity: Double = 0.8) -> some View {
        self.modifier(AppColors.glowEffect(color: color, radius: radius, opacity: opacity))
    }
}

#Preview("App Colors") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Group {
                Text("Brand Colors")
                    .font(.headline)
                    .foregroundColor(.white)
                HStack {
                    colorPreview(AppColors.accent, "Accent")
                    colorPreview(AppColors.accentSecondary, "Secondary")
                    colorPreview(AppColors.purple, "Purple")
                    colorPreview(AppColors.mint, "Mint")
                }
            }
            
            Group {
                Text("Background Colors")
                    .font(.headline)
                    .foregroundColor(.white)
                HStack {
                    colorPreview(AppColors.backgroundPrimary, "Primary")
                    colorPreview(AppColors.backgroundSecondary, "Secondary")
                    colorPreview(AppColors.cardBackground, "Card")
                }
            }
            
            Group {
                Text("Text Colors")
                    .font(.headline)
                    .foregroundColor(.white)
                HStack {
                    colorPreview(AppColors.textPrimary, "Primary")
                    colorPreview(AppColors.textSecondary, "Secondary")
                    colorPreview(AppColors.textTertiary, "Tertiary")
                }
            }
            
            Group {
                Text("Gradients")
                    .font(.headline)
                    .foregroundColor(.white)
                VStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.backgroundGradient)
                        .frame(height: 50)
                        .overlay(Text("Background").foregroundColor(.white))
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.accentGradient1)
                        .frame(height: 50)
                        .overlay(Text("Gradient 1").foregroundColor(.white))
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.accentGradient2)
                        .frame(height: 50)
                        .overlay(Text("Gradient 2").foregroundColor(.white))
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.accentGradient3)
                        .frame(height: 50)
                        .overlay(Text("Gradient 3").foregroundColor(.white))
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.accentGradient4)
                        .frame(height: 50)
                        .overlay(Text("Gradient 4").foregroundColor(.white))
                }
            }
            
            Group {
                Text("Effect Examples")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    Text("Claymorphism")
                        .padding()
                        .frame(height: 60)
                        .clayMorphism()
                    
                    Text("Glow Effect")
                        .padding()
                        .frame(height: 60)
                        .background(AppColors.accent)
                        .cornerRadius(16)
                        .glow()
                }
            }
            
            Group {
                Text("Avatar Examples")
                    .font(.headline)
                    .foregroundColor(.white)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(0..<5) { i in
                            let name = "User\(i)"
                            ZStack {
                                Circle()
                                    .fill(AppColors.avatarGradient(for: name))
                                    .frame(width: 60, height: 60)
                                Text(AppColors.avatarEmoji(for: name))
                                    .font(.title)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
    .background(AppColors.backgroundGradient)
}

// MARK: - AddFriendView Colors Preview
#Preview("AddFriendView Colors") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Group {
                Text("AddFriendView Base Colors")
                    .font(.headline)
                    .foregroundColor(.white)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        colorPreview(AddFriendViewColors.backgroundDark, "Background Dark")
                        colorPreview(AddFriendViewColors.backgroundLight, "Background Light")
                        colorPreview(AddFriendViewColors.cardBackground, "Card")
                        colorPreview(AddFriendViewColors.purple, "Purple")
                        colorPreview(AddFriendViewColors.pinkRed, "Pink-Red")
                        colorPreview(AddFriendViewColors.orange, "Orange")
                        colorPreview(AddFriendViewColors.mint, "Mint")
                        colorPreview(AddFriendViewColors.emerald, "Emerald")
                        colorPreview(AddFriendViewColors.bluePurple, "Blue-Purple")
                    }
                    .padding(.horizontal, 10)
                }
            }
            
            Group {
                Text("AddFriendView Gradients")
                    .font(.headline)
                    .foregroundColor(.white)
                VStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AddFriendViewColors.backgroundGradient)
                        .frame(height: 50)
                        .overlay(Text("Background").foregroundColor(.white))
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AddFriendViewColors.pinkOrangeGradient)
                        .frame(height: 50)
                        .overlay(Text("Pink-Orange").foregroundColor(.white))
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AddFriendViewColors.purplePinkGradient)
                        .frame(height: 50)
                        .overlay(Text("Purple-Pink").foregroundColor(.white))
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AddFriendViewColors.mintPurpleGradient)
                        .frame(height: 50)
                        .overlay(Text("Mint-Purple").foregroundColor(.white))
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AddFriendViewColors.blueMintGradient)
                        .frame(height: 50)
                        .overlay(Text("Blue-Mint").foregroundColor(.white))
                        
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AddFriendViewColors.successGradient)
                        .frame(height: 50)
                        .overlay(Text("Success").foregroundColor(.white))
                }
            }
            
            Group {
                Text("AddFriendView UI Elements")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    VStack {
                        AddFriendViewColors.tabButton(isSelected: true)
                            .frame(height: 40)
                            .overlay(Text("Selected Tab").foregroundColor(.white))
                        Text("Selected Tab")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    VStack {
                        AddFriendViewColors.tabButton(isSelected: false)
                            .frame(height: 40)
                            .overlay(Text("Unselected Tab").foregroundColor(.white.opacity(0.6)))
                        Text("Unselected Tab")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 15)
                
                HStack {
                    VStack {
                        AddFriendViewColors.actionButton(type: .add)
                        Text("Add Button")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    VStack {
                        AddFriendViewColors.actionButton(type: .invite)
                        Text("Invite Button")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    VStack {
                        AddFriendViewColors.actionButton(type: .added)
                        Text("Added Button")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                
                VStack(spacing: 15) {
                    Text("Contact Card")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    AddFriendViewColors.contactCard()
                        .frame(height: 80)
                        .overlay(
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(AddFriendViewColors.mintPurpleGradient)
                                        .frame(width: 50, height: 50)
                                    
                                    Circle()
                                        .fill(AddFriendViewColors.cardBackground)
                                        .frame(width: 40, height: 40)
                                    
                                    Text("🦋")
                                        .font(.system(size: 18))
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Jamie Smith")
                                        .foregroundColor(.white)
                                    Text("123-456-7890")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.leading, 10)
                                
                                Spacer()
                                
                                AddFriendViewColors.actionButton(type: .add)
                            }
                            .padding(.horizontal, 20)
                        )
                }
            }
        }
        .padding()
    }
    .background(AddFriendViewColors.backgroundGradient)
}

private func colorPreview(_ color: Color, _ name: String) -> some View {
    VStack {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 60, height: 60)
        Text(name)
            .font(.caption)
            .foregroundColor(.white)
    }
} 
