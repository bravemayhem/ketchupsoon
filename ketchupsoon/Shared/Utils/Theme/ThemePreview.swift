import SwiftUI

struct ThemePreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingLarge) {
                // Colors Section
                colorsSection
                
                Divider()
                
                // Typography Section
                typographySection
                
                Divider()
                
                // UI Elements Section
                uiElementsSection
                
                Divider()
                
                // Avatar Colors Section
                avatarColorsSection
                
                Divider()
                
                // Buttons Section
                buttonsSection
            }
            .padding()
        }
        .background(AppColors.systemBackground)
        .navigationTitle("Theme Preview")
    }
    
    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            Text("Colors")
                .font(AppTheme.titleFont)
            
            // Brand Colors
            colorRow(name: "Accent", color: AppColors.accent)
            colorRow(name: "Accent Light", color: AppColors.accentLight)
            
            // Background Colors
            colorRow(name: "System Background", color: AppColors.systemBackground)
            colorRow(name: "Secondary System Background", color: AppColors.secondarySystemBackground)
            
            // Text Colors
            colorRow(name: "Label", color: AppColors.label)
            colorRow(name: "Secondary Label", color: AppColors.secondaryLabel)
            colorRow(name: "Tertiary Label", color: AppColors.tertiaryLabel)
            
            // Semantic Colors
            colorRow(name: "Success", color: AppColors.success)
            colorRow(name: "Warning", color: AppColors.warning)
            colorRow(name: "Error", color: AppColors.error)
        }
    }
    
    private var typographySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            Text("Typography")
                .font(AppTheme.titleFont)
            
            Text("Title Font")
                .font(AppTheme.titleFont)
            Text("Headline Font")
                .font(AppTheme.headlineFont)
            Text("Body Font")
                .font(AppTheme.bodyFont)
            Text("Caption Font")
                .font(AppTheme.captionFont)
        }
    }
    
    private var uiElementsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            Text("UI Elements")
                .font(AppTheme.titleFont)
            
            // Gradients
            Text("Background Gradient")
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                .fill(AppColors.backgroundGradient)
                .frame(height: 100)
            
            Text("Accent Gradient")
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                .fill(AppColors.accentGradient)
                .frame(height: 100)
            
            // Glassmorphism
            Text("Glassmorphism")
            ZStack {
                AppColors.accentGradient
                AppColors.glassMorphism()
            }
            .frame(height: 100)
            .cornerRadius(AppTheme.cornerRadiusMedium)
        }
    }
    
    private var avatarColorsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            Text("Avatar Colors")
                .font(AppTheme.titleFont)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacingSmall) {
                    ForEach(AppColors.avatarColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 50, height: 50)
                    }
                }
            }
        }
    }
    
    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            Text("Buttons")
                .font(AppTheme.titleFont)
            
            Button("Primary Button") {}
                .buttonStyle(AppTheme.primaryButtonStyle())
            
            Button("Secondary Button") {}
                .buttonStyle(AppTheme.secondaryButtonStyle())
        }
    }
    
    private func colorRow(name: String, color: Color) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                .fill(color)
                .frame(width: 50, height: 50)
            
            Text(name)
                .font(AppTheme.bodyFont)
            
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        ThemePreview()
    }
} 