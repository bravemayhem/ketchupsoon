import SwiftUI

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: ThemeProtocol.Type = LightTheme.self
    
    func toggleTheme(isDark: Bool) {
        currentTheme = isDark ? DarkTheme.self : LightTheme.self
    }
} 