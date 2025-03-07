import SwiftUI

// For KetchupSoon we're defaulting to dark mode for the Gen Z aesthetic
// but we're keeping the option to switch to light mode if needed

enum AppearanceMode: String, CaseIterable {
    case system
    case light
    case dark
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var emoji: String {
        switch self {
        case .system: return "📱"
        case .light: return "☀️"
        case .dark: return "🌙"
        }
    }
}

class ColorSchemeManager: ObservableObject {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.dark.rawValue
    @Published var colorScheme: ColorScheme = .dark
    
    static let shared = ColorSchemeManager()
    
    private init() {
        updateColorScheme()
    }
    
    var currentAppearanceMode: AppearanceMode {
        get {
            AppearanceMode(rawValue: appearanceMode) ?? .dark
        }
        set {
            appearanceMode = newValue.rawValue
            updateColorScheme()
        }
    }
    
    private func updateColorScheme() {
        switch currentAppearanceMode {
        case .system:
            // When in system mode, we'll let the app handle it naturally
            // But default to dark if system appearance is not determinable
            colorScheme = .dark
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        }
    }
    
    // Toggle method for simple switching
    func toggleDarkMode() {
        currentAppearanceMode = currentAppearanceMode == .dark ? .light : .dark
    }
}

// Preview for Color Scheme Selector
struct AppearanceSelector: View {
    @ObservedObject var colorSchemeManager = ColorSchemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("appearance")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    appearanceButton(for: mode)
                }
            }
        }
        .padding()
        .clayCard()
    }
    
    private func appearanceButton(for mode: AppearanceMode) -> some View {
        let isSelected = colorSchemeManager.currentAppearanceMode == mode
        
        return Button(action: {
            colorSchemeManager.currentAppearanceMode = mode
        }) {
            VStack(spacing: 8) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(AppColors.accentGradient1)
                            .frame(width: 50, height: 50)
                            .shadow(color: AppColors.accent.opacity(0.5), radius: 6, x: 0, y: 0)
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 50, height: 50)
                    }
                    
                    Text(mode.emoji)
                        .font(.system(size: 20))
                }
                
                Text(mode.displayName.lowercased())
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : AppColors.textSecondary)
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.backgroundGradient.ignoresSafeArea()
        AppearanceSelector()
            .padding()
    }
} 