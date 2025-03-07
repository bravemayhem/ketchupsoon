import SwiftUI

struct ThemePreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingLarge) {
                // Header
                Text("ketchup")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .kerning(-0.5) + 
                Text("soon")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppColors.accent)
                    .kerning(-0.5) +
                Text(" design")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .kerning(-0.5)
                
                Text("gen z aesthetic ✨")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.bottom)
                
                // Colors Section
                colorsSection
                    .clayCard()
                    .padding(.horizontal)
                
                // UI Elements Section
                uiElementsSection
                    .clayCard()
                    .padding(.horizontal)
                
                // Typography Section
                typographySection
                    .clayCard()
                    .padding(.horizontal)
                
                // Avatar Styles Section
                avatarStylesSection
                    .clayCard()
                    .padding(.horizontal)
                
                // Buttons Section
                buttonsSection
                    .clayCard()
                    .padding(.horizontal)
                
                // UI Components Section
                componentsSection
                    .clayCard()
                    .padding(.horizontal)
                
                // Space at the bottom
                Spacer()
                    .frame(height: 40)
            }
            .padding(.top)
        }
        .background(
            ZStack {
                AppColors.backgroundGradient
                
                // Decorative blobs
                Circle()
                    .fill(AppColors.purple.opacity(0.3))
                    .frame(width: 400, height: 400)
                    .blur(radius: 50)
                    .offset(x: 150, y: -50)
                
                Circle()
                    .fill(AppColors.accent.opacity(0.2))
                    .frame(width: 360, height: 360)
                    .blur(radius: 50)
                    .offset(x: -150, y: 500)
                
                // Small decorative elements
                Circle()
                    .fill(AppColors.mint.opacity(0.8))
                    .frame(width: 16, height: 16)
                    .offset(x: -140, y: 180)
                
                Circle()
                    .fill(AppColors.accentSecondary.opacity(0.8))
                    .frame(width: 10, height: 10)
                    .offset(x: 150, y: 400)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.purple.opacity(0.8))
                    .frame(width: 15, height: 15)
                    .rotationEffect(.degrees(30))
                    .offset(x: 120, y: 220)
            }
        )
        .foregroundColor(AppColors.textPrimary)
    }
    
    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            sectionHeader("brand colors 🎨")
            
            // Brand Colors Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                colorSwatch(name: "accent", color: AppColors.accent)
                colorSwatch(name: "secondary", color: AppColors.accentSecondary)
                colorSwatch(name: "purple", color: AppColors.purple)
                colorSwatch(name: "mint", color: AppColors.mint)
                colorSwatch(name: "background", color: AppColors.backgroundPrimary)
                colorSwatch(name: "card bg", color: AppColors.cardBackground)
            }
        }
        .padding()
    }
    
    private var typographySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            sectionHeader("typography ✏️")
            
            VStack(alignment: .leading, spacing: 8) {
                Text("title font")
                    .font(AppTheme.titleFont)
                    .foregroundColor(.white)
                
                Text("subtitle font")
                    .font(AppTheme.subtitleFont)
                    .foregroundColor(.white)
                
                Text("body font")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(.white)
                
                Text("caption font")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
    }
    
    private var uiElementsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            sectionHeader("gradients 🌈")
            
            // Gradients Grid
            VStack(spacing: 12) {
                gradientSample("gradient 1", gradient: AppColors.accentGradient1)
                gradientSample("gradient 2", gradient: AppColors.accentGradient2)
                gradientSample("gradient 3", gradient: AppColors.accentGradient3)
                gradientSample("gradient 4", gradient: AppColors.accentGradient4)
            }
        }
        .padding()
    }
    
    private var avatarStylesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            sectionHeader("avatar styles 👤")
            
            // Avatar Styles
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<5) { i in
                        let name = "User\(i)"
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(AppColors.avatarGradient(for: name))
                                    .frame(width: 60, height: 60)
                                    .shadow(color: AppColors.gradient1Start.opacity(0.3), radius: 6, x: 0, y: 0)
                                
                                Circle()
                                    .fill(AppColors.cardBackground)
                                    .frame(width: 54, height: 54)
                                
                                Text(AppColors.avatarEmoji(for: name))
                                    .font(.system(size: 26))
                            }
                            
                            Text(name.lowercased())
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            sectionHeader("button styles 👆")
            
            VStack(spacing: 16) {
                Button("primary button") {}
                    .buttonStyle(AppTheme.primaryButtonStyle())
                    .frame(maxWidth: .infinity)
                
                Button("secondary button") {}
                    .buttonStyle(AppTheme.secondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                
                Button("tertiary button") {}
                    .buttonStyle(AppTheme.tertiaryButtonStyle())
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
    
    private var componentsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            sectionHeader("ui components 💎")
            
            VStack(spacing: 16) {
                // Card Component
                VStack(alignment: .leading, spacing: 8) {
                    Text("card with claymorphism")
                        .font(AppTheme.subtitleFont)
                        .foregroundColor(.white)
                    
                    Text("cards use soft shadows and subtle borders")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding()
                .clayCard(cornerRadius: 20)
                
                // Text Field Component
                VStack(alignment: .leading, spacing: 8) {
                    Text("text fields")
                        .font(AppTheme.subtitleFont)
                        .foregroundColor(.white)
                    
                    TextField("Enter your name...", text: .constant(""))
                        .appTextFieldStyle()
                }
                
                // Progress Component
                VStack(alignment: .leading, spacing: 8) {
                    Text("progress indicator")
                        .font(AppTheme.subtitleFont)
                        .foregroundColor(.white)
                    
                    ProgressView(value: 0.6)
                        .progressViewStyle(GradientProgressStyle())
                }
            }
        }
        .padding()
    }
    
    // Helper functions
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
    }
    
    private func colorSwatch(name: String, color: Color) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    private func gradientSample(_ name: String, gradient: LinearGradient) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(gradient)
                .frame(height: 50)
        }
    }
}

// Custom Gradient Progress Style
struct GradientProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
                .frame(height: 20)
            
            RoundedRectangle(cornerRadius: 10)
                .fill(AppColors.accentGradient1)
                .frame(width: CGFloat(configuration.fractionCompleted ?? 0) * 350, height: 20)
                .glow(color: AppColors.accent, radius: 3, opacity: 0.5)
        }
    }
}

#Preview {
    ThemePreview()
} 