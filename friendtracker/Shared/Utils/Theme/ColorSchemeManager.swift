import SwiftUI

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
}

class ColorSchemeManager: ObservableObject {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @Published var colorScheme: ColorScheme = .light
    
    static let shared = ColorSchemeManager()
    
    private init() {
        updateColorScheme()
    }
    
    var currentAppearanceMode: AppearanceMode {
        get {
            AppearanceMode(rawValue: appearanceMode) ?? .system
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
            colorScheme = .light // This will be overridden by the system
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        }
    }
} 